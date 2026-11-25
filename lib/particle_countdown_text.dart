import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

const _mint = Color(0xff99eedd);
const _pink = Color(0xffffaacc);
const _formationDuration = 2.3;
const _characterSpacing = 2.0;
const _lineHeight = 12.0;

// Lowercase letters retain their x-height, ascenders, and the y descender.
// Each lit cell is a cluster of tiny particles, rather than a font glyph.
const _glyphs = <String, String>{
  '0': '01110/10001/10011/10101/11001/10001/01110',
  '1': '010/110/010/010/010/010/111',
  '2': '01110/10001/00001/00010/00100/01000/11111',
  '3': '11110/00001/00001/01110/00001/00001/11110',
  '4': '00010/00110/01010/10010/11111/00010/00010',
  '5': '11111/10000/10000/11110/00001/00001/11110',
  '6': '01110/10000/10000/11110/10001/10001/01110',
  '7': '11111/00001/00010/00100/01000/01000/01000',
  '8': '01110/10001/10001/01110/10001/10001/01110',
  '9': '01110/10001/10001/01111/00001/00001/01110',
  'D': '11110/10001/10001/10001/10001/10001/11110',
  'A': '01110/10001/10001/11111/10001/10001/10001',
  'Y': '10001/10001/01010/00100/00100/00100/00100',
  '-': '000/000/000/111/000/000/000',
  '!': '1/1/1/1/1/0/1',
  ' ': '000/000/000/000/000/000/000',
  '?': '01110/10001/00001/00010/00100/00000/00100',
  'm': '00000/00000/11010/10101/10101/10101/10101/00000/00000',
  'e': '00000/00000/01110/10001/11111/10000/01111/00000/00000',
  'r': '0000/0000/1011/1100/1000/1000/1000/0000/0000',
  'y': '00000/00000/10001/10001/10001/01111/00001/00001/01110',
  'c': '00000/00000/01111/10000/10000/10000/01111/00000/00000',
  'h': '10000/10000/10110/11001/10001/10001/10001/00000/00000',
  'i': '1/0/1/1/1/1/1/0/0',
  's': '00000/00000/01111/10000/01110/00001/11110/00000/00000',
  't': '010/010/111/010/010/010/001/000/000',
  'a': '00000/00000/01110/00001/01111/10001/01111/00000/00000',
};

/// Forms countdown lettering from the same small dashes used by the forest.
///
/// The owner supplies elapsed seconds and resets [time] only for replay or a
/// changed date. Once formed, positions stay fixed and only sizes twinkle.
class ParticleCountdownTextPainter extends CustomPainter {
  ParticleCountdownTextPainter({required this.text, required this.time})
      : _layout = _makeLayout(text),
        super(repaint: time);

  final String text;
  final ValueListenable<double> time;
  final _ParticleLettering _layout;
  final _paints = [Paint()..color = _mint, Paint()..color = _pink];

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || _layout.particles.isEmpty) return;

    final horizontalPadding = math.min(12.0, size.width * 0.05);
    final verticalPadding = math.min(8.0, size.height * 0.08);
    final cellPitch = math.min(
      11.5,
      math.min(
        (size.width - horizontalPadding * 2) / _layout.width,
        (size.height - verticalPadding * 2) / _layout.height,
      ),
    );
    if (cellPitch <= 0) return;

    final left = (size.width - _layout.width * cellPitch) / 2;
    final top = (size.height - _layout.height * cellPitch) / 2;
    final particleScale = math.min(1.0, cellPitch / 7);
    final paths = [Path(), Path()];
    final seconds = time.value;

    for (var i = 0; i < _layout.particles.length; i++) {
      final particle = _layout.particles[i];
      final mix = _smooth((seconds - particle.delay) / _formationDuration);
      final targetX = left + particle.x * cellPitch;
      final targetY = top + particle.y * cellPitch;
      final spreadX = particle.sx * size.width;
      final spreadY = particle.sy * size.height;
      final drift =
          math.sin(seconds * 1.4 + i * 2.4) * size.height * 0.012 * (1 - mix);
      final x = spreadX + (targetX - spreadX) * mix + drift;
      final y = spreadY +
          (targetY - spreadY) * mix -
          math.sin(mix * math.pi) * size.height * 0.12;
      final dotSize = particle.size *
          particleScale *
          (0.85 + 0.15 * math.sin(seconds * 3 + i));

      paths[particle.color].addRect(
        Rect.fromCenter(
          center: Offset(x, y),
          width: dotSize * 1.9,
          height: dotSize * 0.8,
        ),
      );
    }

    for (var i = 0; i < paths.length; i++) {
      canvas.drawPath(paths[i], _paints[i]);
    }
  }

  @override
  bool shouldRepaint(covariant ParticleCountdownTextPainter oldDelegate) {
    return oldDelegate.text != text || oldDelegate.time != time;
  }
}

double _smooth(double value) {
  final clamped = value.clamp(0.0, 1.0);
  return clamped * clamped * (3 - 2 * clamped);
}

_ParticleLettering _makeLayout(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return const _ParticleLettering(0, 0, []);
  final lines = trimmed.toLowerCase() == 'merry christmas!'
      ? ['merry', 'christmas!']
      : trimmed.split('\n');
  final lineWidths = lines.map((line) {
    var width = 0.0;
    for (final character in line.split('')) {
      width += _rows(character).first.length + _characterSpacing;
    }
    return math.max(0.0, width - _characterSpacing);
  }).toList(growable: false);
  final widest = lineWidths.reduce(math.max);
  final cells = <({double x, double y})>[];

  for (var line = 0; line < lines.length; line++) {
    var cursor = (widest - lineWidths[line]) / 2;
    for (final character in lines[line].split('')) {
      final rows = _rows(character);
      for (var row = 0; row < rows.length; row++) {
        for (var column = 0; column < rows[row].length; column++) {
          if (rows[row][column] == '1') {
            cells.add((x: cursor + column, y: line * _lineHeight + row));
          }
        }
      }
      cursor += rows.first.length + _characterSpacing;
    }
  }
  if (cells.isEmpty) return const _ParticleLettering(0, 0, []);

  var minX = double.infinity;
  var minY = double.infinity;
  var maxX = double.negativeInfinity;
  var maxY = double.negativeInfinity;
  for (final cell in cells) {
    minX = math.min(minX, cell.x);
    minY = math.min(minY, cell.y);
    maxX = math.max(maxX, cell.x);
    maxY = math.max(maxY, cell.y);
  }

  var seed = 73;
  for (final code in text.codeUnits) {
    seed = (seed * 31 + code) % 4294967296;
  }
  double random() {
    seed = (seed * 1664525 + 1013904223) % 4294967296;
    return seed / 4294967296;
  }

  final particles = <_LetterParticle>[];
  for (final cell in cells) {
    for (var row = -1; row <= 1; row++) {
      for (var column = -1; column <= 1; column++) {
        particles.add(
          _LetterParticle(
            x: cell.x - minX + 0.5 + column * 0.27 + (random() - 0.5) * 0.06,
            y: cell.y - minY + 0.5 + row * 0.27 + (random() - 0.5) * 0.06,
            sx: 0.04 + random() * 0.92,
            sy: 0.82 + random() * 0.12,
            delay: random() * 0.65,
            size: 0.65 + random() * 0.55,
            color: random() < 0.18 ? 1 : 0,
          ),
        );
      }
    }
  }

  return _ParticleLettering(
    maxX - minX + 1,
    maxY - minY + 1,
    particles,
  );
}

List<String> _rows(String character) {
  return (_glyphs[character] ?? _glyphs['?']!).split('/');
}

class _ParticleLettering {
  const _ParticleLettering(this.width, this.height, this.particles);

  final double width;
  final double height;
  final List<_LetterParticle> particles;
}

class _LetterParticle {
  const _LetterParticle({
    required this.x,
    required this.y,
    required this.sx,
    required this.sy,
    required this.delay,
    required this.size,
    required this.color,
  });

  final double x;
  final double y;
  final double sx;
  final double sy;
  final double delay;
  final double size;
  final int color;
}
