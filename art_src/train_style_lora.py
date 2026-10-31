# -*- coding: utf-8 -*-
"""Train the style LoRA on fal.ai, and try it.

The training set is gen_style_dataset.py's style_dataset.zip: the owner's
pets, bosses and home scenes. fal's FLUX.2 [dev] trainer learns the style from
it (about 2,000 steps), and fal's FLUX.2 [dev] LoRA endpoint draws with it.
Both are fal's own hosted endpoints, tagged for commercial use (the FLUX.2
[dev] weights themselves are non-commercial, so the LoRA is for fal's endpoint,
not for self-hosting).

    python train_style_lora.py status                  # what would run, what it costs
    python train_style_lora.py train --yes             # train (2,000 steps, ~$12.80)
    python train_style_lora.py fetch REQUEST_ID        # collect a job that was cut off
    python train_style_lora.py sample "a wooden chest on a flat magenta background" --yes

Nothing is spent without --yes. The API key is read from FAL_KEY or from
~/.fal_key (a file holding only the key); it is never printed or stored here.
Prices (fal, 2026-10-18): trainer $0.0064 a step; the LoRA endpoint $0.021 a
megapixel, so about $0.022 for a 1024 x 1024 image.

Output: style_lora/ (run.json with the job and the LoRA's URL, the weights, the
config) and style_samples/ -- both gitignored.
"""
import argparse
import json
import os
import re
import sys
import time
import urllib.request

HERE = os.path.dirname(os.path.abspath(__file__))
DATASET = os.path.join(HERE, 'style_dataset.zip')
LORA_DIR = os.path.join(HERE, 'style_lora')
RUN = os.path.join(LORA_DIR, 'run.json')
SAMPLES = os.path.join(HERE, 'style_samples')

TRAINER = 'fal-ai/flux-2-trainer'
GENERATOR = 'fal-ai/flux-2/lora'
PER_STEP = 0.0064                 # dollars a training step
PER_MEGAPIXEL = 0.021             # dollars a megapixel generated
TRIGGER = 'mmkn'                  # gen_style_dataset.TRIGGER


def have_key():
    """FAL_KEY from the environment, else from ~/.fal_key."""
    if os.environ.get('FAL_KEY'):
        return True
    path = os.path.join(os.path.expanduser('~'), '.fal_key')
    if os.path.exists(path):
        with open(path, encoding='utf-8') as f:
            os.environ['FAL_KEY'] = f.read().strip()
        return bool(os.environ['FAL_KEY'])
    return False


def fal():
    if not have_key():
        sys.exit('No fal key: set FAL_KEY, or put the key alone in ~/.fal_key')
    try:
        import fal_client
    except ImportError:
        sys.exit('pip install fal-client first')
    return fal_client


def count_dataset():
    import zipfile
    with zipfile.ZipFile(DATASET) as z:
        names = z.namelist()
    return (sum(n.endswith('.png') for n in names),
            sum(n.endswith('.txt') for n in names))


def save_json(path, data):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w', encoding='utf-8', newline='\n') as f:
        json.dump(data, f, indent=1)
        f.write('\n')


def load_run():
    if not os.path.exists(RUN):
        sys.exit('No trained LoRA yet (style_lora/run.json): run `train` first')
    with open(RUN, encoding='utf-8') as f:
        return json.load(f)


def download(url, path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    urllib.request.urlretrieve(url, path)
    return path


def cmd_status(args):
    if not os.path.exists(DATASET):
        sys.exit('No style_dataset.zip: run gen_style_dataset.py first')
    images, captions = count_dataset()
    print('dataset: %d images, %d captions (%s)' % (images, captions, DATASET))
    print('train: %d steps at %g, about $%.2f' % (
        args.steps, args.lr, args.steps * PER_STEP))
    print('a 1024 x 1024 sample: about $%.3f' % PER_MEGAPIXEL)
    print('fal key:', 'found' if have_key() else 'NOT found (FAL_KEY or ~/.fal_key)')
    print('trained LoRA:', 'yes (%s)' % RUN if os.path.exists(RUN) else 'not yet')


def collect(result, request_id, steps, lr):
    """Keep the job's answer on disk first, then the weights."""
    run = {'request_id': request_id, 'steps': steps, 'learning_rate': lr,
           'trainer': TRAINER, 'result': result,
           'lora_url': result['diffusers_lora_file']['url'],
           'config_url': result['config_file']['url'],
           'finished': time.strftime('%Y-%m-%d %H:%M:%S')}
    save_json(RUN, run)
    run['lora_file'] = download(run['lora_url'], os.path.join(
        LORA_DIR, 'style_lora.safetensors'))
    run['config_file'] = download(run['config_url'], os.path.join(
        LORA_DIR, 'config.json'))
    save_json(RUN, run)
    print('LoRA saved:', run['lora_file'])
    return run


def cmd_train(args):
    images, captions = count_dataset()
    cost = args.steps * PER_STEP
    print('%d images, %d steps at %g: about $%.2f' % (
        images, args.steps, args.lr, cost))
    if not args.yes:
        print('(not run: add --yes to spend it)')
        return
    fal_client = fal()
    print('uploading', DATASET)
    url = fal_client.upload_file(DATASET)
    handler = fal_client.submit(TRAINER, arguments={
        'image_data_url': url,
        'steps': args.steps,
        'learning_rate': args.lr,
        'default_caption': TRIGGER,
        'output_lora_format': 'fal',
    })
    # Written at once: if this process dies the job still runs on fal and is
    # still billed, and the id is how `fetch` gets the result.
    save_json(os.path.join(LORA_DIR, 'submitted.json'), {
        'request_id': handler.request_id, 'steps': args.steps,
        'learning_rate': args.lr, 'when': time.strftime('%Y-%m-%d %H:%M:%S')})
    print('submitted, request id', handler.request_id)
    for event in handler.iter_events(with_logs=True):
        for log in getattr(event, 'logs', None) or []:
            print(log.get('message', log))
    collect(handler.get(), handler.request_id, args.steps, args.lr)


def cmd_fetch(args):
    fal_client = fal()
    sub = os.path.join(LORA_DIR, 'submitted.json')
    steps, lr = args.steps, args.lr
    if os.path.exists(sub):
        with open(sub, encoding='utf-8') as f:
            was = json.load(f)
        steps, lr = was.get('steps', steps), was.get('learning_rate', lr)
    result = fal_client.result(TRAINER, args.request_id)
    collect(result, args.request_id, steps, lr)


def cmd_sample(args):
    w, h = [int(v) for v in args.size.lower().split('x')]
    cost = PER_MEGAPIXEL * w * h / 1e6 * args.n
    print('%d image(s) at %dx%d: about $%.3f' % (args.n, w, h, cost))
    if not args.yes:
        print('(not run: add --yes to spend it)')
        return
    run = load_run()
    fal_client = fal()
    prompt = args.prompt
    if TRIGGER not in prompt.split(','):
        prompt = '%s, %s' % (TRIGGER, prompt)
    arguments = {
        'prompt': prompt,
        'loras': [{'path': run['lora_url'], 'scale': args.scale}],
        'image_size': {'width': w, 'height': h},
        'num_images': args.n,
        'num_inference_steps': args.inference_steps,
        'guidance_scale': args.guidance,
        'output_format': 'png',
    }
    if args.seed is not None:
        arguments['seed'] = args.seed
    result = fal_client.subscribe(GENERATOR, arguments=arguments)
    slug = re.sub(r'[^a-z0-9]+', '-', args.prompt.lower())[:40].strip('-')
    stamp = time.strftime('%H%M%S')
    for i, im in enumerate(result['images'], 1):
        path = os.path.join(SAMPLES, '%s_%s_s%g_%d.png' % (
            stamp, slug, args.scale, i))
        download(im['url'], path)
        print(path)
    print('seed', result.get('seed'), '| prompt:', prompt)


def main(argv):
    ap = argparse.ArgumentParser(description=__doc__.split('\n')[0])
    sub = ap.add_subparsers(dest='cmd', required=True)

    def training_options(p):
        p.add_argument('--steps', type=int, default=2000)
        p.add_argument('--lr', type=float, default=0.00005)

    p = sub.add_parser('status')
    training_options(p)
    p.set_defaults(run=cmd_status)

    p = sub.add_parser('train')
    training_options(p)
    p.add_argument('--yes', action='store_true', help='spend the money')
    p.set_defaults(run=cmd_train)

    p = sub.add_parser('fetch')
    p.add_argument('request_id')
    training_options(p)
    p.set_defaults(run=cmd_fetch)

    p = sub.add_parser('sample')
    p.add_argument('prompt')
    p.add_argument('--n', type=int, default=2)
    p.add_argument('--scale', type=float, default=1.0, help='LoRA strength')
    p.add_argument('--size', default='1024x1024')
    p.add_argument('--seed', type=int)
    p.add_argument('--inference-steps', type=int, default=28)
    p.add_argument('--guidance', type=float, default=2.5)
    p.add_argument('--yes', action='store_true', help='spend the money')
    p.set_defaults(run=cmd_sample)

    args = ap.parse_args(argv)
    args.run(args)


if __name__ == '__main__':
    main(sys.argv[1:])
