/// Stock sentences for a boss trial's sentence rounds: Mossback's Spells,
/// Amethyst's echo, and the witch's Hexed Scroll and brewing.
///
/// A TESTING PLACEHOLDER, like `boss_trial_words.dart`, and built on the same
/// twelve nouns, so the round that asks a player to answer uses the words the
/// round before it asked them to understand. A real trial would draw its
/// sentences from the level band.
///
/// Every language the app teaches is here, pre-split into word stones — which
/// is the only way to do it for Japanese, Chinese and Thai, which do not put
/// spaces between words. Every language can be either side of the pair: the
/// stones come from the language being learned, the prompt from the player's.
///
/// The six sentences, in this order in every row:
/// the cat drinks milk / the dog eats bread / I read a book /
/// my friend has a house / I drink water / I see a star.
///
/// Stones are written as they appear mid-sentence: no capital on the first
/// word unless the language always writes one there (German nouns, English
/// "I"), and no closing punctuation, so neither gives away where a sentence
/// starts or ends.
library;

import '../utils/boss_trial.dart';
import 'app_runtime_config.dart';

const Map<String, List<List<String>>> _sentences = {
  'en': [
    ['the', 'cat', 'drinks', 'milk'],
    ['the', 'dog', 'eats', 'bread'],
    ['I', 'read', 'a', 'book'],
    ['my', 'friend', 'has', 'a', 'house'],
    ['I', 'drink', 'water'],
    ['I', 'see', 'a', 'star'],
  ],
  'es': [
    ['el', 'gato', 'bebe', 'leche'],
    ['el', 'perro', 'come', 'pan'],
    ['yo', 'leo', 'un', 'libro'],
    ['mi', 'amigo', 'tiene', 'una', 'casa'],
    ['yo', 'bebo', 'agua'],
    ['yo', 'veo', 'una', 'estrella'],
  ],
  'fr': [
    ['le', 'chat', 'boit', 'du', 'lait'],
    ['le', 'chien', 'mange', 'du', 'pain'],
    ['je', 'lis', 'un', 'livre'],
    ['mon', 'ami', 'a', 'une', 'maison'],
    ['je', 'bois', 'de', "l'eau"],
    ['je', 'vois', 'une', 'étoile'],
  ],
  'de': [
    ['die', 'Katze', 'trinkt', 'Milch'],
    ['der', 'Hund', 'frisst', 'Brot'],
    ['ich', 'lese', 'ein', 'Buch'],
    ['mein', 'Freund', 'hat', 'ein', 'Haus'],
    ['ich', 'trinke', 'Wasser'],
    ['ich', 'sehe', 'einen', 'Stern'],
  ],
  'it': [
    ['il', 'gatto', 'beve', 'il', 'latte'],
    ['il', 'cane', 'mangia', 'il', 'pane'],
    ['io', 'leggo', 'un', 'libro'],
    ['il', 'mio', 'amico', 'ha', 'una', 'casa'],
    ['io', 'bevo', 'acqua'],
    ['io', 'vedo', 'una', 'stella'],
  ],
  'pt': [
    ['o', 'gato', 'bebe', 'leite'],
    ['o', 'cachorro', 'come', 'pão'],
    ['eu', 'leio', 'um', 'livro'],
    ['meu', 'amigo', 'tem', 'uma', 'casa'],
    ['eu', 'bebo', 'água'],
    ['eu', 'vejo', 'uma', 'estrela'],
  ],
  'ru': [
    ['кошка', 'пьёт', 'молоко'],
    ['собака', 'ест', 'хлеб'],
    ['я', 'читаю', 'книгу'],
    ['у', 'моего', 'друга', 'есть', 'дом'],
    ['я', 'пью', 'воду'],
    ['я', 'вижу', 'звезду'],
  ],
  'ja': [
    ['ねこ', 'は', 'ミルク', 'を', 'のむ'],
    ['いぬ', 'は', 'パン', 'を', 'たべる'],
    ['わたし', 'は', 'ほん', 'を', 'よむ'],
    ['ともだち', 'は', 'いえ', 'を', 'もっている'],
    ['わたし', 'は', 'みず', 'を', 'のむ'],
    ['わたし', 'は', 'ほし', 'を', 'みる'],
  ],
  'zh': [
    ['猫', '喝', '牛奶'],
    ['狗', '吃', '面包'],
    ['我', '看', '书'],
    ['我的', '朋友', '有', '房子'],
    ['我', '喝', '水'],
    ['我', '看见', '星星'],
  ],
  'ko': [
    ['고양이가', '우유를', '마셔요'],
    ['개가', '빵을', '먹어요'],
    ['저는', '책을', '읽어요'],
    ['제', '친구는', '집이', '있어요'],
    ['저는', '물을', '마셔요'],
    ['저는', '별을', '봐요'],
  ],
  'ar': [
    ['القطة', 'تشرب', 'الحليب'],
    ['الكلب', 'يأكل', 'الخبز'],
    ['أنا', 'أقرأ', 'كتابا'],
    ['لدى', 'صديقي', 'بيت'],
    ['أنا', 'أشرب', 'الماء'],
    ['أنا', 'أرى', 'نجمة'],
  ],
  'hi': [
    ['बिल्ली', 'दूध', 'पीती', 'है'],
    ['कुत्ता', 'रोटी', 'खाता', 'है'],
    ['मैं', 'किताब', 'पढ़ता', 'हूँ'],
    ['मेरे', 'दोस्त', 'के', 'पास', 'घर', 'है'],
    ['मैं', 'पानी', 'पीता', 'हूँ'],
    ['मैं', 'तारा', 'देखता', 'हूँ'],
  ],
  'tr': [
    ['kedi', 'süt', 'içiyor'],
    ['köpek', 'ekmek', 'yiyor'],
    ['ben', 'kitap', 'okuyorum'],
    ['arkadaşımın', 'bir', 'evi', 'var'],
    ['ben', 'su', 'içiyorum'],
    ['ben', 'bir', 'yıldız', 'görüyorum'],
  ],
  'nl': [
    ['de', 'kat', 'drinkt', 'melk'],
    ['de', 'hond', 'eet', 'brood'],
    ['ik', 'lees', 'een', 'boek'],
    ['mijn', 'vriend', 'heeft', 'een', 'huis'],
    ['ik', 'drink', 'water'],
    ['ik', 'zie', 'een', 'ster'],
  ],
  'sv': [
    ['katten', 'dricker', 'mjölk'],
    ['hunden', 'äter', 'bröd'],
    ['jag', 'läser', 'en', 'bok'],
    ['min', 'vän', 'har', 'ett', 'hus'],
    ['jag', 'dricker', 'vatten'],
    ['jag', 'ser', 'en', 'stjärna'],
  ],
  'pl': [
    ['kot', 'pije', 'mleko'],
    ['pies', 'je', 'chleb'],
    ['ja', 'czytam', 'książkę'],
    ['mój', 'przyjaciel', 'ma', 'dom'],
    ['ja', 'piję', 'wodę'],
    ['ja', 'widzę', 'gwiazdę'],
  ],
  'id': [
    ['kucing', 'minum', 'susu'],
    ['anjing', 'makan', 'roti'],
    ['saya', 'membaca', 'buku'],
    ['teman', 'saya', 'punya', 'rumah'],
    ['saya', 'minum', 'air'],
    ['saya', 'melihat', 'bintang'],
  ],
  'vi': [
    ['con', 'mèo', 'uống', 'sữa'],
    ['con', 'chó', 'ăn', 'bánh mì'],
    ['tôi', 'đọc', 'sách'],
    ['bạn', 'tôi', 'có', 'nhà'],
    ['tôi', 'uống', 'nước'],
    ['tôi', 'thấy', 'ngôi sao'],
  ],
  'th': [
    ['แมว', 'ดื่ม', 'นม'],
    ['สุนัข', 'กิน', 'ขนมปัง'],
    ['ฉัน', 'อ่าน', 'หนังสือ'],
    ['เพื่อน', 'ของ', 'ฉัน', 'มี', 'บ้าน'],
    ['ฉัน', 'ดื่ม', 'น้ำ'],
    ['ฉัน', 'เห็น', 'ดาว'],
  ],
  'el': [
    ['η', 'γάτα', 'πίνει', 'γάλα'],
    ['ο', 'σκύλος', 'τρώει', 'ψωμί'],
    ['εγώ', 'διαβάζω', 'ένα', 'βιβλίο'],
    ['ο', 'φίλος', 'μου', 'έχει', 'ένα', 'σπίτι'],
    ['εγώ', 'πίνω', 'νερό'],
    ['εγώ', 'βλέπω', 'ένα', 'αστέρι'],
  ],
  'uk': [
    ['кіт', "п'є", 'молоко'],
    ['собака', 'їсть', 'хліб'],
    ['я', 'читаю', 'книгу'],
    ['у', 'мого', 'друга', 'є', 'будинок'],
    ['я', "п'ю", 'воду'],
    ['я', 'бачу', 'зірку'],
  ],
  'da': [
    ['katten', 'drikker', 'mælk'],
    ['hunden', 'spiser', 'brød'],
    ['jeg', 'læser', 'en', 'bog'],
    ['min', 'ven', 'har', 'et', 'hus'],
    ['jeg', 'drikker', 'vand'],
    ['jeg', 'ser', 'en', 'stjerne'],
  ],
  'fi': [
    ['kissa', 'juo', 'maitoa'],
    ['koira', 'syö', 'leipää'],
    ['minä', 'luen', 'kirjaa'],
    ['ystävälläni', 'on', 'talo'],
    ['minä', 'juon', 'vettä'],
    ['minä', 'näen', 'tähden'],
  ],
  'no': [
    ['katten', 'drikker', 'melk'],
    ['hunden', 'spiser', 'brød'],
    ['jeg', 'leser', 'en', 'bok'],
    ['vennen', 'min', 'har', 'et', 'hus'],
    ['jeg', 'drikker', 'vann'],
    ['jeg', 'ser', 'en', 'stjerne'],
  ],
  'cs': [
    ['kočka', 'pije', 'mléko'],
    ['pes', 'jí', 'chléb'],
    ['já', 'čtu', 'knihu'],
    ['můj', 'přítel', 'má', 'dům'],
    ['já', 'piju', 'vodu'],
    ['já', 'vidím', 'hvězdu'],
  ],
  'ro': [
    ['pisica', 'bea', 'lapte'],
    ['câinele', 'mănâncă', 'pâine'],
    ['eu', 'citesc', 'o', 'carte'],
    ['prietenul', 'meu', 'are', 'o', 'casă'],
    ['eu', 'beau', 'apă'],
    ['eu', 'văd', 'o', 'stea'],
  ],
  'hu': [
    ['a', 'macska', 'tejet', 'iszik'],
    ['a', 'kutya', 'kenyeret', 'eszik'],
    ['én', 'egy', 'könyvet', 'olvasok'],
    ['a', 'barátomnak', 'van', 'egy', 'háza'],
    ['én', 'vizet', 'iszom'],
    ['én', 'egy', 'csillagot', 'látok'],
  ],
};

/// What each row's hexable words mean, in row order: its subject, verb and
/// object. A null subject is a pronoun, which is never hexed — "I" swapped
/// for "the cat" breaks the verb's agreement long before the meaning. It is
/// still what the sentence is about, so its concepts count it as "me".
const List<({String? subject, String verb, String object})> _meanings = [
  (subject: 'cat', verb: 'drink', object: 'milk'),
  (subject: 'dog', verb: 'eat', object: 'bread'),
  (subject: null, verb: 'read', object: 'book'),
  (subject: 'friend', verb: 'have', object: 'house'),
  (subject: null, verb: 'drink', object: 'water'),
  (subject: null, verb: 'see', object: 'star'),
];

/// The stones that play those parts in each row, as written in [_sentences]:
/// subject (null for a pronoun), verb, object.
///
/// A hex on the witch's scroll swaps one of these for the same part of
/// another row, so "el gato bebe leche" can come out "el gato bebe pan" or
/// "el gato come leche", never "el pan bebe leche". Where a language builds
/// "has" out of a preposition or an existential (у … есть, के पास … है,
/// لدى), the word standing in for the verb is the one that carries "has".
const Map<String, List<List<String?>>> _parts = {
  'en': [['cat', 'drinks', 'milk'], ['dog', 'eats', 'bread'],
         [null, 'read', 'book'], ['friend', 'has', 'house'],
         [null, 'drink', 'water'], [null, 'see', 'star']],
  'es': [['gato', 'bebe', 'leche'], ['perro', 'come', 'pan'],
         [null, 'leo', 'libro'], ['amigo', 'tiene', 'casa'],
         [null, 'bebo', 'agua'], [null, 'veo', 'estrella']],
  'fr': [['chat', 'boit', 'lait'], ['chien', 'mange', 'pain'],
         [null, 'lis', 'livre'], ['ami', 'a', 'maison'],
         [null, 'bois', "l'eau"], [null, 'vois', 'étoile']],
  'de': [['Katze', 'trinkt', 'Milch'], ['Hund', 'frisst', 'Brot'],
         [null, 'lese', 'Buch'], ['Freund', 'hat', 'Haus'],
         [null, 'trinke', 'Wasser'], [null, 'sehe', 'Stern']],
  'it': [['gatto', 'beve', 'latte'], ['cane', 'mangia', 'pane'],
         [null, 'leggo', 'libro'], ['amico', 'ha', 'casa'],
         [null, 'bevo', 'acqua'], [null, 'vedo', 'stella']],
  'pt': [['gato', 'bebe', 'leite'], ['cachorro', 'come', 'pão'],
         [null, 'leio', 'livro'], ['amigo', 'tem', 'casa'],
         [null, 'bebo', 'água'], [null, 'vejo', 'estrela']],
  'ru': [['кошка', 'пьёт', 'молоко'], ['собака', 'ест', 'хлеб'],
         [null, 'читаю', 'книгу'], ['друга', 'есть', 'дом'],
         [null, 'пью', 'воду'], [null, 'вижу', 'звезду']],
  'ja': [['ねこ', 'のむ', 'ミルク'], ['いぬ', 'たべる', 'パン'],
         [null, 'よむ', 'ほん'], ['ともだち', 'もっている', 'いえ'],
         [null, 'のむ', 'みず'], [null, 'みる', 'ほし']],
  'zh': [['猫', '喝', '牛奶'], ['狗', '吃', '面包'],
         [null, '看', '书'], ['朋友', '有', '房子'],
         [null, '喝', '水'], [null, '看见', '星星']],
  'ko': [['고양이가', '마셔요', '우유를'], ['개가', '먹어요', '빵을'],
         [null, '읽어요', '책을'], ['친구는', '있어요', '집이'],
         [null, '마셔요', '물을'], [null, '봐요', '별을']],
  'ar': [['القطة', 'تشرب', 'الحليب'], ['الكلب', 'يأكل', 'الخبز'],
         [null, 'أقرأ', 'كتابا'], ['صديقي', 'لدى', 'بيت'],
         [null, 'أشرب', 'الماء'], [null, 'أرى', 'نجمة']],
  'hi': [['बिल्ली', 'पीती', 'दूध'], ['कुत्ता', 'खाता', 'रोटी'],
         [null, 'पढ़ता', 'किताब'], ['दोस्त', 'है', 'घर'],
         [null, 'पीता', 'पानी'], [null, 'देखता', 'तारा']],
  'tr': [['kedi', 'içiyor', 'süt'], ['köpek', 'yiyor', 'ekmek'],
         [null, 'okuyorum', 'kitap'], ['arkadaşımın', 'var', 'evi'],
         [null, 'içiyorum', 'su'], [null, 'görüyorum', 'yıldız']],
  'nl': [['kat', 'drinkt', 'melk'], ['hond', 'eet', 'brood'],
         [null, 'lees', 'boek'], ['vriend', 'heeft', 'huis'],
         [null, 'drink', 'water'], [null, 'zie', 'ster']],
  'sv': [['katten', 'dricker', 'mjölk'], ['hunden', 'äter', 'bröd'],
         [null, 'läser', 'bok'], ['vän', 'har', 'hus'],
         [null, 'dricker', 'vatten'], [null, 'ser', 'stjärna']],
  'pl': [['kot', 'pije', 'mleko'], ['pies', 'je', 'chleb'],
         [null, 'czytam', 'książkę'], ['przyjaciel', 'ma', 'dom'],
         [null, 'piję', 'wodę'], [null, 'widzę', 'gwiazdę']],
  'id': [['kucing', 'minum', 'susu'], ['anjing', 'makan', 'roti'],
         [null, 'membaca', 'buku'], ['teman', 'punya', 'rumah'],
         [null, 'minum', 'air'], [null, 'melihat', 'bintang']],
  'vi': [['mèo', 'uống', 'sữa'], ['chó', 'ăn', 'bánh mì'],
         [null, 'đọc', 'sách'], ['bạn', 'có', 'nhà'],
         [null, 'uống', 'nước'], [null, 'thấy', 'ngôi sao']],
  'th': [['แมว', 'ดื่ม', 'นม'], ['สุนัข', 'กิน', 'ขนมปัง'],
         [null, 'อ่าน', 'หนังสือ'], ['เพื่อน', 'มี', 'บ้าน'],
         [null, 'ดื่ม', 'น้ำ'], [null, 'เห็น', 'ดาว']],
  'el': [['γάτα', 'πίνει', 'γάλα'], ['σκύλος', 'τρώει', 'ψωμί'],
         [null, 'διαβάζω', 'βιβλίο'], ['φίλος', 'έχει', 'σπίτι'],
         [null, 'πίνω', 'νερό'], [null, 'βλέπω', 'αστέρι']],
  'uk': [['кіт', "п'є", 'молоко'], ['собака', 'їсть', 'хліб'],
         [null, 'читаю', 'книгу'], ['друга', 'є', 'будинок'],
         [null, "п'ю", 'воду'], [null, 'бачу', 'зірку']],
  'da': [['katten', 'drikker', 'mælk'], ['hunden', 'spiser', 'brød'],
         [null, 'læser', 'bog'], ['ven', 'har', 'hus'],
         [null, 'drikker', 'vand'], [null, 'ser', 'stjerne']],
  'fi': [['kissa', 'juo', 'maitoa'], ['koira', 'syö', 'leipää'],
         [null, 'luen', 'kirjaa'], ['ystävälläni', 'on', 'talo'],
         [null, 'juon', 'vettä'], [null, 'näen', 'tähden']],
  'no': [['katten', 'drikker', 'melk'], ['hunden', 'spiser', 'brød'],
         [null, 'leser', 'bok'], ['vennen', 'har', 'hus'],
         [null, 'drikker', 'vann'], [null, 'ser', 'stjerne']],
  'cs': [['kočka', 'pije', 'mléko'], ['pes', 'jí', 'chléb'],
         [null, 'čtu', 'knihu'], ['přítel', 'má', 'dům'],
         [null, 'piju', 'vodu'], [null, 'vidím', 'hvězdu']],
  'ro': [['pisica', 'bea', 'lapte'], ['câinele', 'mănâncă', 'pâine'],
         [null, 'citesc', 'carte'], ['prietenul', 'are', 'casă'],
         [null, 'beau', 'apă'], [null, 'văd', 'stea']],
  'hu': [['macska', 'iszik', 'tejet'], ['kutya', 'eszik', 'kenyeret'],
         [null, 'olvasok', 'könyvet'], ['barátomnak', 'van', 'háza'],
         [null, 'iszom', 'vizet'], [null, 'látok', 'csillagot']],
};

/// Languages written without spaces between words.
const Set<String> _unspaced = {'ja', 'zh', 'th'};

String _join(List<String> tokens, String code) =>
    tokens.join(_unspaced.contains(code) ? '' : ' ');

/// The languages a stock sentence set exists for — every one the app teaches.
Iterable<String> get bossTrialSentenceLanguages => _sentences.keys;

/// Stock sentences for learning [targetCode], prompted in [nativeCode].
///
/// Falls back to English prompts for a native language without a row, and
/// returns nothing for an unknown target or a target that is the player's own
/// language, the same as the word set.
List<TrialSentence> bossTrialStockSentences({
  required String? targetCode,
  required String? nativeCode,
}) {
  if (!AppRuntimeConfig.stockContent) return const [];
  final targets = _sentences[targetCode];
  if (targets == null) return const [];
  final meaningCode = _sentences.containsKey(nativeCode) ? nativeCode! : 'en';
  if (meaningCode == targetCode) return const [];
  final meanings = _sentences[meaningCode]!;
  final parts = _parts[targetCode];
  return [
    for (var i = 0; i < targets.length; i++)
      TrialSentence(
        tokens: targets[i],
        target: _join(targets[i], targetCode!),
        meaning: _join(meanings[i], meaningCode),
        slots: parts == null ? const [] : _slots(targets[i], parts[i], i),
        concepts: {
          _meanings[i].subject ?? 'me',
          _meanings[i].verb,
          _meanings[i].object,
        },
      ),
  ];
}

/// Row [row]'s hexable stones, found in [tokens] by the words in [parts].
List<HexSlot> _slots(List<String> tokens, List<String?> parts, int row) {
  final meaning = _meanings[row];
  final roles = [
    (HexRole.subject, meaning.subject),
    (HexRole.verb, meaning.verb),
    (HexRole.object, meaning.object),
  ];
  return [
    for (var p = 0; p < roles.length; p++)
      if (parts[p] case final word?)
        if (roles[p].$2 case final concept?)
          if (tokens.contains(word))
            HexSlot(
              index: tokens.indexOf(word),
              role: roles[p].$1,
              concept: concept,
            ),
  ];
}
