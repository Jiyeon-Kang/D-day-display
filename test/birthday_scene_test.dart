import 'dart:io';
import 'dart:ui' as ui;

import 'package:d_day_display/birthday_scene.dart';
import 'package:d_day_display/particle_character.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

const _size = ui.Size(393, 852);
const _ratio = 3;
const _width = 393 * _ratio;
const _height = 852 * _ratio;

Future<Uint8List> _render(BirthdayCharacterPainter painter) async {
  final recorder = ui.PictureRecorder();
  painter.paint(ui.Canvas(recorder)..scale(_ratio.toDouble()), _size);
  final picture = recorder.endRecording();
  final image = await picture.toImage(_width, _height);
  try {
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    return Uint8List.fromList(bytes!.buffer.asUint8List());
  } finally {
    image.dispose();
    picture.dispose();
  }
}

({int mint, int pink, ui.Rect bounds}) _portraitPixels(Uint8List pixels) {
  var left = _width;
  var right = 0;
  var top = _height;
  var bottom = 0;
  var mint = 0;
  var pink = 0;
  for (var i = 0; i < pixels.length; i += 4) {
    if (pixels[i + 3] <= 200) continue;
    final red = pixels[i];
    final green = pixels[i + 1];
    final blue = pixels[i + 2];
    final isMint = green > blue && blue > red;
    final isPink = red > blue && blue > green;
    if (!isMint && !isPink) continue;
    if (isMint) mint++;
    if (isPink) pink++;
    final pixel = i ~/ 4;
    final x = pixel % _width;
    final y = pixel ~/ _width;
    if (x < left) left = x;
    if (x > right) right = x;
    if (y < top) top = y;
    if (y > bottom) bottom = y;
  }
  return (
    mint: mint,
    pink: pink,
    bounds: ui.Rect.fromLTRB(
      left / _ratio,
      top / _ratio,
      (right + 1) / _ratio,
      (bottom + 1) / _ratio,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late CharacterParticleCloud realCharacters;

  setUpAll(() async {
    realCharacters = await decodeCharacterParticleCloud(
      await File('assets/birthday_characters.png').readAsBytes(),
    );
  });

  test('the edited character asset produces two bounded ink samples', () {
    expect(realCharacters.sourceBounds, hasLength(2));
    for (var side = 0; side < 2; side++) {
      final count =
          realCharacters.particles.where((point) => point.side == side).length;
      expect(count, greaterThan(1500));
      expect(count, lessThanOrEqualTo(3200));
      expect(realCharacters.sourceBounds[side].isEmpty, isFalse);
    }
    for (final point in realCharacters.particles) {
      expect(point.x, inInclusiveRange(0, 1));
      expect(point.y, inInclusiveRange(0, 1));
      expect(point.delay, inInclusiveRange(0, 0.65));
    }
  });

  test('transparent pixels do not become a rectangular character backdrop', () {
    const width = 16;
    const height = 12;
    final pixels = Uint8List(width * height * 4);
    for (final x in [2, 3, 4, 11, 12, 13]) {
      for (var y = 3; y < 9; y++) {
        final offset = (y * width + x) * 4;
        pixels[offset + 3] = 255;
      }
    }
    final first = CharacterParticleCloud.fromRgba(pixels,
        width: width, height: height, maxParticlesPerCharacter: 16);
    final second = CharacterParticleCloud.fromRgba(pixels,
        width: width, height: height, maxParticlesPerCharacter: 16);
    expect(first.particles.where((point) => point.side == 0), hasLength(16));
    expect(first.particles.where((point) => point.side == 1), hasLength(16));
    expect(first.sourceBounds, [
      const ui.Rect.fromLTRB(2, 3, 5, 9),
      const ui.Rect.fromLTRB(11, 3, 14, 9)
    ]);
    expect(
      first.particles.map(
          (point) => (point.x, point.y, point.side, point.delay, point.size)),
      second.particles.map(
          (point) => (point.x, point.y, point.side, point.delay, point.size)),
    );
    final empty = CharacterParticleCloud.fromRgba(Uint8List(width * height * 4),
        width: width, height: height);
    expect(empty.particles, isEmpty);
  });

  test(
      'both exact-color portraits stay formed below the title and above controls',
      () async {
    final time = ValueNotifier(4.0);
    addTearDown(time.dispose);
    final painter =
        BirthdayCharacterPainter(time: time, characters: realCharacters);

    for (final seconds in [4.0, 12.0, 30.0, 120.0]) {
      time.value = seconds;
      final pixels = _portraitPixels(await _render(painter));
      expect(pixels.mint, greaterThan(500));
      expect(pixels.pink, greaterThan(500));
      expect(pixels.bounds.left, greaterThanOrEqualTo(11));
      expect(pixels.bounds.right, lessThanOrEqualTo(382));
      expect(pixels.bounds.top, greaterThanOrEqualTo(225));
      expect(pixels.bounds.bottom, lessThanOrEqualTo(665));
      expect(pixels.bounds.height, greaterThan(280));
    }
  });

  test('replay restores the lower cloud and reforms the same two portraits',
      () async {
    final time = ValueNotifier(0.0);
    addTearDown(time.dispose);
    final painter =
        BirthdayCharacterPainter(time: time, characters: realCharacters);
    final initial = await _render(painter);
    expect(_portraitPixels(initial).bounds.top, greaterThan(700));
    time.value = 4;
    final formed = _portraitPixels(await _render(painter));
    expect(formed.bounds.bottom, lessThan(665));
    time.value = 120;
    expect(_portraitPixels(await _render(painter)).mint, greaterThan(500));
    time.value = 0;
    expect(listEquals(initial, await _render(painter)), isTrue);
    time.value = 4;
    expect(_portraitPixels(await _render(painter)).pink, greaterThan(500));
  });

  test('detail colors separate cake, clothing, and faces from the base colors',
      () async {
    final time = ValueNotifier(4.0);
    addTearDown(time.dispose);
    final pixels = await _render(
        BirthdayCharacterPainter(time: time, characters: realCharacters));
    final colors = <int, int>{
      0x99eedd: 0,
      0xffaacc: 0,
      0xe8d8ee: 0,
      0xcec8f2: 0,
      0xcde58d: 0,
      0xa9cee9: 0,
      0xffdc92: 0,
    };
    for (var i = 0; i < pixels.length; i += 4) {
      if (pixels[i + 3] != 255) continue;
      final rgb = pixels[i] << 16 | pixels[i + 1] << 8 | pixels[i + 2];
      if (colors.containsKey(rgb)) colors[rgb] = colors[rgb]! + 1;
    }
    for (final entry in colors.entries) {
      expect(entry.value, greaterThan(20),
          reason: 'Expected visible ${entry.key.toRadixString(16)} details');
    }
  });
}
