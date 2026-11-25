import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'particle_character.dart';

const _characterColors = [
  Color(0xff99eedd),
  Color(0xffffaacc),
];

class BirthdayScene extends StatefulWidget {
  const BirthdayScene({super.key, required this.time});

  final ValueListenable<double> time;

  @override
  State<BirthdayScene> createState() => _BirthdaySceneState();
}

class _BirthdaySceneState extends State<BirthdayScene> {
  CharacterParticleCloud? _characters;
  bool _loadFailed = false;

  @override
  void initState() {
    super.initState();
    _loadCharacters();
  }

  Future<void> _loadCharacters() async {
    try {
      final bytes = await rootBundle.load('assets/birthday_characters.png');
      final cloud = await decodeCharacterParticleCloud(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      );
      if (mounted) setState(() => _characters = cloud);
    } catch (_) {
      if (mounted) setState(() => _loadFailed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: '청록색과 분홍색 생일 캐릭터가 작은 입자로 모입니다',
      child: RepaintBoundary(
        child: CustomPaint(
          painter: BirthdayCharacterPainter(
              time: widget.time, characters: _characters),
          child:
              _loadFailed ? const Center(child: Text('캐릭터를 불러올 수 없습니다')) : null,
        ),
      ),
    );
  }
}

class BirthdayCharacterPainter extends CustomPainter {
  BirthdayCharacterPainter({required this.time, required this.characters})
      : super(repaint: time);

  final ValueListenable<double> time;
  final CharacterParticleCloud? characters;
  final _paints = [
    for (final color in _characterColors) Paint()..color = color,
  ];
  final _snowPaint = Paint()..color = const Color(0x73b9d6e5);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final seconds = time.value;
    _drawSnow(canvas, size, seconds);
    final cloud = characters;
    if (cloud == null || cloud.particles.isEmpty) return;

    final top = math.max(190.0, size.height * 0.26);
    final bottom = math.min(size.height * 0.79, size.height - 174);
    if (bottom <= top) return;
    final availableHeight = bottom - top;
    final maxWidth =
        math.max(0.0, math.min(size.width * 0.60, (size.width / 3 - 12) * 2));
    if (maxWidth == 0) return;
    final frames = List.generate(2, (side) {
      final source = cloud.sourceBounds[side];
      final aspect = source.isEmpty ? 1.0 : source.width / source.height;
      final height = math.min(maxWidth / aspect, availableHeight * 0.58);
      return Rect.fromCenter(
        center: Offset(
          size.width * (side == 0 ? 1 / 3 : 2 / 3),
          top + availableHeight * (side == 0 ? 0.34 : 0.68),
        ),
        width: height * aspect,
        height: height,
      );
    });
    final paths = List.generate(_paints.length, (_) => Path());
    for (var i = 0; i < cloud.particles.length; i++) {
      final point = cloud.particles[i];
      final frame = frames[point.side];
      final mix = _smooth((seconds - point.delay) / 2.3);
      final targetX = frame.left + point.x * frame.width;
      final targetY = frame.top + point.y * frame.height;
      final drift = math.sin(seconds * 1.4 + i * 2.4) * 2 * (1 - mix);
      final x = point.spreadX * size.width +
          (targetX - point.spreadX * size.width) * mix +
          drift;
      final y = point.spreadY * size.height +
          (targetY - point.spreadY * size.height) * mix -
          math.sin(mix * math.pi) * size.height * 0.12;
      final dotSize = point.size *
          math.min(1.18, frame.width / 200) *
          (0.85 + 0.15 * math.sin(seconds * 3 + i));
      final color = point.side;
      paths[color].addRect(Rect.fromCenter(
        center: Offset(x, y),
        width: dotSize * 1.9,
        height: dotSize * 0.8,
      ));
    }
    for (var color = 0; color < paths.length; color++) {
      canvas.drawPath(paths[color], _paints[color]);
    }
  }

  void _drawSnow(Canvas canvas, Size size, double seconds) {
    final path = Path();
    for (var i = 0; i < 160; i++) {
      final x = (i * 137.508 + math.sin(seconds * 0.3 + i) * 12) % size.width;
      final y = (i * 71.73 + seconds * (10 + i % 21)) % size.height;
      path.addOval(Rect.fromCircle(
        center: Offset(x, y),
        radius: 0.45 + i % 3 * 0.3,
      ));
    }
    canvas.drawPath(path, _snowPaint);
  }

  @override
  bool shouldRepaint(covariant BirthdayCharacterPainter oldDelegate) {
    return oldDelegate.time != time || oldDelegate.characters != characters;
  }
}

double _smooth(double value) {
  final x = value.clamp(0.0, 1.0);
  return x * x * (3 - 2 * x);
}
