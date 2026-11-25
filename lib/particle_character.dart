import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

/// Small detail groups retain the source drawing's boundaries while the painter
/// supplies a restrained palette around the two main character colors.
enum CharacterParticleTone { base, skin, outfit, cake, plate, ornament }

/// A cropped contour sample of the two original character stickers.
/// Source pixels determine geometry and detail groups, never final paint colors.
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
          tone: _detailTone(
            rgba,
            alpha,
            luminance,
            width: width,
            height: height,
            side: side,
            crop: crop,
            x: candidate.x,
            y: candidate.y,
          ),
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
    this.tone = CharacterParticleTone.base,
  });

  final double x;
  final double y;
  final int side;
  final double spreadX;
  final double spreadY;
  final double delay;
  final double size;
  final CharacterParticleTone tone;
}

CharacterParticleTone _detailTone(
  Uint8List rgba,
  Float64List alpha,
  Float64List luminance, {
  required int width,
  required int height,
  required int side,
  required ui.Rect crop,
  required int x,
  required int y,
}) {
  final u = (x + 0.5 - crop.left) / crop.width;
  final v = (y + 0.5 - crop.top) / crop.height;
  bool inside(double left, double top, double right, double bottom) =>
      u >= left && u <= right && v >= top && v <= bottom;

  final inCake = side == 0
      ? inside(0.52, 0.63, 0.71, 0.84)
      : inside(0.26, 0.62, 0.45, 0.84);
  final inPlate = side == 0
      ? inside(0.48, 0.75, 0.75, 0.89)
      : inside(0.22, 0.77, 0.51, 0.88);
  final inOutfit =
      side == 0 ? inside(0.36, 0.71, 0.65, 1) : inside(0.41, 0.74, 0.59, 1);
  final inSkin = side == 0
      ? inside(0.27, 0.28, 0.74, 0.74) || inside(0.35, 0.64, 0.64, 0.92)
      : inside(0.25, 0.35, 0.73, 0.78) || inside(0.34, 0.79, 0.59, 0.98);
  final inOrnament = v < 0.4 || u < 0.16 || u > 0.84;
  if (!inCake && !inPlate && !inOutfit && !inSkin && !inOrnament) {
    return CharacterParticleTone.base;
  }

  var green = 0.0;
  var gold = 0.0;
  var neutral = 0.0;
  var skin = 0.0;
  var total = 0.0;
  final radius = math.max(2, (crop.width / 75).round());
  for (var dy = -radius; dy <= radius; dy++) {
    for (var dx = -radius; dx <= radius; dx++) {
      final nx = x + dx;
      final ny = y + dy;
      if (nx < crop.left || nx >= crop.right || ny < 0 || ny >= height) {
        continue;
      }
      final pixel = ny * width + nx;
      final opacity = alpha[pixel];
      if (opacity < 0.65 || luminance[pixel] < 0.28) continue;
      final offset = pixel * 4;
      final r = (rgba[offset] / (255 * opacity)).clamp(0.0, 1.0);
      final g = (rgba[offset + 1] / (255 * opacity)).clamp(0.0, 1.0);
      final b = (rgba[offset + 2] / (255 * opacity)).clamp(0.0, 1.0);
      final high = math.max(r, math.max(g, b));
      final low = math.min(r, math.min(g, b));
      final weight = 1 / (1 + (dx * dx + dy * dy) * 0.35);
      total += weight;
      if (g > b * 1.25 && r > b * 1.15 && g > r * 0.72) {
        green += weight;
      }
      if (r > 0.58 &&
          g > 0.36 &&
          b < r * 0.68 &&
          g > r * 0.52 &&
          g > b * 1.25) {
        gold += weight;
      }
      if (high - low < 0.2 && luminance[pixel] > 0.55) {
        neutral += weight;
      }
      if (r > 0.7 &&
          g > 0.5 &&
          b > 0.45 &&
          r > g * 1.035 &&
          g > b * 1.025 &&
          high - low < 0.3) {
        skin += weight;
      }
    }
  }
  if (total == 0) return CharacterParticleTone.base;
  // Dark contour pixels inherit a nearby fill, not their own near-black ink.
  // Position gates keep cake greens and dress whites away from hair highlights.
  if (inCake && (green + gold) / total > 0.12) {
    return CharacterParticleTone.cake;
  }
  if (inPlate && neutral / total > 0.18 && skin / total < 0.15) {
    return CharacterParticleTone.plate;
  }
  if (inSkin && skin / total > 0.16) return CharacterParticleTone.skin;
  if (inOutfit && neutral / total > 0.2) return CharacterParticleTone.outfit;
  if (inOrnament && gold / total > 0.22) {
    return CharacterParticleTone.ornament;
  }
  return CharacterParticleTone.base;
}

class _InkCandidate {
  const _InkCandidate(this.x, this.y, this.strength, this.priority);

  final int x;
  final int y;
  final double strength;
  final double priority;
}
