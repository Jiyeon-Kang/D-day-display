import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'tree_season.dart';

const _centerTreeColor = Color(0xff99eedd);
const _sideTreeColor = Color(0xffffaacc);

// Preserve the existing particle buckets and seeded arrangement.
const _colors = [
  _centerTreeColor,
  _centerTreeColor,
  _centerTreeColor,
  _sideTreeColor,
  _sideTreeColor,
  _sideTreeColor,
];
const _classicColors = [
  Color(0xff65ce95),
  Color(0xff49b981),
  Color(0xffe9686b),
  Color(0xff4fb982),
  Color(0xff3d9e70),
  Color(0xffdc5260),
];
const _trees = [
  (x: 0.0, z: 0.0, h: 1.0, r: 0.29),
  (x: -0.25, z: 0.24, h: 0.66, r: 0.16),
  (x: 0.25, z: 0.24, h: 0.72, r: 0.17),
];
const _particleCount = 2200;
const _snowCount = 160;
const _formationDuration = 2.3;

/// Draws the scene in batched color paths without rebuilding widgets per frame.
class ParticleForestPainter extends CustomPainter {
  ParticleForestPainter({
    required this.time,
    this.season = const TreeSeason(),
  })  : _particles = _makeParticles(),
        _paints = (season.useClassicColors ? _classicColors : _colors)
            .map((color) => Paint()..color = color)
            .toList(),
        super(repaint: time);

  final ValueListenable<double> time;
  final TreeSeason season;
  final List<_Particle> _particles;
  final List<Paint> _paints;
  final _starPaint = Paint()..color = const Color(0xfff4cf79);
  final _starGlow = Paint()
    ..color = const Color(0x55f4cf79)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
  final _snowPaint = Paint()..color = const Color(0x73b9d6e5);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final t = time.value;
    _drawSnow(canvas, size, t);

    final paths = List.generate(_colors.length, (_) => Path());
    // Reserve the same topper space throughout the decorating season, so
    // existing ornaments keep their positions when the date changes.
    final scale = math.min(size.width * 1.14, size.height * 0.56) *
        (season.ornamentCount > 0 ? 0.94 : 1);
    final baseY = size.height * 0.76;
    final angle = t * 0.27;
    final cos = math.cos(angle);
    final sin = math.sin(angle);

    for (var i = 0; i < _particles.length; i++) {
      final p = _particles[i];
      final mix = _smooth((t - p.delay) / _formationDuration);
      final drift = math.sin(t * 1.4 + i * 2.4) * 0.035 * (1 - mix);
      final x = p.sx + (p.x - p.sx) * mix + drift;
      final y = p.sy + (p.y - p.sy) * mix - math.sin(mix * math.pi) * 0.24;
      final z = p.sz + (p.z - p.sz) * mix;
      // Rotate around each trunk so the three silhouettes stay in front view.
      final localX = x - p.treeX;
      final localZ = z - p.treeZ;
      final rx = p.treeX + localX * cos - localZ * sin;
      final rz = p.treeZ + localX * sin + localZ * cos;
      final perspective = 6 / (6 + rz);
      final px = size.width / 2 + rx * scale * perspective;
      // Project from halfway up the tree instead of looking up from its base.
      final py = baseY + ((y + 0.5) * perspective - 0.5) * scale;
      final dotSize = p.size *
          1.18 *
          (season.useClassicColors ? 1.12 : 1) *
          perspective *
          (0.85 + 0.15 * math.sin(t * 3 + i));

      final color = season.useClassicColors
          ? (p.treeIndex == 0 ? 0 : 3) + (p.isRibbon ? 2 : p.color % 2)
          : p.color;
      paths[color].addRect(
        Rect.fromLTWH(px, py, dotSize * 1.9, dotSize * 0.8),
      );
    }

    for (var i = 0; i < paths.length; i++) {
      canvas.drawPath(paths[i], _paints[i]);
    }
    _drawDecorations(canvas, size, t, scale, baseY);
  }

  void _drawDecorations(
      Canvas canvas, Size size, double t, double scale, double baseY) {
    if (!season.showStar) return;
    final screenScale = math.min(1.2, scale / (393 * 1.14));
    final star = _starPath(size, t, scale, baseY, screenScale);
    canvas.drawPath(star, _starGlow);
    canvas.drawPath(star, _starPaint);
  }

  Path _starPath(
      Size size, double t, double scale, double baseY, double screenScale) {
    final radius = 12.0 * screenScale;
    final center = Offset(size.width / 2, baseY - scale - radius * 0.85);
    final vertices = List.generate(10, (i) {
      final angle = -math.pi / 2 + i * math.pi / 5;
      return Offset(math.cos(angle), math.sin(angle)) *
          radius *
          (i.isEven ? 1 : 0.44);
    });
    final points = <Offset>[];
    for (var edge = 0; edge < 10; edge++) {
      for (var dot = 0; dot < 6; dot++) {
        points.add(
            Offset.lerp(vertices[edge], vertices[(edge + 1) % 10], dot / 6)!);
      }
      if (edge.isEven) {
        for (var dot = 0; dot < 5; dot++) {
          points.add(vertices[edge] * (dot / 5));
        }
      }
    }
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final mix =
          _smooth((t - (i * 37 % 101) / 100 * 0.65) / _formationDuration);
      final start = Offset(size.width * (0.08 + i * 0.381966 % 0.84),
          size.height * (0.86 + i * 0.0237 % 0.08));
      final point = Offset.lerp(start, center + points[i], mix)! -
          Offset(0, math.sin(mix * math.pi) * size.height * 0.12);
      final pulse = 0.92 + math.sin(t * 2.5 + i * 0.7) * 0.08;
      path.addRect(Rect.fromCenter(
          center: point,
          width: 1.6 * screenScale * pulse,
          height: 1.0 * screenScale * pulse));
    }
    return path;
  }

  void _drawSnow(Canvas canvas, Size size, double t) {
    final snow = Path();
    for (var i = 0; i < _snowCount; i++) {
      final x = (i * 137.508 + math.sin(t * 0.3 + i) * 12) % size.width;
      final y = (i * 71.73 + t * (10 + i % 21)) % size.height;
      snow.addOval(
        Rect.fromCircle(center: Offset(x, y), radius: 0.45 + i % 3 * 0.3),
      );
    }
    canvas.drawPath(snow, _snowPaint);
  }

  @override
  bool shouldRepaint(covariant ParticleForestPainter oldDelegate) {
    return oldDelegate.time != time || oldDelegate.season != season;
  }
}

double _smooth(double value) {
  final x = value.clamp(0.0, 1.0);
  return x * x * (3 - 2 * x);
}

List<_Particle> _makeParticles() {
  // The same seeded generator keeps particle positions identical on all targets.
  var seed = 73;
  double random() {
    seed = (seed * 1664525 + 1013904223) % 4294967296;
    return seed / 4294967296;
  }

  return List.generate(_particleCount, (i) {
    final treeIndex = i < _particleCount * 0.5
        ? 0
        : i < _particleCount * 0.75
            ? 1
            : 2;
    final tree = _trees[treeIndex];
    final h = math.sqrt(random());
    final angle = random() * math.pi * 2;
    final radius =
        tree.r * h * (0.78 + 0.22 * math.cos(h * 38)) * (0.8 + 0.2 * random());

    return _Particle(
      treeIndex: treeIndex,
      isRibbon: math.sin(angle + h * 24) > 0.76,
      treeX: tree.x,
      treeZ: tree.z,
      x: tree.x + math.cos(angle) * radius,
      y: -tree.h + h * tree.h,
      z: tree.z + math.sin(angle) * radius,
      sx: (random() - 0.5) * 1.7,
      sy: 0.12 + random() * 0.3,
      sz: (random() - 0.5) * 1.2,
      delay: random() * 0.65,
      size: 0.55 + random() * 0.65,
      color: (treeIndex == 0 ? 0 : 3) + (random() * 3).floor(),
    );
  }, growable: false);
}

class _Particle {
  const _Particle({
    required this.treeIndex,
    required this.isRibbon,
    required this.treeX,
    required this.treeZ,
    required this.x,
    required this.y,
    required this.z,
    required this.sx,
    required this.sy,
    required this.sz,
    required this.delay,
    required this.size,
    required this.color,
  });

  final int treeIndex;
  final bool isRibbon;
  final double treeX;
  final double treeZ;
  final double x;
  final double y;
  final double z;
  final double sx;
  final double sy;
  final double sz;
  final double delay;
  final double size;
  final int color;
}
