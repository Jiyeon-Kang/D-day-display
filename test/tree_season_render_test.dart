import 'dart:ui' as ui;

import 'package:d_day_display/particle_forest.dart';
import 'package:d_day_display/christmas_ornament.dart';
import 'package:d_day_display/tree_season.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

const _size = ui.Size(393, 852);
const _ratio = 3;
const _width = 393 * _ratio;
const _height = 852 * _ratio;

Future<Uint8List> _render(ParticleForestPainter painter) async {
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

int _count(Uint8List pixels, bool Function(int r, int g, int b) matches,
    {double top = 0, double bottom = 852}) {
  var count = 0;
  final start = (top * _ratio).floor() * _width * 4;
  final end = (bottom * _ratio).ceil() * _width * 4;
  for (var i = start; i < end; i += 4) {
    if (pixels[i + 3] < 245) continue;
    if (matches(pixels[i], pixels[i + 1], pixels[i + 2])) count++;
  }
  return count;
}

bool _isGold(int r, int g, int b) => r > 225 && g > 180 && b < 155;
bool _isGreen(int r, int g, int b) => g > r * 1.2 && g > b * 1.15;
bool _isRed(int r, int g, int b) => r > g * 1.4 && r > b * 1.3;

bool _isMotif(int r, int g, int b) => christmasOrnamentColors
    .take(9)
    .any((color) => color.red == r && color.green == g && color.blue == b);

ui.Rect _starBounds(Uint8List pixels) {
  var left = _width;
  var top = _height;
  var right = 0;
  var bottom = 0;
  for (var y = 0; y < 280 * _ratio; y++) {
    for (var x = 0; x < _width; x++) {
      final i = (y * _width + x) * 4;
      if (pixels[i + 3] < 245 ||
          !_isGold(pixels[i], pixels[i + 1], pixels[i + 2])) continue;
      if (x < left) left = x;
      if (y < top) top = y;
      if (x > right) right = x;
      if (y > bottom) bottom = y;
    }
  }
  return ui.Rect.fromLTRB(
      left / _ratio, top / _ratio, (right + 1) / _ratio, (bottom + 1) / _ratio);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('outside the season the exact original mint and pink scene remains',
      () async {
    final time = ValueNotifier(4.0);
    addTearDown(time.dispose);
    final original = await _render(ParticleForestPainter(time: time));
    final outside = await _render(ParticleForestPainter(
        time: time, season: TreeSeason.fromLocalDate(DateTime(2026, 11, 26))));
    expect(listEquals(original, outside), isTrue);
    expect(_count(outside, (r, g, b) => r == 153 && g == 238 && b == 221),
        greaterThan(100));
    expect(_count(outside, (r, g, b) => r == 255 && g == 170 && b == 204),
        greaterThan(100));
    expect(_count(outside, _isGold), 0);
  });

  test('December 7 uses green foliage and red garlands on all three trees',
      () async {
    final time = ValueNotifier(4.0);
    addTearDown(time.dispose);
    final pixels = await _render(ParticleForestPainter(
        time: time, season: TreeSeason.fromLocalDate(DateTime(2026, 12, 7))));
    expect(_count(pixels, _isGreen), greaterThan(1000));
    expect(_count(pixels, _isRed), greaterThan(200));
    expect(_count(pixels, (r, g, b) => r == 153 && g == 238 && b == 221), 0);
    expect(_count(pixels, (r, g, b) => r == 255 && g == 170 && b == 204), 0);
    expect(_count(pixels, _isGold, bottom: 280), 0);
  });

  test('motifs accumulate without moving the first cookie', () async {
    final time = ValueNotifier(4.0);
    addTearDown(time.dispose);
    Future<Uint8List> day(int day) => _render(ParticleForestPainter(
        time: time, season: TreeSeason.fromLocalDate(DateTime(2026, 12, day))));
    final first = await day(1);
    final second = await day(2);
    final later = await day(24);
    final firstDetails = _count(first, _isMotif);
    expect(firstDetails, greaterThan(100));
    expect(_count(second, _isMotif), greaterThan(firstDetails));
    expect(_count(later, _isMotif), greaterThan(firstDetails * 3));
    for (var i = 0; i < first.length; i += 4) {
      if (first[i + 3] < 245 ||
          !_isMotif(first[i], first[i + 1], first[i + 2])) {
        continue;
      }
      // Growing the batch can change antialias coverage; cookie dots must
      // still occupy their original pixels and retain their own detail hue.
      expect(second[i + 3], greaterThanOrEqualTo(first[i + 3] - 8));
      expect(_isMotif(second[i], second[i + 1], second[i + 2]), isTrue,
          reason: 'Existing motifs must keep their anchored positions.');
    }
  });

  test('only Christmas Day adds a gold star above the central tip', () async {
    final time = ValueNotifier(4.0);
    addTearDown(time.dispose);
    for (final date in [DateTime(2026, 12, 24), DateTime(2026, 12, 26)]) {
      final pixels = await _render(ParticleForestPainter(
          time: time, season: TreeSeason.fromLocalDate(date)));
      expect(_count(pixels, _isGold, bottom: 280), 0);
    }
    final pixels = await _render(ParticleForestPainter(
        time: time, season: TreeSeason.fromLocalDate(DateTime(2026, 12, 25))));
    final star = _starBounds(pixels);
    expect(star.center.dx, closeTo(_size.width / 2, 1));
    expect(star.width, inInclusiveRange(18, 28));
    expect(star.height, inInclusiveRange(18, 28));
    expect(star.top, greaterThanOrEqualTo(198));
    expect(star.bottom, lessThan(230));
  });

  test(
      'ornaments and Christmas star hold, pause, and replay with the tree clock',
      () async {
    final time = ValueNotifier(0.0);
    addTearDown(time.dispose);
    final painter = ParticleForestPainter(
        time: time, season: TreeSeason.fromLocalDate(DateTime(2026, 12, 25)));
    final initial = await _render(painter);
    expect(_count(initial, _isGold, bottom: 700), 0);
    for (final seconds in [4.0, 12.0, 30.0, 120.0]) {
      time.value = seconds;
      final formed = await _render(painter);
      expect(_count(formed, _isMotif, top: 280, bottom: 700), greaterThan(500));
      expect(_count(formed, _isGold, bottom: 280), greaterThan(100));
      expect(listEquals(formed, await _render(painter)), isTrue);
    }
    time.value = 0;
    expect(listEquals(initial, await _render(painter)), isTrue);
  });
}
