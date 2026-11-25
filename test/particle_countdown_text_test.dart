import 'dart:ui' as ui;

import 'package:d_day_display/particle_countdown_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

const _size = ui.Size(345, 116);
const _pixelRatio = 3;
const _pixelWidth = 345 * _pixelRatio;
const _pixelHeight = 116 * _pixelRatio;

Future<Uint8List> _render(ParticleCountdownTextPainter painter) async {
  final recorder = ui.PictureRecorder();
  painter.paint(ui.Canvas(recorder)..scale(_pixelRatio.toDouble()), _size);
  final picture = recorder.endRecording();
  final image = await picture.toImage(_pixelWidth, _pixelHeight);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final pixels = Uint8List.fromList(bytes!.buffer.asUint8List());
  image.dispose();
  picture.dispose();
  return pixels;
}

int _ink(Uint8List pixels, {double top = 0, double bottom = 116}) {
  var count = 0;
  final start = (top * _pixelRatio).floor() * _pixelWidth * 4;
  final end = (bottom * _pixelRatio).ceil() * _pixelWidth * 4;
  for (var i = start; i < end; i += 4) {
    if (pixels[i + 3] > 100) count++;
  }
  return count;
}

ui.Rect _bounds(Uint8List pixels) {
  var left = _pixelWidth;
  var right = 0;
  var top = _pixelHeight;
  var bottom = 0;
  for (var i = 0; i < pixels.length; i += 4) {
    if (pixels[i + 3] <= 10) continue;
    final pixel = i ~/ 4;
    final x = pixel % _pixelWidth;
    final y = pixel ~/ _pixelWidth;
    if (x < left) left = x;
    if (x > right) right = x;
    if (y < top) top = y;
    if (y > bottom) bottom = y;
  }
  return ui.Rect.fromLTRB(
    left / _pixelRatio,
    top / _pixelRatio,
    (right + 1) / _pixelRatio,
    (bottom + 1) / _pixelRatio,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('empty seasonal text paints no particles', () async {
    final clock = ValueNotifier(4.0);
    addTearDown(clock.dispose);
    for (final text in ['', '   ']) {
      final pixels = await _render(
        ParticleCountdownTextPainter(text: text, time: clock),
      );
      expect(_ink(pixels), 0);
    }
  });

  test('countdown gathers, stays formed, and only resets on replay', () async {
    final clock = ValueNotifier(0.0);
    addTearDown(clock.dispose);
    final painter = ParticleCountdownTextPainter(text: 'D-15', time: clock);
    final scattered = await _render(painter);
    expect(_ink(scattered), greaterThan(100));
    expect(_ink(scattered, bottom: 81), 0);

    for (final seconds in [4.0, 14.0, 120.0]) {
      clock.value = seconds;
      final formed = await _render(painter);
      final bounds = _bounds(formed);
      expect(_ink(formed, bottom: 81), greaterThan(100));
      expect(bounds.width, inInclusiveRange(230, 280));
      expect(bounds.height, inInclusiveRange(70, 85));
      expect(bounds.left, greaterThanOrEqualTo(8));
      expect(bounds.right, lessThanOrEqualTo(_size.width - 8));
      expect(bounds.top, greaterThanOrEqualTo(6));
      expect(bounds.bottom, lessThanOrEqualTo(_size.height - 6));
    }

    clock.value = 0;
    final replayed = await _render(painter);
    expect(listEquals(scattered, replayed), isTrue);
  });

  test('the next countdown day has a distinct particle glyph layout', () async {
    final clock = ValueNotifier(4.0);
    addTearDown(clock.dispose);
    final fifteen = ParticleCountdownTextPainter(text: 'D-15', time: clock);
    final fourteen = ParticleCountdownTextPainter(text: 'D-14', time: clock);

    expect(fifteen.text, 'D-15');
    expect(fourteen.text, 'D-14');
    expect(
        listEquals(await _render(fifteen), await _render(fourteen)), isFalse);
    expect(fourteen.shouldRepaint(fifteen), isTrue);
  });

  test('lowercase Christmas greeting is drawn in two bounded particle lines',
      () async {
    final clock = ValueNotifier(4.0);
    addTearDown(clock.dispose);
    final painter = ParticleCountdownTextPainter(
      text: 'merry christmas!',
      time: clock,
    );
    final pixels = await _render(painter);
    final bounds = _bounds(pixels);

    expect(painter.text, 'merry christmas!');
    expect(_ink(pixels, bottom: 53), greaterThan(100));
    expect(_ink(pixels, top: 64), greaterThan(100));
    expect(_ink(pixels, top: 54, bottom: 63), 0);
    expect(bounds.left, greaterThanOrEqualTo(8));
    expect(bounds.right, lessThanOrEqualTo(_size.width - 8));
    expect(bounds.top, greaterThanOrEqualTo(6));
    expect(bounds.bottom, lessThanOrEqualTo(_size.height - 6));
  });
}
