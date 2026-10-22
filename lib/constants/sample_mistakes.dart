import '../models/models.dart';

/// English sentences with a typical learner's slip, the correction, and the
/// explanation in Turkish, for filling the Mistakes and Review screens while
/// they are being built. Only ever added when [AppRuntimeConfig.sampleMistakes]
/// is on, and never saved: see `MistakesProvider.loadMistakes`.
///
/// The ids are stable so a sample is never added twice.
final List<Mistake> kSampleMistakes = [
  _sample(
    1,
    'I goed to school yesterday.',
    'I went to school yesterday.',
    '"Go" düzensiz bir fiildir. Geçmiş zamanı "goed" değil "went" olur.',
    'grammar',
  ),
  _sample(
    2,
    "She don't like coffee.",
    "She doesn't like coffee.",
    'He/she/it ile olumsuz cümlede "don\'t" değil "doesn\'t" kullanılır. '
        'Asıl fiil yalın kalır: like.',
    'grammar',
  ),
  _sample(
    3,
    'I am agree with you.',
    'I agree with you.',
    '"Agree" kendi başına bir fiildir, başına "am" gerekmez. '
        'Türkçedeki "katılıyorum" gibi tek parça: I agree.',
    'grammar',
  ),
  _sample(
    4,
    'He is more taller than me.',
    'He is taller than me.',
    '"Taller" zaten karşılaştırma halidir. "More" ile birlikte kullanılmaz; '
        'ikisini birden söylemek fazladır.',
    'grammar',
  ),
  _sample(
    5,
    'I will make a photo of the sea.',
    'I will take a photo of the sea.',
    'Fotoğraf için "make" değil "take" denir. Türkçede "fotoğraf çekmek" '
        'dediğimiz yerde İngilizce "take a photo" der.',
    'vocabulary',
  ),
  _sample(
    6,
    'Can you say me the time?',
    'Can you tell me the time?',
    'Birine bir şey söylerken kişi nesnesiyle "say" değil "tell" kullanılır: '
        'tell someone something.',
    'vocabulary',
  ),
];

Mistake _sample(
  int n,
  String original,
  String correction,
  String explanation,
  String type,
) =>
    Mistake(
      id: '$kSampleMistakeIdPrefix$n',
      original: original,
      correction: correction,
      explanation: explanation,
      type: type,
      timestamp: DateTime(2026, 10, 22).subtract(Duration(hours: n)),
    );

/// What marks a mistake as a sample, so it can be kept out of storage.
const String kSampleMistakeIdPrefix = 'sample-';
