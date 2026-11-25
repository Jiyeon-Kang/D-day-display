import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

/// A few quiet dot hearts in the open space around the birthday portraits.
/// The scene clock also controls formation, pause, and replay.
class BirthdayHeartsPainter extends CustomPainter {
  BirthdayHeartsPainter({required this.time}) : super(repaint: time);

  final ValueListenable<double> time;

  static const _hearts = [
    (x: 0.15, y: 0.24, radius: 14.0, color: 1),
    (x: 0.80, y: 0.25, radius: 17.0, color: 0),
    (x: 0.91, y: 0.38, radius: 13.0, color: 1),
    (x: 0.10, y: 0.67, radius: 16.0, color: 0),
    (x: 0.36, y: 0.77, radius: 15.0, color: 1),
  ];
  final _paints = [
    Paint()..color = const Color(0x8a99eedd),
    Paint()..color = const Color(0x99ffaacc),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final safeTop = math.max(192.0, size.height * 0.22);
    final safeBottom = size.height - 160;
    if (safeBottom - safeTop < 120 || size.width < 220) return;

    final seconds = time.value;
    final scale = math.min(1.2, size.width / 393);
    final paths = [Path(), Path()];
    for (var heart = 0; heart < _hearts.length; heart++) {
      final definition = _hearts[heart];
      final radius = definition.radius * scale;
      final center = Offset(
        (size.width * definition.x).clamp(radius + 4, size.width - radius - 4),
        (size.height * definition.y)
            .clamp(safeTop + radius, safeBottom - radius),
      );
      final pulse = 1 + math.sin(seconds * 1.1 + heart * 1.7) * 0.035;
      final floatY = math.sin(seconds * 0.55 + heart * 1.3) * 1.8 * scale;
      for (var dot = 0; dot < 56; dot++) {
        final phase = dot * math.pi * 2 / 56;
        final sine = math.sin(phase);
        final outline = Offset(
          sine * sine * sine,
          -(13 * math.cos(phase) -
                  5 * math.cos(2 * phase) -
                  2 * math.cos(3 * phase) -
                  math.cos(4 * phase)) /
              17,
        );
        final index = heart * 56 + dot;
        final delay = ((index * 43 + 17) % 101) / 100 * 0.65;
        final mix = _smooth((seconds - delay) / 2.3);
        final start = Offset(
          size.width * (0.05 + (index * 0.61803398875 % 0.90)),
          size.height * (0.86 + (index * 0.041421356 % 0.08)),
        );
        final target = center + outline * radius * pulse + Offset(0, floatY);
        final position = Offset.lerp(start, target, mix)! -
            Offset(0, math.sin(mix * math.pi) * size.height * 0.06);
        final dotSize = scale *
            (0.70 + (index % 4) * 0.08) *
            (0.85 + math.sin(seconds * 2.2 + index * 1.4) * 0.15);
        paths[definition.color].addRect(Rect.fromCenter(
          center: position,
          width: dotSize * 1.9,
          height: dotSize * 0.8,
        ));
      }
    }
    for (var color = 0; color < paths.length; color++) {
      canvas.drawPath(paths[color], _paints[color]);
    }
  }

  @override
  bool shouldRepaint(covariant BirthdayHeartsPainter oldDelegate) =>
      oldDelegate.time != time;
}

double _smooth(double value) {
  final clamped = value.clamp(0.0, 1.0);
  return clamped * clamped * (3 - 2 * clamped);
}
