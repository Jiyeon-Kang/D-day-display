import 'dart:ui' as ui;

import 'package:d_day_display/particle_forest.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

const _size = ui.Size(393, 852);
const _pixelRatio = 3;
const _pixelWidth = 393 * _pixelRatio;
const _pixelHeight = 852 * _pixelRatio;

Future<Uint8List> renderScene(double seconds) async {
  final clock = ValueNotifier(seconds);
  try {
    return await renderPainter(ParticleForestPainter(time: clock));
  } finally {
    clock.dispose();
  }
}

Future<Uint8List> renderPainter(ParticleForestPainter painter) async {
  final recorder = ui.PictureRecorder();
  painter.paint(ui.Canvas(recorder)..scale(_pixelRatio.toDouble()), _size);
  final picture = recorder.endRecording();
  final image = await picture.toImage(_pixelWidth, _pixelHeight);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final result = Uint8List.fromList(bytes!.buffer.asUint8List());
  image.dispose();
  picture.dispose();
  return result;
}

int upperForestPixels(Uint8List rgba) {
  var count = 0;
  // Snow is translucent. Solid colored pixels above the ground belong to trees.
  final end = _pixelWidth * (_pixelHeight * 0.68).floor() * 4;
  for (var i = 0; i < end; i += 4) {
    if (rgba[i + 3] > 200) {
      count++;
    }
  }
  return count;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('trees stay formed until the same animation clock is replayed',
      () async {
    final clock = ValueNotifier(0.0);
    addTearDown(clock.dispose);
    final painter = ParticleForestPainter(time: clock);

    final scattered = await renderPainter(painter);
    expect(upperForestPixels(scattered), 0);

    for (final seconds in [4.0, 10.0, 12.0, 30.0, 120.0]) {
      clock.value = seconds;
      final formed = await renderPainter(painter);
      expect(
        upperForestPixels(formed),
        greaterThan(100),
        reason: 'The formed trees must remain visible at $seconds seconds.',
      );
    }

    clock.value = 0;
    final replayed = await renderPainter(painter);
    expect(upperForestPixels(replayed), 0);
    expect(listEquals(scattered, replayed), isTrue);

    clock.value = 4;
    final reformed = await renderPainter(painter);
    expect(upperForestPixels(reformed), greaterThan(100));
  });

  test('recreating the scene preserves its seeded appearance', () async {
    final first = await renderScene(4);
    final replay = await renderScene(4);
    expect(listEquals(first, replay), isTrue);
  });

  test('front-facing trees fit iPhone 15 and stay clear of playback controls',
      () async {
    const horizontalMargin = 12.0;
    const controlsTop = 852.0 - 52 - 48;

    for (final seconds in [4.0, 6.0, 12.0, 18.0, 24.0, 30.0, 120.0]) {
      final pixels = await renderScene(seconds);
      var left = _pixelWidth;
      var top = _pixelHeight;
      var right = 0;
      var bottom = 0;
      var mintPixels = 0;
      var leftPinkPixels = 0;
      var rightPinkPixels = 0;

      for (var i = 0; i < pixels.length; i += 4) {
        if (pixels[i + 3] <= 200) continue;
        final red = pixels[i];
        final green = pixels[i + 1];
        final blue = pixels[i + 2];
        final mint = green > blue && blue > red;
        final pink = red > blue && blue > green;
        if (!mint && !pink) continue;

        final pixel = i ~/ 4;
        final x = pixel % _pixelWidth;
        final y = pixel ~/ _pixelWidth;
        if (x < left) left = x;
        if (x > right) right = x;
        if (y < top) top = y;
        if (y > bottom) bottom = y;
        if (mint) mintPixels++;
        if (pink && x < _pixelWidth / 2) leftPinkPixels++;
        if (pink && x >= _pixelWidth / 2) rightPinkPixels++;
      }

      final bounds = ui.Rect.fromLTRB(
        left / _pixelRatio,
        top / _pixelRatio,
        (right + 1) / _pixelRatio,
        (bottom + 1) / _pixelRatio,
      );
      final reason = 'All three trees must remain framed at $seconds seconds.';
      expect(mintPixels, greaterThan(100), reason: reason);
      expect(leftPinkPixels, greaterThan(100), reason: reason);
      expect(rightPinkPixels, greaterThan(100), reason: reason);
      expect(bounds.left, greaterThanOrEqualTo(horizontalMargin),
          reason: reason);
      expect(bounds.right, lessThanOrEqualTo(393 - horizontalMargin),
          reason: reason);
      expect(bounds.top, greaterThanOrEqualTo(80), reason: reason);
      expect(bounds.bottom, lessThanOrEqualTo(controlsTop - 32),
          reason: reason);
      expect(bounds.height, greaterThan(_size.height * 0.45), reason: reason);
    }
  });
}
