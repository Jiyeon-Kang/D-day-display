import 'dart:ui' as ui;

import 'package:d_day_display/birthday_hearts.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

const _size = ui.Size(393, 852);
const _ratio = 2;

Future<Uint8List> _render(BirthdayHeartsPainter painter) async {
  final recorder = ui.PictureRecorder();
  painter.paint(ui.Canvas(recorder)..scale(_ratio.toDouble()), _size);
  final picture = recorder.endRecording();
  final image = await picture.toImage(
      (_size.width * _ratio).round(), (_size.height * _ratio).round());
  try {
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    return Uint8List.fromList(bytes!.buffer.asUint8List());
  } finally {
    image.dispose();
    picture.dispose();
  }
}

List<ui.Rect> _groups(Uint8List pixels) {
  final width = (_size.width * _ratio).round();
  const binSize = 4 * _ratio;
  final columns = (width / binSize).ceil();
  final bins = <int, ui.Rect>{};
  for (var offset = 0; offset < pixels.length; offset += 4) {
    if (pixels[offset + 3] < 8) continue;
    final pixel = offset ~/ 4;
    final x = pixel % width;
    final y = pixel ~/ width;
    final bin = (y ~/ binSize) * columns + x ~/ binSize;
    final rect =
        ui.Rect.fromLTWH(x / _ratio, y / _ratio, 1 / _ratio, 1 / _ratio);
    bins[bin] = bins[bin]?.expandToInclude(rect) ?? rect;
  }
  final groups = <ui.Rect>[];
  while (bins.isNotEmpty) {
    final pending = [bins.keys.first];
    var bounds = bins.remove(pending.first)!;
    while (pending.isNotEmpty) {
      final current = pending.removeLast();
      final x = current % columns;
      final y = current ~/ columns;
      for (var dy = -1; dy <= 1; dy++) {
        for (var dx = -1; dx <= 1; dx++) {
          final neighborX = x + dx;
          if (neighborX < 0 || neighborX >= columns || y + dy < 0) continue;
          final neighbor = (y + dy) * columns + neighborX;
          final rect = bins.remove(neighbor);
          if (rect == null) continue;
          pending.add(neighbor);
          bounds = bounds.expandToInclude(rect);
        }
      }
    }
    groups.add(bounds);
  }
  return groups;
}

bool _hasInk(Uint8List pixels, ui.Rect rect) {
  final width = (_size.width * _ratio).round();
  for (var y = (rect.top * _ratio).ceil();
      y < (rect.bottom * _ratio).floor();
      y++) {
    for (var x = (rect.left * _ratio).ceil();
        x < (rect.right * _ratio).floor();
        x++) {
      if (pixels[(y * width + x) * 4 + 3] > 8) return true;
    }
  }
  return false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('five hollow dot hearts leave the title and controls clear', () async {
    final time = ValueNotifier(4.0);
    addTearDown(time.dispose);
    final pixels = await _render(BirthdayHeartsPainter(time: time));
    final groups = _groups(pixels);
    expect(groups, hasLength(5));
    for (final heart in groups) {
      expect(heart.width, inInclusiveRange(20, 40));
      expect(heart.height, inInclusiveRange(18, 36));
      expect(heart.left, greaterThan(0));
      expect(heart.right, lessThan(_size.width));
      expect(heart.top, greaterThanOrEqualTo(190));
      expect(heart.bottom, lessThan(700));
      final hollow =
          ui.Rect.fromCenter(center: heart.center, width: 4, height: 3);
      expect(_hasInk(pixels, hollow), isFalse);
    }
  });

  test('hearts remain formed and replay alone returns them to the lower cloud',
      () async {
    final time = ValueNotifier(0.0);
    addTearDown(time.dispose);
    final painter = BirthdayHeartsPainter(time: time);
    final initial = await _render(painter);
    expect(_hasInk(initial, const ui.Rect.fromLTWH(0, 0, 393, 720)), isFalse);
    for (final seconds in [4.0, 30.0, 120.0]) {
      time.value = seconds;
      final formed = await _render(painter);
      expect(_groups(formed), hasLength(5));
      expect(
          _hasInk(formed, const ui.Rect.fromLTWH(0, 720, 393, 132)), isFalse);
      expect(listEquals(formed, await _render(painter)), isTrue);
    }
    time.value = 0;
    expect(listEquals(initial, await _render(painter)), isTrue);
  });
}
