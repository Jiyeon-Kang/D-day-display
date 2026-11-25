import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

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
const _particleCount = 2200;
const _snowCount = 160;
const _formationDuration = 2.3;

/// Draws the whole scene with seven paths, without rebuilding widgets per frame.
class ParticleForestPainter extends CustomPainter {
  ParticleForestPainter({required this.time})
      : _particles = _makeParticles(),
        super(repaint: time);

  final ValueListenable<double> time;
  final List<_Particle> _particles;
  final _paints = _colors.map((color) => Paint()..color = color).toList();
  final _snowPaint = Paint()..color = const Color(0x73b9d6e5);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final t = time.value;
    _drawSnow(canvas, size, t);

    final paths = List.generate(_colors.length, (_) => Path());
    final scale = math.min(size.width * 0.84, size.height * 0.59);
    final baseY = size.height * 0.73;
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
      final rx = x * cos - z * sin;
      final rz = x * sin + z * cos;
      final perspective = 2.8 / (2.8 + rz);
      final px = size.width / 2 + rx * scale * perspective;
      final py = baseY + (y + rz * 0.12) * scale * perspective;
      final dotSize =
          p.size * perspective * (0.85 + 0.15 * math.sin(t * 3 + i));

      paths[p.color].addRect(
        Rect.fromLTWH(px, py, dotSize * 1.9, dotSize * 0.8),
      );
    }

    for (var i = 0; i < paths.length; i++) {
      canvas.drawPath(paths[i], _paints[i]);
    }
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
    return oldDelegate.time != time;
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

  const trees = [
    (x: 0.0, z: 0.0, h: 1.0, r: 0.29),
    (x: -0.29, z: 0.18, h: 0.66, r: 0.21),
    (x: 0.31, z: 0.2, h: 0.72, r: 0.22),
  ];

  return List.generate(_particleCount, (i) {
    final treeIndex = i < _particleCount * 0.5
        ? 0
        : i < _particleCount * 0.75
            ? 1
            : 2;
    final tree = trees[treeIndex];
    final h = math.sqrt(random());
    final angle = random() * math.pi * 2;
    final radius =
        tree.r * h * (0.78 + 0.22 * math.cos(h * 38)) * (0.8 + 0.2 * random());

    return _Particle(
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
