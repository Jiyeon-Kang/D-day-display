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
  final painter = ParticleForestPainter(time: clock);
  final recorder = ui.PictureRecorder();
  painter.paint(ui.Canvas(recorder)..scale(_pixelRatio.toDouble()), _size);
  final picture = recorder.endRecording();
  final image = await picture.toImage(_pixelWidth, _pixelHeight);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final result = Uint8List.fromList(bytes!.buffer.asUint8List());
  image.dispose();
  picture.dispose();
  clock.dispose();
  return result;
}

int upperForestPixels(Uint8List rgba) {
  var count = 0;
  // Snow is translucent. Solid colored pixels above the ground belong to trees.
  final end = _pixelWidth * (_pixelHeight * 0.68).floor() * 4;
  for (var i = 0; i < end; i += 4) {
    final red = rgba[i];
    final green = rgba[i + 1];
    final blue = rgba[i + 2];
    if (rgba[i + 3] > 200 &&
        (green > red * 1.3 || (blue > red * 1.2 && blue > green * 1.1))) {
      count++;
    }
  }
  return count;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('particles form visible trees, disperse, and form again next cycle',
      () async {
    final scattered = await renderScene(0);
    final formed = await renderScene(4);
    final dispersed = await renderScene(10);
    final nextCycle = await renderScene(16);

    expect(upperForestPixels(scattered), 0);
    expect(upperForestPixels(formed), greaterThan(100));
    expect(upperForestPixels(dispersed), 0);
    expect(upperForestPixels(nextCycle), greaterThan(100));
  });

  test('recreating the scene preserves its seeded appearance', () async {
    final first = await renderScene(4);
    final replay = await renderScene(4);
    expect(listEquals(first, replay), isTrue);
  });
}
