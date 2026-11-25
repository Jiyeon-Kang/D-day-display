import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

/// A cropped contour sample of the two original character stickers.
/// Source pixels determine geometry; the painter supplies the main colors.
class CharacterParticleCloud {
  CharacterParticleCloud._(this.sourceBounds, this.particles);

  factory CharacterParticleCloud.fromRgba(
    Uint8List rgba, {
    required int width,
    required int height,
    int maxParticlesPerCharacter = 3200,
  }) {
    if (width < 2 || height < 1 || rgba.length < width * height * 4) {
      throw ArgumentError('A complete paired RGBA image is required.');
    }
    if (maxParticlesPerCharacter < 1) {
      throw ArgumentError.value(maxParticlesPerCharacter);
    }

    var seed = 73;
    double random() {
      seed = (seed * 1664525 + 1013904223) % 4294967296;
      return seed / 4294967296;
    }

    final alpha = Float64List(width * height);
    final luminance = Float64List(width * height);
    for (var pixel = 0; pixel < alpha.length; pixel++) {
      final offset = pixel * 4;
      final opacity = rgba[offset + 3] / 255;
      alpha[pixel] = opacity;
      luminance[pixel] = opacity < 0.01
          ? 1
          : ((rgba[offset] * 0.2126 +
                      rgba[offset + 1] * 0.7152 +
                      rgba[offset + 2] * 0.0722) /
                  (255 * opacity))
              .clamp(0.0, 1.0);
    }

    final bounds = <ui.Rect>[];
    final particles = <CharacterParticlePoint>[];
    for (var side = 0; side < 2; side++) {
      final firstX = side == 0 ? 0 : width ~/ 2;
      final endX = side == 0 ? width ~/ 2 : width;
      var minX = endX;
      var minY = height;
      var maxX = firstX;
      var maxY = 0;
      for (var y = 0; y < height; y++) {
        for (var x = firstX; x < endX; x++) {
          if (alpha[y * width + x] < 0.18) continue;
          minX = math.min(minX, x);
          minY = math.min(minY, y);
          maxX = math.max(maxX, x + 1);
          maxY = math.max(maxY, y + 1);
        }
      }
      if (minX >= maxX || minY >= maxY) {
        bounds.add(ui.Rect.zero);
        continue;
      }
      final crop = ui.Rect.fromLTRB(
        minX.toDouble(),
        minY.toDouble(),
        maxX.toDouble(),
        maxY.toDouble(),
      );
      bounds.add(crop);

      final cellSize =
          math.max(1, (math.min(crop.width, crop.height) / 130).round());
      final cellColumns = (crop.width / cellSize).ceil();
      final cells = <int, _InkCandidate>{};
      for (var y = minY; y < maxY; y++) {
        for (var x = minX; x < maxX; x++) {
          final pixel = y * width + x;
          final opacity = alpha[pixel];
          if (opacity < 0.18) continue;
          final light = luminance[pixel];
          var ridge = 0.0;
          for (final offset in const [
            (x: -2, y: 0),
            (x: 2, y: 0),
            (x: 0, y: -2),
            (x: 0, y: 2)
          ]) {
            final nx = x + offset.x;
            final ny = y + offset.y;
            if (nx < firstX || nx >= endX || ny < 0 || ny >= height) {
              continue;
            }
            final neighbor = ny * width + nx;
            ridge = math.max(ridge, luminance[neighbor] - light);
          }
          final darkness = ((0.64 - light) / 0.64).clamp(0.0, 1.0);
          final feature = darkness * (0.22 + ridge * 2.5) + ridge * ridge * 1.8;
          if (feature < 0.07) continue;
          // Keep the dark side of a contour. White sticker borders and broad
          // mid-tone hair fills otherwise consume the small face-line budget.
          final cell =
              ((y - minY) ~/ cellSize) * cellColumns + (x - minX) ~/ cellSize;
          final previous = cells[cell];
          if (previous != null && previous.strength >= feature) continue;
          cells[cell] = _InkCandidate(x, y, feature, 0);
        }
      }
      // A strong ink point per small cell spreads dots along thin eyes, mouths,
      // and hair strands instead of clustering them in thick dark outlines.
      final candidates = cells.values.map((point) {
        final weight = 0.05 + point.strength;
        final priority = -math.log(math.max(random(), 0.000000001)) / weight;
        return _InkCandidate(point.x, point.y, point.strength, priority);
      }).toList();
      candidates.sort((a, b) => a.priority.compareTo(b.priority));
      for (final candidate in candidates.take(maxParticlesPerCharacter)) {
        particles.add(CharacterParticlePoint(
          x: ((candidate.x + 0.5 - minX) / crop.width).clamp(0.0, 1.0),
          y: ((candidate.y + 0.5 - minY) / crop.height).clamp(0.0, 1.0),
          side: side,
          spreadX: 0.04 + random() * 0.92,
          spreadY: 0.86 + random() * 0.08,
          delay: random() * 0.65,
          size: 0.65 + random() * 0.55,
        ));
      }
    }
    return CharacterParticleCloud._(
      List.unmodifiable(bounds),
      List.unmodifiable(particles),
    );
  }

  final List<ui.Rect> sourceBounds;
  final List<CharacterParticlePoint> particles;
}

Future<CharacterParticleCloud> decodeCharacterParticleCloud(
  Uint8List encoded, {
  int targetWidth = 640,
  int maxParticlesPerCharacter = 3200,
}) async {
  final codec =
      await ui.instantiateImageCodec(encoded, targetWidth: targetWidth);
  try {
    final frame = await codec.getNextFrame();
    final image = frame.image;
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (bytes == null) {
        throw StateError('The character image could not be read.');
      }
      return CharacterParticleCloud.fromRgba(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        width: image.width,
        height: image.height,
        maxParticlesPerCharacter: maxParticlesPerCharacter,
      );
    } finally {
      image.dispose();
    }
  } finally {
    codec.dispose();
  }
}

class CharacterParticlePoint {
  const CharacterParticlePoint({
    required this.x,
    required this.y,
    required this.side,
    required this.spreadX,
    required this.spreadY,
    required this.delay,
    required this.size,
  });

  final double x;
  final double y;
  final int side;
  final double spreadX;
  final double spreadY;
  final double delay;
  final double size;
}

class _InkCandidate {
  const _InkCandidate(this.x, this.y, this.strength, this.priority);

  final int x;
  final int y;
  final double strength;
  final double priority;
}
