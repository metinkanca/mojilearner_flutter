// ignore_for_file: constant_identifier_names

class FaceDefinition {
  final String open;
  final String? closed;
  final int minLevel;

  const FaceDefinition({required this.open, this.closed, this.minLevel = 1});

  factory FaceDefinition.simple(String open, {int minLevel = 1}) {
    return FaceDefinition(open: open, minLevel: minLevel);
  }
}

class Faces {
  static const List<FaceDefinition> neutral = [
    FaceDefinition(open: '(•_•)', closed: '(-_-)', minLevel: 1),
    FaceDefinition(open: '( ._. )', closed: '( -_- )', minLevel: 1),
    FaceDefinition(open: '(￣_￣)', minLevel: 2),
    FaceDefinition(open: '( ˙꒳​˙ )', closed: '( -꒳- )', minLevel: 3),
    FaceDefinition(open: '(¬_¬ )', minLevel: 5),
  ];

  static const List<FaceDefinition> happy = [
    FaceDefinition(open: '(｡•‿•｡)', closed: '(｡-‿-｡)', minLevel: 1),
    FaceDefinition(open: '(o^▽^o)', closed: '(o-▽-o)', minLevel: 2),
    FaceDefinition(open: '(≧◡≦)', minLevel: 3),
    FaceDefinition(open: '(´｡• ᵕ •｡`)', closed: '(´｡- ᵕ -｡`)', minLevel: 5),
    FaceDefinition(open: '(⌒▽⌒)☆', minLevel: 8),
    FaceDefinition(open: '(☆▽☆)', minLevel: 10),
  ];

  static const List<FaceDefinition> sad = [
    FaceDefinition(open: '(╥_╥)', closed: '(>_<)', minLevel: 1),
    FaceDefinition(open: '(｡•́︿•̀｡)', minLevel: 1),
    FaceDefinition(open: '(T_T)', minLevel: 1),
  ];

  static const List<FaceDefinition> hungry = [
    FaceDefinition(open: '(￣﹃￣)', minLevel: 1),
    FaceDefinition(open: '(o˘◡˘o)', minLevel: 1),
    FaceDefinition(open: '(º﹃º)', minLevel: 1),
  ];

  static const List<FaceDefinition> sleeping = [
    FaceDefinition(open: '(ー_ー) zzz', closed: '(—_—) zzz', minLevel: 1),
    FaceDefinition(open: '(ᴗ_ ᴗ。)', minLevel: 1),
  ];

  static const List<FaceDefinition> thinking = [
    FaceDefinition(open: '(¬_¬)', minLevel: 1),
    FaceDefinition(open: '(・_・ヾ', minLevel: 2),
    FaceDefinition(open: '(￣ω￣;)', minLevel: 4),
    FaceDefinition(open: '(・・ ) ?', minLevel: 6),
    FaceDefinition(open: '(¬‿¬ )', minLevel: 8),
    FaceDefinition(open: '(˘･_･˘)', minLevel: 10),
  ];

  static const List<FaceDefinition> confused = [
    FaceDefinition(open: '(⊙_⊙)', minLevel: 1),
    FaceDefinition(open: '(o_O)', minLevel: 2),
    FaceDefinition(open: '(・・?)', closed: '(- -?)', minLevel: 3),
    FaceDefinition(open: '(● ●)？', minLevel: 5),
    FaceDefinition(open: '┐(‘～` )┌', minLevel: 7),
    FaceDefinition(open: '(・_・;)', minLevel: 9),
  ];

  static const List<FaceDefinition> excited = [
    FaceDefinition(open: '＼(＾O＾)／', minLevel: 1),
    FaceDefinition(open: 'o(≧▽≦)o', minLevel: 3),
    FaceDefinition(open: '☆*:.｡.o(≧▽≦)o.｡.:*☆', minLevel: 5),
    FaceDefinition(open: 'ヽ(o^ ^o)ﾉ', minLevel: 7),
    FaceDefinition(open: '(☆▽☆)', minLevel: 9),
    FaceDefinition(open: '٩(•‿•｡)۶', minLevel: 10),
  ];

  static Map<String, List<FaceDefinition>> get all => {
    'neutral': neutral,
    'happy': happy,
    'sad': sad,
    'hungry': hungry,
    'sleeping': sleeping,
    'thinking': thinking,
    'confused': confused,
    'excited': excited,
  };
}
