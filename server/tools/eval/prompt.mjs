/**
 * The shipping prompts, adapted to the shape the eval cases use.
 *
 * This file used to be a hand-maintained port of the system instruction that
 * `lib/screens/chat_screen.dart` built, carrying a comment at the top warning
 * that it would drift and asking whoever changed the Dart to change this too.
 * It drifted.
 *
 * That is fixed at the root now rather than by being more careful: the prompts
 * live in `src/prompts.js`, the app asks for one by name, and the eval reads
 * the same builder the service runs. One copy of the wording, so there is
 * nothing left to keep in step.
 */

import { buildSystemInstruction as buildForMode } from '../../src/prompts.js';

export { needsReading } from '../../src/prompts.js';

/**
 * The chat tutor's system instruction for one eval case.
 *
 * Cases carry `targetLang`/`nativeLang` as human labels for the report and
 * `targetCode`/`nativeCode` as the values that actually select the prompt, so
 * this only has to adapt the case shape to the service's params. A case that
 * names a scenario gets the untracked roleplay branch, which is the one the
 * eval has always exercised.
 */
export function buildSystemInstruction({ targetCode, nativeCode, scenario = null }) {
  return buildForMode('chat', {
    targetCode,
    nativeCode,
    ...(scenario ? { scenario: { title: scenario } } : {}),
  });
}
