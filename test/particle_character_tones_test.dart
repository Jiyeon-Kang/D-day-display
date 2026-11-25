import 'dart:io';
import 'dart:typed_data';

import 'package:d_day_display/particle_character.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('nearby source fills distinguish ink details from the main hair color',
      () {
    const width = 200;
    const height = 120;
    final rgba = Uint8List(width * height * 4);
    for (var offset = 0; offset < rgba.length; offset += 4) {
      rgba[offset] = 255;
      rgba[offset + 1] = 255;
      rgba[offset + 2] = 255;
      rgba[offset + 3] = 255;
    }
    void patch(int side, int left, int top, int right, int bottom,
        (int, int, int) color) {
      for (var y = top; y < bottom; y++) {
        for (var x = left; x < right; x++) {
          final offset = (y * width + side * 100 + x) * 4;
          final border =
              x == left || x == right - 1 || y == top || y == bottom - 1;
          rgba[offset] = border ? 20 : color.$1;
          rgba[offset + 1] = border ? 20 : color.$2;
          rgba[offset + 2] = border ? 20 : color.$3;
        }
      }
    }

    for (var side = 0; side < 2; side++) {
      patch(
          side, 20, 15, 75, 35, side == 0 ? (100, 170, 210) : (220, 100, 150));
      patch(side, 44, 50, 62, 70, (250, 215, 193));
      patch(side, side == 0 ? 55 : 28, 78, side == 0 ? 69 : 42, 97,
          (140, 180, 70));
      patch(side, side == 0 ? 49 : 24, 101, side == 0 ? 73 : 49, 106,
          (220, 230, 235));
      patch(side, 44, 111, 55, 119, (220, 218, 235));
      patch(side, 78, 15, 88, 23, (240, 190, 70));
    }
    // Warm pink highlights can have low blue values, but are never gold bows.
    patch(1, 30, 18, 40, 30, (250, 145, 165));
    patch(1, 50, 18, 60, 30, (215, 120, 142));
    final first = CharacterParticleCloud.fromRgba(
      rgba,
      width: width,
      height: height,
    );
    final second = CharacterParticleCloud.fromRgba(
      rgba,
      width: width,
      height: height,
    );

    for (var side = 0; side < 2; side++) {
      final points = first.particles.where((point) => point.side == side);
      for (final tone in CharacterParticleTone.values) {
        expect(points.where((point) => point.tone == tone), isNotEmpty,
            reason: 'side $side must retain $tone from its source patch');
      }
      final hair = points.where((point) =>
          point.x > 0.2 && point.x < 0.75 && point.y > 0.12 && point.y < 0.3);
      expect(hair, isNotEmpty);
      expect(hair.every((point) => point.tone == CharacterParticleTone.base),
          isTrue);
    }
    expect(
      first.particles.map((point) =>
          (point.x, point.y, point.side, point.delay, point.size, point.tone)),
      second.particles.map((point) =>
          (point.x, point.y, point.side, point.delay, point.size, point.tone)),
    );
  });

  test('real character details retain a dominant base and visible cake/clothes',
      () async {
    final cloud = await decodeCharacterParticleCloud(
      await File('assets/birthday_characters.png').readAsBytes(),
    );
    for (var side = 0; side < 2; side++) {
      final points =
          cloud.particles.where((point) => point.side == side).toList();
      final counts = {
        for (final tone in CharacterParticleTone.values)
          tone: points.where((point) => point.tone == tone).length,
      };
      expect(points, hasLength(3200));
      expect(counts[CharacterParticleTone.base],
          greaterThanOrEqualTo(points.length * 0.4),
          reason: 'the original mint/pink must remain dominant: $counts');
      for (final tone in [
        CharacterParticleTone.skin,
        CharacterParticleTone.outfit,
        CharacterParticleTone.cake,
        CharacterParticleTone.plate,
      ]) {
        expect(counts[tone], greaterThan(20), reason: 'side $side: $counts');
      }
    }
  });
}
