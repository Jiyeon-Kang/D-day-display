import 'package:flutter/rendering.dart';

enum ChristmasOrnamentKind { gingerbread, candyCane, snowman, santa, rudolph }

const christmasOrnamentColors = [
  Color(0xffdda66a), // Baked gingerbread.
  Color(0xfffff4d6), // Icing.
  Color(0xffea6573), // Candy, hats and Rudolph's nose.
  Color(0xffe6f3f5), // Snow and Santa's beard.
  Color(0xfff2aa67), // Carrot.
  Color(0xff314259), // Eyes, buttons and hats.
  Color(0xff9e6d4f), // Antlers and twig arms.
  Color(0xffcfa376), // Reindeer face.
  Color(0xff8ec89f), // Scarf detail.
  Color(0xfff4cf79), // Golden hanging thread.
];

class OrnamentDot {
  const OrnamentDot({required this.x, required this.y, required this.color});

  final double x;
  final double y;
  final int color;
}

class OrnamentSprite {
  const OrnamentSprite({
    required this.width,
    required this.height,
    required this.dots,
  });

  final double width;
  final double height;
  final List<OrnamentDot> dots;
}

// Hand-drawn dot motifs: icing, striped hooks, scarves, beards and antlers
// retain recognizable silhouettes at the phone's small hanging ornament size.
const _motifs = {
  ChristmasOrnamentKind.gingerbread: [
    '....ccccc....',
    '...ccccccc...',
    '...ccicicc...',
    '...ccccccc...',
    '....cicic....',
    '.....ccc.....',
    '.cc..ccc..cc.',
    'ccccccccccccc',
    '.cicccrcccic.',
    '...cccrccc...',
    '...ccccccc...',
    '....cicic....',
    '...ccc.ccc...',
    '..cccc.cccc..',
    '..ciic.ciic..',
    '...cc...cc...',
  ],
  ChristmasOrnamentKind.candyCane: [
    '....wwwww..',
    '...wwrrrww.',
    '..wwrrrwwww',
    '..wrrrwwrrw',
    '..wrrwwrrrw',
    '..wwww..rrw',
    '...ww...rrw',
    '........wwr',
    '........wrr',
    '........rrw',
    '........rww',
    '........wwr',
    '........wrr',
    '........rrw',
    '........rww',
    '........wwr',
    '........www',
  ],
  ChristmasOrnamentKind.snowman: [
    '.....ddd.....',
    '....ddddd....',
    '...ddddddd...',
    '....wwwww....',
    '...wwdwdww...',
    '...wwwowww...',
    '....wwdww....',
    '...rrrrrrr...',
    '..bwwrwwwwb..',
    '.bbwwrwdwwbb.',
    '...wwwwwww...',
    '..wwwwwdwww..',
    '..wwwwwwwww..',
    '...wwwwwww...',
    '....wwwww....',
    '...dd...dd...',
  ],
  ChristmasOrnamentKind.santa: [
    '......rr.....',
    '.....rrrr....',
    '....rrrrrr...',
    '...rrrrrrrr..',
    '..rrrrrrrrrw.',
    '..wwwwwwwww..',
    '...ttttttt...',
    '...tdtttdt...',
    '..wwttottww..',
    '..wwwtrtwww..',
    '...wwwwwww...',
    '...wwdwdww...',
    '....wwwww....',
    '.....www.....',
    '....rrwrr....',
    '...rrrwrrr...',
    '....rrwrr....',
  ],
  ChristmasOrnamentKind.rudolph: [
    '.b...b...b...b.',
    '.bb.bb...bb.bb.',
    '..bbb.....bbb..',
    '...b.......b...',
    '..ttt.....ttt..',
    '...ttttttttt...',
    '..ttttttttttt..',
    '..ttdtttttdtt..',
    '...ttttttttt...',
    '....tttrttt....',
    '....ttrrrtt....',
    '.....ttttt.....',
    '......ttt......',
    '.....rgrgr.....',
    '.....ttttt.....',
    '......b.b......',
  ],
};

const _ink = {
  'c': 0,
  'i': 1,
  'r': 2,
  'w': 3,
  'o': 4,
  'd': 5,
  'b': 6,
  't': 7,
  'g': 8,
  'y': 9
};

final _sprites = {
  for (final entry in _motifs.entries) entry.key: _makeSprite(entry.value),
};

OrnamentSprite getChristmasOrnamentSprite(ChristmasOrnamentKind kind) =>
    _sprites[kind]!;

OrnamentSprite _makeSprite(List<String> rows) {
  final width = rows.map((row) => row.length).reduce((a, b) => a > b ? a : b);
  final dots = <OrnamentDot>[];
  for (var y = 0; y < rows.length; y++) {
    for (var x = 0; x < rows[y].length; x++) {
      final color = _ink[rows[y][x]];
      if (color == null) continue;
      dots.add(OrnamentDot(
          x: x - (width - 1) / 2, y: y - (rows.length - 1) / 2, color: color));
    }
  }
  return OrnamentSprite(
      width: width.toDouble(),
      height: rows.length.toDouble(),
      dots: List.unmodifiable(dots));
}
