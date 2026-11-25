import 'dart:ui' as ui;

import 'package:d_day_display/birthday_glyphs.dart';
import 'package:d_day_display/particle_countdown_text.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

const _size = ui.Size(345, 116);
const _ratio = 3;
const _width = 345 * _ratio;
const _height = 116 * _ratio;

Future<Uint8List> _render(ParticleCountdownTextPainter painter) async {
  final recorder = ui.PictureRecorder();
  painter.paint(ui.Canvas(recorder)..scale(_ratio.toDouble()), _size);
  final picture = recorder.endRecording();
  final image = await picture.toImage(_width, _height);
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final result = Uint8List.fromList(data!.buffer.asUint8List());
  image.dispose();
  picture.dispose();
  return result;
}

int _ink(Uint8List pixels, {double top = 0, double bottom = 116}) {
  var count = 0;
  final start = (top * _ratio).floor() * _width * 4;
  final end = (bottom * _ratio).ceil() * _width * 4;
  for (var i = start; i < end; i += 4) {
    if (pixels[i + 3] > 64) count++;
  }
  return count;
}

ui.Rect _bounds(Uint8List pixels) {
  var left = _width;
  var right = 0;
  var top = _height;
  var bottom = 0;
  for (var i = 0; i < pixels.length; i += 4) {
    if (pixels[i + 3] <= 10) continue;
    final position = i ~/ 4;
    final x = position % _width;
    final y = position ~/ _width;
    if (x < left) left = x;
    if (x > right) right = x;
    if (y < top) top = y;
    if (y > bottom) bottom = y;
  }
  return ui.Rect.fromLTRB(
    left / _ratio,
    top / _ratio,
    (right + 1) / _ratio,
    (bottom + 1) / _ratio,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the complete birthday greeting has distinct Japanese glyph masks', () {
    expect(birthdayMessage, '雫、誕生日おめでとう〜');
    expect(birthdayGlyphs.keys.toSet(), birthdayMessage.split('').toSet());
    expect(birthdayGlyphs.values.toSet().length, birthdayGlyphs.length);

    for (final entry in birthdayGlyphs.entries) {
      final rows = entry.value.split('/');
      expect(rows.length, 24, reason: entry.key);
      expect(rows.every((row) => row.length == 24), isTrue, reason: entry.key);
      expect(rows.join(), matches(RegExp(r'^[01]+$')), reason: entry.key);
      expect(rows.join().replaceAll('0', '').length, greaterThan(10),
          reason: entry.key);
    }
  });

  test('birthday greeting forms readable bounded Japanese particle lines',
      () async {
    final clock = ValueNotifier(4.0);
    addTearDown(clock.dispose);
    final painter = ParticleCountdownTextPainter(
      text: birthdayMessage,
      time: clock,
    );
    final pixels = await _render(painter);
    final bounds = _bounds(pixels);

    expect(painter.text, '雫、誕生日おめでとう〜');
    expect(_ink(pixels, bottom: 54), greaterThan(100));
    expect(_ink(pixels, top: 64), greaterThan(100));
    expect(_ink(pixels, top: 55, bottom: 62), 0);
    expect(bounds.left, greaterThanOrEqualTo(8));
    expect(bounds.right, lessThanOrEqualTo(_size.width - 8));
    expect(bounds.top, greaterThanOrEqualTo(6));
    expect(bounds.bottom, lessThanOrEqualTo(_size.height - 6));
    expect(bounds.width, greaterThan(250));
    expect(bounds.height, greaterThan(85));
  });

  test('birthday particles stay formed and reset only for replay', () async {
    final clock = ValueNotifier(0.0);
    addTearDown(clock.dispose);
    final painter = ParticleCountdownTextPainter(
      text: birthdayMessage,
      time: clock,
    );
    final initial = await _render(painter);
    expect(_ink(initial, bottom: 81), 0);

    for (final time in [4.0, 14.0, 120.0]) {
      clock.value = time;
      final formed = await _render(painter);
      expect(_ink(formed, bottom: 81), greaterThan(100));
      expect(_bounds(formed).bottom, lessThanOrEqualTo(110));
    }

    clock.value = 0;
    expect(listEquals(initial, await _render(painter)), isTrue);
  });
}
