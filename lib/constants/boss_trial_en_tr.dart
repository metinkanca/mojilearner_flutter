/// English and Turkish content for the trial openers that need more than the
/// stock words and sentences: Lanternmaw's Shoal, Sableth's Riddle, Sealed
/// Door and Tablets, and Pyrewing's Parley, Flame Link, Ember Paraphrase and
/// Hoard.
///
/// A TESTING PLACEHOLDER, like the rest of the stock: these rounds are meant
/// to be filled by the AI from the player's level band. Until then they are
/// hand-written in the owner's two languages only, and either can be the one
/// being learned — every set is written in both, or, where a language's
/// grammar is its own (the doors, the phrases), for each. A player on any
/// other pair fights these openers in English and Turkish instead, and the
/// intro says so.
library;

import '../utils/boss_trial.dart';
import '../utils/boss_trial_dragon.dart';
import '../utils/boss_trial_sphinx.dart';

/// Whether [target] and [native] are English and Turkish, either way round.
bool isEnTrPair(String? target, String? native) =>
    (target == 'en' && native == 'tr') || (target == 'tr' && native == 'en');

/// The English–Turkish pair a player on another pair fights these openers
/// in: English if English is what they are learning, else Turkish.
(String, String) enTrStandIn(String? target) =>
    target == 'en' ? ('en', 'tr') : ('tr', 'en');

/// Everything these openers draw on, for one way round of the pair.
class EnTrContent {
  const EnTrContent._({
    required this.categories,
    required this.riddles,
    required this.doors,
    required this.stories,
    required this.parleys,
    required this.links,
    required this.paraphrases,
    required this.phrases,
    required this.alsoFit,
  });

  /// Words in groups, for the shoal: every group's words, with meanings.
  final Map<String, List<TrialWord>> categories;
  final List<TrialRiddle> riddles;
  final List<GrammarDoor> doors;
  final List<TrialStory> stories;
  final List<ParleyScript> parleys;
  final List<LinkItem> links;
  final List<ParaphraseItem> paraphrases;
  final List<Collocation> phrases;

  /// First and second halves that make a phrase too, though not one of
  /// [phrases]: a hoard never lays them out together.
  final Set<(String, String)> alsoFit;

  /// The content for learning [target] with [native] meanings, or null when
  /// that is not English and Turkish.
  static EnTrContent? of(String? target, String? native) {
    if (!isEnTrPair(target, native)) return null;
    final en = target == 'en';
    // Picks the learned side, then the meaning side, of an (en, tr) pair.
    String t((String, String) p) => en ? p.$1 : p.$2;
    String m((String, String) p) => en ? p.$2 : p.$1;
    return EnTrContent._(
      categories: {
        for (final e in _categories.entries)
          e.key: [
            for (final w in e.value) TrialWord(target: t(w), meaning: m(w)),
          ],
      },
      riddles: [
        for (final (english, turkish) in _riddles)
          TrialRiddle(
            passage: (en ? english : turkish).$1,
            question: (en ? english : turkish).$2,
            answers: (en ? english : turkish).$3,
            meaning: '${(en ? turkish : english).$1} '
                '${(en ? turkish : english).$2}',
          ),
      ],
      doors: en ? _englishDoors : _turkishDoors,
      stories: [
        for (final s in _stories)
          TrialStory(
            lines: [for (final l in s) t(l)],
            meanings: [for (final l in s) m(l)],
          ),
      ],
      parleys: [
        for (final script in _parleys)
          ParleyScript([
            for (final (line, replies) in script)
              ParleyTurn(
                line: t(line),
                replies: [for (final r in replies) t(r)],
                meaning: '${m(line)} — ${m(replies.first)}',
              ),
          ]),
      ],
      links: en ? _englishLinks : _turkishLinks,
      paraphrases: en ? _englishParaphrases : _turkishParaphrases,
      phrases: en ? _englishPhrases : _turkishPhrases,
      alsoFit: en ? _englishAlsoFit : _turkishAlsoFit,
    );
  }
}

// ---- Shoal: words in groups ---------------------------------------------------

/// Every word belongs to one group only: no "fish", which is food and an
/// animal, no "orange", which is a fruit and a colour.
const Map<String, List<(String, String)>> _categories = {
  'animals': [
    ('dog', 'köpek'),
    ('cat', 'kedi'),
    ('horse', 'at'),
    ('bird', 'kuş'),
    ('cow', 'inek'),
    ('sheep', 'koyun'),
  ],
  'food': [
    ('bread', 'ekmek'),
    ('cheese', 'peynir'),
    ('apple', 'elma'),
    ('egg', 'yumurta'),
    ('rice', 'pirinç'),
    ('soup', 'çorba'),
  ],
  'colours': [
    ('red', 'kırmızı'),
    ('blue', 'mavi'),
    ('green', 'yeşil'),
    ('yellow', 'sarı'),
    ('black', 'siyah'),
    ('white', 'beyaz'),
  ],
  'the body': [
    ('hand', 'el'),
    ('foot', 'ayak'),
    ('head', 'baş'),
    ('eye', 'göz'),
    ('ear', 'kulak'),
    ('nose', 'burun'),
  ],
  'clothes': [
    ('shirt', 'gömlek'),
    ('shoe', 'ayakkabı'),
    ('hat', 'şapka'),
    ('coat', 'palto'),
    ('sock', 'çorap'),
    ('dress', 'elbise'),
  ],
  'weather': [
    ('rain', 'yağmur'),
    ('snow', 'kar'),
    ('wind', 'rüzgâr'),
    ('cloud', 'bulut'),
    ('storm', 'fırtına'),
    ('fog', 'sis'),
  ],
  'family': [
    ('mother', 'anne'),
    ('father', 'baba'),
    ('son', 'oğul'),
    ('daughter', 'kız'),
    ('grandmother', 'büyükanne'),
    ('uncle', 'amca'),
  ],
  'places': [
    ('school', 'okul'),
    ('hospital', 'hastane'),
    ('market', 'pazar'),
    ('library', 'kütüphane'),
    ('station', 'istasyon'),
    ('bank', 'banka'),
  ],
};

// ---- Riddle ---------------------------------------------------------------

typedef _Riddle = (String, String, List<String>);

/// (English, Turkish): the story, the question, and the answers with the
/// right one first.
const List<(_Riddle, _Riddle)> _riddles = [
  (
    (
      'Tom has a red bike. His sister has a blue bike.',
      'What colour is Tom\'s bike?',
      ['Red', 'Blue', 'Green'],
    ),
    (
      'Tom\'un kırmızı bir bisikleti var. Kız kardeşinin mavi bir bisikleti var.',
      'Tom\'un bisikleti ne renk?',
      ['Kırmızı', 'Mavi', 'Yeşil'],
    ),
  ),
  (
    (
      'Ayşe gets up at seven. She has breakfast and goes to school at eight.',
      'When does Ayşe go to school?',
      ['At eight', 'At seven', 'At nine'],
    ),
    (
      'Ayşe yedide kalkar. Kahvaltı yapar ve sekizde okula gider.',
      'Ayşe okula saat kaçta gider?',
      ['Sekizde', 'Yedide', 'Dokuzda'],
    ),
  ),
  (
    (
      'It is raining, so Ali takes his umbrella.',
      'Why does Ali take his umbrella?',
      ['Because it is raining', 'Because it is sunny', 'Because he is hungry'],
    ),
    (
      'Yağmur yağıyor, bu yüzden Ali şemsiyesini alıyor.',
      'Ali şemsiyesini neden alıyor?',
      ['Çünkü yağmur yağıyor', 'Çünkü hava güneşli', 'Çünkü aç'],
    ),
  ),
  (
    (
      'The cat is under the table. The dog is on the sofa.',
      'Where is the dog?',
      ['On the sofa', 'Under the table', 'In the garden'],
    ),
    (
      'Kedi masanın altında. Köpek kanepenin üstünde.',
      'Köpek nerede?',
      ['Kanepenin üstünde', 'Masanın altında', 'Bahçede'],
    ),
  ),
  (
    (
      'Mehmet is hungry. He opens the fridge and takes some cheese.',
      'What does Mehmet take?',
      ['Cheese', 'Milk', 'An apple'],
    ),
    (
      'Mehmet aç. Buzdolabını açıyor ve biraz peynir alıyor.',
      'Mehmet ne alıyor?',
      ['Peynir', 'Süt', 'Elma'],
    ),
  ),
  (
    (
      'Anna has two brothers and one sister.',
      'How many brothers does Anna have?',
      ['Two', 'One', 'Three'],
    ),
    (
      'Anna\'nın iki erkek kardeşi ve bir kız kardeşi var.',
      'Anna\'nın kaç erkek kardeşi var?',
      ['İki', 'Bir', 'Üç'],
    ),
  ),
  (
    (
      'The shop opens at nine and closes at six.',
      'When does the shop close?',
      ['At six', 'At nine', 'At noon'],
    ),
    (
      'Dükkân dokuzda açılır ve altıda kapanır.',
      'Dükkân saat kaçta kapanır?',
      ['Altıda', 'Dokuzda', 'Öğlen'],
    ),
  ),
  (
    (
      'My grandmother lives in a small house by the sea.',
      'Where is the house?',
      ['By the sea', 'In the city', 'On a mountain'],
    ),
    (
      'Büyükannem deniz kenarında küçük bir evde yaşıyor.',
      'Ev nerede?',
      ['Deniz kenarında', 'Şehirde', 'Dağda'],
    ),
  ),
];

// ---- Sealed Door ----------------------------------------------------------
//
// Written for each language on its own: what makes a form right is that
// language's grammar, so the Turkish doors are not the English ones
// translated. The meaning shown is what makes the answer the only one.

const List<GrammarDoor> _englishDoors = [
  GrammarDoor(
    before: 'Yesterday I',
    after: 'to the market.',
    base: 'go',
    forms: ['went', 'go', 'goes'],
    meaning: 'Dün pazara gittim.',
  ),
  GrammarDoor(
    before: 'She',
    after: 'coffee every morning.',
    base: 'drink',
    forms: ['drinks', 'drink', 'drinking'],
    meaning: 'Her sabah kahve içer.',
  ),
  GrammarDoor(
    before: 'Look! They',
    after: 'football.',
    base: 'play',
    forms: ['are playing', 'plays', 'played'],
    meaning: 'Bak! Futbol oynuyorlar.',
  ),
  GrammarDoor(
    before: 'Tomorrow we',
    after: 'our grandmother.',
    base: 'visit',
    forms: ['will visit', 'visited', 'visits'],
    meaning: 'Yarın büyükannemizi ziyaret edeceğiz.',
  ),
  GrammarDoor(
    before: 'I have two',
    after: '',
    base: 'child',
    forms: ['children', 'childs', 'child'],
    meaning: 'İki çocuğum var.',
  ),
  GrammarDoor(
    before: 'This box is',
    after: 'than that one.',
    base: 'heavy',
    forms: ['heavier', 'heavy', 'heaviest'],
    meaning: 'Bu kutu şundan daha ağır.',
  ),
  GrammarDoor(
    before: 'He',
    after: 'his keys last night.',
    base: 'lose',
    forms: ['lost', 'loses', 'losed'],
    meaning: 'Dün gece anahtarlarını kaybetti.',
  ),
  GrammarDoor(
    before: 'My brother',
    after: 'in a bank.',
    base: 'work',
    forms: ['works', 'work', 'working'],
    meaning: 'Erkek kardeşim bir bankada çalışıyor.',
  ),
  GrammarDoor(
    before: 'There are three',
    after: 'in the garden.',
    base: 'mouse',
    forms: ['mice', 'mouses', 'mouse'],
    meaning: 'Bahçede üç fare var.',
  ),
];

const List<GrammarDoor> _turkishDoors = [
  GrammarDoor(
    before: 'Dün pazara',
    after: '',
    base: 'gitmek',
    forms: ['gittim', 'gidiyorum', 'gideceğim'],
    meaning: 'Yesterday I went to the market.',
  ),
  GrammarDoor(
    before: 'Yarın arkadaşım',
    after: '',
    base: 'gelmek',
    forms: ['gelecek', 'geldi', 'gelmişti'],
    meaning: 'My friend will come tomorrow.',
  ),
  GrammarDoor(
    before: 'Şu anda kitap',
    after: '',
    base: 'okumak',
    forms: ['okuyorum', 'okudum', 'okuyacağım'],
    meaning: 'I am reading a book right now.',
  ),
  GrammarDoor(
    before: 'Kitap',
    after: 'üstünde.',
    base: 'masa',
    forms: ['masanın', 'masayı', 'masada'],
    meaning: 'The book is on the table.',
  ),
  GrammarDoor(
    before: 'Her gün',
    after: 'gidiyorum.',
    base: 'okul',
    forms: ['okula', 'okulda', 'okuldan'],
    meaning: 'I go to school every day.',
  ),
  GrammarDoor(
    before: 'Annem',
    after: 'çalışıyor.',
    base: 'hastane',
    forms: ['hastanede', 'hastaneye', 'hastaneden'],
    meaning: 'My mother works at the hospital.',
  ),
  GrammarDoor(
    before: 'Dün akşam televizyon',
    after: '',
    base: 'izlemek',
    forms: ['izledik', 'izliyoruz', 'izleyeceğiz'],
    meaning: 'We watched TV last night.',
  ),
  GrammarDoor(
    before: 'Bu elbise',
    after: 'daha güzel.',
    base: 'o',
    forms: ['ondan', 'onu', 'onda'],
    meaning: 'This dress is prettier than that one.',
  ),
  GrammarDoor(
    before: 'Ben',
    after: 'korkarım.',
    base: 'köpek',
    forms: ['köpeklerden', 'köpekleri', 'köpeklerde'],
    meaning: 'I am afraid of dogs.',
  ),
];

// ---- Tablets --------------------------------------------------------------

/// Three lines each, (English, Turkish), in the order they happen — and only
/// one order makes sense.
const List<List<(String, String)>> _stories = [
  [
    ('Ali buys a ticket.', 'Ali bir bilet alır.'),
    ('He gets on the train.', 'Trene biner.'),
    ('The train arrives in Ankara.', 'Tren Ankara\'ya varır.'),
  ],
  [
    ('It starts to rain.', 'Yağmur yağmaya başlar.'),
    ('Ela opens her umbrella.', 'Ela şemsiyesini açar.'),
    ('She gets home dry.', 'Eve ıslanmadan varır.'),
  ],
  [
    ('The phone rings.', 'Telefon çalar.'),
    ('Can answers it.', 'Can telefonu açar.'),
    ('He talks to his mother.', 'Annesiyle konuşur.'),
  ],
  [
    ('We plant a seed.', 'Bir tohum ekeriz.'),
    ('It grows into a small tree.', 'Tohum küçük bir ağaç olur.'),
    ('We pick apples from the tree.', 'Ağaçtan elma toplarız.'),
  ],
  [
    ('Zeynep gets very hungry.', 'Zeynep çok acıkır.'),
    ('She cooks some pasta.', 'Biraz makarna pişirir.'),
    ('She eats all of it.', 'Hepsini yer.'),
  ],
  [
    ('The water boils.', 'Su kaynar.'),
    ('I put tea in the pot.', 'Demliğe çay koyarım.'),
    ('I drink a glass of tea.', 'Bir bardak çay içerim.'),
  ],
  [
    ('The shop is closed.', 'Dükkân kapalı.'),
    ('Mert waits at the door.', 'Mert kapının önünde bekler.'),
    ('At nine, the door opens.', 'Saat dokuzda kapı açılır.'),
  ],
  [
    ('The cat sees a bird.', 'Kedi bir kuş görür.'),
    ('It jumps at the bird.', 'Kuşa doğru atlar.'),
    ('The bird flies away.', 'Kuş uçup gider.'),
  ],
];

// ---- Parley ---------------------------------------------------------------

typedef _Line = (String, String);

/// Each turn: its line, and the replies with the one that answers it first.
/// The wrong replies are good sentences that answer some other question.
const List<List<(_Line, List<_Line>)>> _parleys = [
  [
    (
      ('Who are you, little one?', 'Sen kimsin, ufaklık?'),
      [
        ('I am your challenger.', 'Ben senin rakibinim.'),
        ('It is three o\'clock.', 'Saat üç.'),
        ('Yes, I like apples.', 'Evet, elma severim.'),
      ],
    ),
    (
      ('Where do you come from?', 'Nereden geliyorsun?'),
      [
        ('From a small village.', 'Küçük bir köyden.'),
        ('Tomorrow morning.', 'Yarın sabah.'),
        ('Because I am tired.', 'Çünkü yorgunum.'),
      ],
    ),
    (
      ('Why are you here?', 'Neden buradasın?'),
      [
        ('To pass your trial.', 'Sınavını geçmek için.'),
        ('By bus.', 'Otobüsle.'),
        ('Blue and green.', 'Mavi ve yeşil.'),
      ],
    ),
  ],
  [
    (
      ('Are you hungry?', 'Aç mısın?'),
      [
        ('No, I just ate.', 'Hayır, az önce yedim.'),
        ('It is on the table.', 'Masanın üstünde.'),
        ('My name is Pip.', 'Benim adım Pip.'),
      ],
    ),
    (
      ('What did you eat?', 'Ne yedin?'),
      [
        ('Some bread and cheese.', 'Biraz ekmek ve peynir.'),
        ('Next week.', 'Gelecek hafta.'),
        ('Very tall.', 'Çok uzun.'),
      ],
    ),
    (
      (
        'Do you want some of my fire peppers?',
        'Ateş biberlerimden ister misin?',
      ),
      [
        ('No, thank you.', 'Hayır, teşekkür ederim.'),
        ('At the station.', 'İstasyonda.'),
        ('Two years ago.', 'İki yıl önce.'),
      ],
    ),
  ],
  [
    (
      ('What is the weather like outside?', 'Dışarıda hava nasıl?'),
      [
        ('It is cold and windy.', 'Soğuk ve rüzgârlı.'),
        ('I have a brother.', 'Bir erkek kardeşim var.'),
        ('With my friends.', 'Arkadaşlarımla.'),
      ],
    ),
    (
      ('How long was your journey?', 'Yolculuğun ne kadar sürdü?'),
      [
        ('About three hours.', 'Yaklaşık üç saat.'),
        ('It was red.', 'Kırmızıydı.'),
        ('Under the bed.', 'Yatağın altında.'),
      ],
    ),
    (
      ('Will you go home after this?', 'Bundan sonra eve gidecek misin?'),
      [
        ('Yes, if I win.', 'Evet, kazanırsam.'),
        ('I am eating soup.', 'Çorba içiyorum.'),
        ('Twelve apples.', 'On iki elma.'),
      ],
    ),
  ],
  [
    (
      ('What do you do in your free time?', 'Boş zamanında ne yaparsın?'),
      [
        ('I read books.', 'Kitap okurum.'),
        ('It is next to the bank.', 'Bankanın yanında.'),
        ('Since Monday.', 'Pazartesiden beri.'),
      ],
    ),
    (
      ('Which book do you like best?', 'En çok hangi kitabı seversin?'),
      [
        ('A story about dragons.', 'Ejderhalar hakkında bir hikâye.'),
        ('Twice a week.', 'Haftada iki kez.'),
        ('I am fine, thanks.', 'İyiyim, teşekkürler.'),
      ],
    ),
    (
      ('Are the dragons in it kind?', 'İçindeki ejderhalar iyi mi?'),
      [
        ('Some of them are.', 'Bazıları öyle.'),
        ('At seven o\'clock.', 'Saat yedide.'),
        ('By plane.', 'Uçakla.'),
      ],
    ),
  ],
  [
    (
      ('Can you help me find my gold?', 'Altınımı bulmama yardım eder misin?'),
      [
        ('Of course. Where did you lose it?', 'Tabii. Nerede kaybettin?'),
        ('I am ten years old.', 'On yaşındayım.'),
        ('It tastes sweet.', 'Tadı tatlı.'),
      ],
    ),
    (
      ('I think I left it in the cave.', 'Sanırım mağarada bıraktım.'),
      [
        ('Let\'s go and look there.', 'Hadi gidip orada bakalım.'),
        ('My favourite colour is green.', 'En sevdiğim renk yeşil.'),
        ('I do not have a cat.', 'Kedim yok.'),
      ],
    ),
    (
      ('Thank you. Now, shall we fight?', 'Teşekkürler. Şimdi savaşalım mı?'),
      [
        ('Yes, I am ready.', 'Evet, hazırım.'),
        ('It is raining.', 'Yağmur yağıyor.'),
        ('In the kitchen.', 'Mutfakta.'),
      ],
    ),
  ],
];

// ---- Flame Link -------------------------------------------------------------
//
// One list per language: which linking words a language has, and what they
// join, is its own. The two wrong runes are chosen so that neither makes a
// sentence that is merely odd: "I stayed at home although it was raining"
// could be defended, so "although" is not offered there.

const List<LinkItem> _englishLinks = [
  LinkItem(
    left: 'I stayed at home',
    right: 'it was raining.',
    links: ['because', 'unless', 'so'],
    meaning: 'Yağmur yağdığı için evde kaldım.',
  ),
  LinkItem(
    left: 'She was tired,',
    right: 'she kept working.',
    links: ['but', 'unless', 'or'],
    meaning: 'Yorgundu ama çalışmaya devam etti.',
  ),
  LinkItem(
    left: 'It was cold,',
    right: 'I wore a coat.',
    links: ['so', 'because', 'unless'],
    meaning: 'Hava soğuktu, bu yüzden palto giydim.',
  ),
  LinkItem(
    left: 'You will miss the bus',
    right: 'you hurry.',
    links: ['unless', 'because', 'so'],
    meaning: 'Acele etmezsen otobüsü kaçıracaksın.',
  ),
  LinkItem(
    left: 'He is rich,',
    right: 'he is not happy.',
    links: ['but', 'so', 'because'],
    meaning: 'Zengin ama mutlu değil.',
  ),
  LinkItem(
    left: 'I will call you',
    right: 'I arrive.',
    links: ['when', 'although', 'because'],
    meaning: 'Varınca seni arayacağım.',
  ),
  LinkItem(
    left: 'She studied hard',
    right: 'she could pass the exam.',
    links: ['so that', 'although', 'unless'],
    meaning: 'Sınavı geçebilmek için çok çalıştı.',
  ),
  LinkItem(
    left: 'My brother likes tea,',
    right: 'I prefer coffee.',
    links: ['whereas', 'because', 'so'],
    meaning: 'Erkek kardeşim çayı sever, oysa ben kahveyi tercih ederim.',
  ),
];

const List<LinkItem> _turkishLinks = [
  LinkItem(
    left: 'Evde kaldım',
    right: 'yağmur yağıyordu.',
    links: ['çünkü', 'yoksa', 'bu yüzden'],
    meaning: 'I stayed at home because it was raining.',
  ),
  LinkItem(
    left: 'Yorgundu',
    right: 'çalışmaya devam etti.',
    links: ['ama', 'çünkü', 'yoksa'],
    meaning: 'She was tired, but she kept working.',
  ),
  LinkItem(
    left: 'Hava soğuktu,',
    right: 'palto giydim.',
    links: ['bu yüzden', 'çünkü', 'yoksa'],
    meaning: 'It was cold, so I wore a coat.',
  ),
  LinkItem(
    left: 'Acele et,',
    right: 'otobüsü kaçıracaksın.',
    links: ['yoksa', 'çünkü', 'ama'],
    meaning: 'Hurry, or you will miss the bus.',
  ),
  LinkItem(
    left: 'Zengin',
    right: 'mutlu değil.',
    links: ['fakat', 'çünkü', 'bu yüzden'],
    meaning: 'He is rich, but he is not happy.',
  ),
  LinkItem(
    left: 'Kardeşim çayı sever,',
    right: 'ben kahveyi tercih ederim.',
    links: ['oysa', 'çünkü', 'bu yüzden'],
    meaning: 'My brother likes tea, whereas I prefer coffee.',
  ),
  LinkItem(
    left: 'Çok yorgundum,',
    right: 'erken yattım.',
    links: ['bu yüzden', 'ama', 'yoksa'],
    meaning: 'I was very tired, so I went to bed early.',
  ),
  LinkItem(
    left: 'Sınav zordu,',
    right: 'geçtim.',
    links: ['yine de', 'çünkü', 'yoksa'],
    meaning: 'The exam was hard; still, I passed.',
  ),
];

// ---- Ember Paraphrase -------------------------------------------------------
//
// One list per language: the point is saying the same thing another way in
// the language being learned — idioms first among them — and idioms do not
// translate. The wrong embers take a word from the sentence and mean
// something else with it.

const List<ParaphraseItem> _englishParaphrases = [
  ParaphraseItem(
    line: 'I am starving.',
    options: ['I am very hungry.', 'I am very tired.', 'I am very cold.'],
    meaning: 'Çok açım.',
  ),
  ParaphraseItem(
    line: 'She passed away last year.',
    options: [
      'She died last year.',
      'She moved away last year.',
      'She walked past last year.',
    ],
    meaning: 'Geçen yıl vefat etti.',
  ),
  ParaphraseItem(
    line: 'Can you give me a hand?',
    options: [
      'Can you help me?',
      'Can you shake my hand?',
      'Can you give me a ring?',
    ],
    meaning: 'Bana yardım eder misin?',
  ),
  ParaphraseItem(
    line: 'It is up to you.',
    options: ['You decide.', 'It is above you.', 'It is your turn.'],
    meaning: 'Sana kalmış.',
  ),
  ParaphraseItem(
    line: 'I cannot stand this music.',
    options: [
      'I really dislike this music.',
      'I cannot dance to this music.',
      'I cannot hear this music.',
    ],
    meaning: 'Bu müziğe dayanamıyorum.',
  ),
  ParaphraseItem(
    line: 'He is under the weather.',
    options: [
      'He feels ill.',
      'He is out in the rain.',
      'He is very sad.',
    ],
    meaning: 'Biraz rahatsız.',
  ),
  ParaphraseItem(
    line: 'Let us call it a day.',
    options: [
      'Let us stop working now.',
      'Let us phone someone today.',
      'Let us name the day.',
    ],
    meaning: 'Bugünlük bu kadar yeter.',
  ),
  ParaphraseItem(
    line: 'The shop is closed on Sundays.',
    options: [
      'The shop does not open on Sundays.',
      'The shop closes early on Sundays.',
      'The shop is busy on Sundays.',
    ],
    meaning: 'Dükkân pazar günleri kapalı.',
  ),
];

const List<ParaphraseItem> _turkishParaphrases = [
  ParaphraseItem(
    line: 'Karnım zil çalıyor.',
    options: ['Çok acıktım.', 'Çok yoruldum.', 'Kulaklarım çınlıyor.'],
    meaning: 'I am starving.',
  ),
  ParaphraseItem(
    line: 'Ağzı kulaklarında.',
    options: ['Çok mutlu.', 'Çok konuşuyor.', 'Kulağı ağrıyor.'],
    meaning: 'He is grinning from ear to ear.',
  ),
  ParaphraseItem(
    line: 'Eli açık biridir.',
    options: [
      'Cömert biridir.',
      'Eli boş biridir.',
      'Kapıyı açık bırakır.',
    ],
    meaning: 'He is a generous person.',
  ),
  ParaphraseItem(
    line: 'Bebeğe göz kulak ol.',
    options: [
      'Bebeğe dikkat et.',
      'Bebeğin gözüne bak.',
      'Bebeğe şarkı söyle.',
    ],
    meaning: 'Keep an eye on the baby.',
  ),
  ParaphraseItem(
    line: 'Bugün hava çok sıcak.',
    options: [
      'Bugün hava bunaltıcı.',
      'Bugün hava serin.',
      'Bugün yağmur yağıyor.',
    ],
    meaning: 'It is very hot today.',
  ),
  ParaphraseItem(
    line: 'Dükkân pazar günleri kapalı.',
    options: [
      'Dükkân pazar günleri açılmıyor.',
      'Dükkân pazar günleri erken kapanıyor.',
      'Dükkân pazarın yanında.',
    ],
    meaning: 'The shop is closed on Sundays.',
  ),
  ParaphraseItem(
    line: 'Ona kulak ver.',
    options: ['Onu dinle.', 'Ona kulağını göster.', 'Ona hediye ver.'],
    meaning: 'Listen to him.',
  ),
  ParaphraseItem(
    line: 'Canım sıkılıyor.',
    options: ['Sıkıldım.', 'Canım acıyor.', 'Çok heyecanlıyım.'],
    meaning: 'I am bored.',
  ),
];

// ---- Hoard ----------------------------------------------------------------
//
// Again one list per language: which verb a noun takes is the whole point,
// and it is not the same verb in the two.

const List<Collocation> _englishPhrases = [
  Collocation('make', 'a mistake', 'hata yapmak'),
  Collocation('take', 'a photo', 'fotoğraf çekmek'),
  Collocation('do', 'homework', 'ödev yapmak'),
  Collocation('catch', 'a cold', 'nezle olmak'),
  Collocation('tell', 'the truth', 'doğruyu söylemek'),
  Collocation('pay', 'attention', 'dikkat etmek'),
  Collocation('break', 'a promise', 'sözünden dönmek'),
  Collocation('ride', 'a bike', 'bisiklete binmek'),
  Collocation('brush', 'your teeth', 'dişlerini fırçalamak'),
  Collocation('fall', 'asleep', 'uykuya dalmak'),
  Collocation('set', 'the table', 'sofrayı kurmak'),
  Collocation('make', 'a decision', 'karar vermek'),
];

/// Pairs a speaker would take as a phrase too: "make a promise".
const Set<(String, String)> _englishAlsoFit = {
  ('make', 'a promise'),
  ('take', 'a decision'),
  ('do', 'a mistake'),
};

const List<Collocation> _turkishPhrases = [
  Collocation('fotoğraf', 'çekmek', 'take a photo'),
  Collocation('hata', 'yapmak', 'make a mistake'),
  Collocation('sır', 'tutmak', 'keep a secret'),
  Collocation('söz', 'vermek', 'make a promise'),
  Collocation('dikkat', 'etmek', 'pay attention'),
  Collocation('para', 'biriktirmek', 'save money'),
  Collocation('bisiklete', 'binmek', 'ride a bike'),
  Collocation('dişlerini', 'fırçalamak', 'brush your teeth'),
  Collocation('karar', 'vermek', 'make a decision'),
  Collocation('nezle', 'olmak', 'catch a cold'),
  Collocation('yalan', 'söylemek', 'tell a lie'),
  Collocation('ders', 'çalışmak', 'study'),
];

const Set<(String, String)> _turkishAlsoFit = {
  ('söz', 'tutmak'),
  ('sır', 'vermek'),
  ('dikkat', 'çekmek'),
  ('para', 'çekmek'),
  ('para', 'vermek'),
  ('ders', 'vermek'),
  ('hata', 'vermek'),
  ('sır', 'söylemek'),
  ('karar', 'tutmak'),
};
