/// Stock words for boss trials, for a player whose review queue is too thin
/// to fill a fight on its own.
///
/// A TESTING PLACEHOLDER. A milestone trial is meant to draw on its level
/// band's vocabulary, fresh every run; until that pool exists these twelve
/// everyday nouns keep the Catch phase playable. The player's own words always
/// come first — see `TrialWordPool.build` — and these only top the pool up.
///
/// Every language the app teaches is here, and every one of them can be either
/// side of the pair: the tile shows the word in the language being learned and
/// the prompt shows it in the player's own. A table keyed on target alone, with
/// English meanings, dead-ended anyone learning a language it lacked and made
/// a fight about English trivial.
library;

import '../utils/boss_trial.dart';

/// One column per concept, in this order in every row:
/// apple, dog, cat, water, book, house, bread, night, friend, milk, door, star.
const Map<String, List<String>> _words = {
  'en': ['apple', 'dog', 'cat', 'water', 'book', 'house',
         'bread', 'night', 'friend', 'milk', 'door', 'star'],
  'es': ['manzana', 'perro', 'gato', 'agua', 'libro', 'casa',
         'pan', 'noche', 'amigo', 'leche', 'puerta', 'estrella'],
  'fr': ['pomme', 'chien', 'chat', 'eau', 'livre', 'maison',
         'pain', 'nuit', 'ami', 'lait', 'porte', 'étoile'],
  'de': ['Apfel', 'Hund', 'Katze', 'Wasser', 'Buch', 'Haus',
         'Brot', 'Nacht', 'Freund', 'Milch', 'Tür', 'Stern'],
  'it': ['mela', 'cane', 'gatto', 'acqua', 'libro', 'casa',
         'pane', 'notte', 'amico', 'latte', 'porta', 'stella'],
  'pt': ['maçã', 'cachorro', 'gato', 'água', 'livro', 'casa',
         'pão', 'noite', 'amigo', 'leite', 'porta', 'estrela'],
  'ru': ['яблоко', 'собака', 'кошка', 'вода', 'книга', 'дом',
         'хлеб', 'ночь', 'друг', 'молоко', 'дверь', 'звезда'],
  'ja': ['りんご', 'いぬ', 'ねこ', 'みず', 'ほん', 'いえ',
         'パン', 'よる', 'ともだち', 'ミルク', 'ドア', 'ほし'],
  'zh': ['苹果', '狗', '猫', '水', '书', '房子',
         '面包', '夜晚', '朋友', '牛奶', '门', '星星'],
  'ko': ['사과', '개', '고양이', '물', '책', '집',
         '빵', '밤', '친구', '우유', '문', '별'],
  'ar': ['تفاحة', 'كلب', 'قطة', 'ماء', 'كتاب', 'بيت',
         'خبز', 'ليل', 'صديق', 'حليب', 'باب', 'نجمة'],
  'hi': ['सेब', 'कुत्ता', 'बिल्ली', 'पानी', 'किताब', 'घर',
         'रोटी', 'रात', 'दोस्त', 'दूध', 'दरवाज़ा', 'तारा'],
  'tr': ['elma', 'köpek', 'kedi', 'su', 'kitap', 'ev',
         'ekmek', 'gece', 'arkadaş', 'süt', 'kapı', 'yıldız'],
  'nl': ['appel', 'hond', 'kat', 'water', 'boek', 'huis',
         'brood', 'nacht', 'vriend', 'melk', 'deur', 'ster'],
  'sv': ['äpple', 'hund', 'katt', 'vatten', 'bok', 'hus',
         'bröd', 'natt', 'vän', 'mjölk', 'dörr', 'stjärna'],
  'pl': ['jabłko', 'pies', 'kot', 'woda', 'książka', 'dom',
         'chleb', 'noc', 'przyjaciel', 'mleko', 'drzwi', 'gwiazda'],
  'id': ['apel', 'anjing', 'kucing', 'air', 'buku', 'rumah',
         'roti', 'malam', 'teman', 'susu', 'pintu', 'bintang'],
  'vi': ['táo', 'chó', 'mèo', 'nước', 'sách', 'nhà',
         'bánh mì', 'đêm', 'bạn', 'sữa', 'cửa', 'ngôi sao'],
  'th': ['แอปเปิ้ล', 'สุนัข', 'แมว', 'น้ำ', 'หนังสือ', 'บ้าน',
         'ขนมปัง', 'กลางคืน', 'เพื่อน', 'นม', 'ประตู', 'ดาว'],
  'el': ['μήλο', 'σκύλος', 'γάτα', 'νερό', 'βιβλίο', 'σπίτι',
         'ψωμί', 'νύχτα', 'φίλος', 'γάλα', 'πόρτα', 'αστέρι'],
  'uk': ['яблуко', 'собака', 'кіт', 'вода', 'книга', 'дім',
         'хліб', 'ніч', 'друг', 'молоко', 'двері', 'зірка'],
  'da': ['æble', 'hund', 'kat', 'vand', 'bog', 'hus',
         'brød', 'nat', 'ven', 'mælk', 'dør', 'stjerne'],
  'fi': ['omena', 'koira', 'kissa', 'vesi', 'kirja', 'talo',
         'leipä', 'yö', 'ystävä', 'maito', 'ovi', 'tähti'],
  'no': ['eple', 'hund', 'katt', 'vann', 'bok', 'hus',
         'brød', 'natt', 'venn', 'melk', 'dør', 'stjerne'],
  'cs': ['jablko', 'pes', 'kočka', 'voda', 'kniha', 'dům',
         'chléb', 'noc', 'přítel', 'mléko', 'dveře', 'hvězda'],
  'ro': ['măr', 'câine', 'pisică', 'apă', 'carte', 'casă',
         'pâine', 'noapte', 'prieten', 'lapte', 'ușă', 'stea'],
  'hu': ['alma', 'kutya', 'macska', 'víz', 'könyv', 'ház',
         'kenyér', 'éjszaka', 'barát', 'tej', 'ajtó', 'csillag'],
};

/// Romanised readings, for the scripts the results screen should help a
/// player say out loud. Same column order as [_words].
const Map<String, List<String>> _readings = {
  'ja': ['ringo', 'inu', 'neko', 'mizu', 'hon', 'ie',
         'pan', 'yoru', 'tomodachi', 'miruku', 'doa', 'hoshi'],
  'ko': ['sagwa', 'gae', 'goyangi', 'mul', 'chaek', 'jip',
         'ppang', 'bam', 'chingu', 'uyu', 'mun', 'byeol'],
  'zh': ['píngguǒ', 'gǒu', 'māo', 'shuǐ', 'shū', 'fángzi',
         'miànbāo', 'yèwǎn', 'péngyou', 'niúnǎi', 'mén', 'xīngxing'],
};

/// The languages a stock set exists for — every one the app teaches.
Iterable<String> get bossTrialStockLanguages => _words.keys;

/// The (target, native) pairs to try, in order, when the player's own pair
/// cannot fill a game: their pair, their target with English and then Spanish
/// meanings, Spanish from their language, and last Spanish from English — the
/// app's own default pair, which always can.
///
/// A pair fails when no language is chosen yet, or when it is the same
/// language on both sides, where every word would be its own answer and the
/// stock sets drop them all.
List<(String?, String?)> bossTrialFallbackPairs(
  String? targetCode,
  String? nativeCode,
) =>
    [
      (targetCode, nativeCode),
      (targetCode, 'en'),
      (targetCode, 'es'),
      ('es', nativeCode),
      ('es', 'en'),
    ];

/// Stock words for learning [targetCode], with meanings in [nativeCode].
///
/// A native language without a row falls back to English meanings rather
/// than to nothing. Returns an empty list only when the target has no row, or
/// when both sides are the same language and every prompt would be its own
/// answer.
List<TrialWord> bossTrialStockWords({
  required String? targetCode,
  required String? nativeCode,
}) {
  final targets = _words[targetCode];
  if (targets == null) return const [];
  final meaningCode = _words.containsKey(nativeCode) ? nativeCode! : 'en';
  if (meaningCode == targetCode) return const [];
  final meanings = _words[meaningCode]!;
  final readings = _readings[targetCode];
  return [
    for (var i = 0; i < targets.length; i++)
      TrialWord(
        target: targets[i],
        meaning: meanings[i],
        reading: readings?[i],
      ),
  ];
}
