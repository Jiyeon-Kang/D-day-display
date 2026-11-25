import 'dart:ui' as ui;

import 'package:d_day_display/particle_forest.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

const _size = ui.Size(390, 844);
const _pixelRatio = 2;
const _pixelWidth = 390 * _pixelRatio;
const _pixelHeight = 844 * _pixelRatio;

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
}
