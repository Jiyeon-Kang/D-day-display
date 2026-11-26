import 'dart:ui' as ui;

import 'package:d_day_display/christmas_ornament.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('five distinct motifs remain bounded and keep their colored details',
      () {
    final signatures = <String>{};
    for (final kind in ChristmasOrnamentKind.values) {
      final sprite = getChristmasOrnamentSprite(kind);
      expect(identical(sprite, getChristmasOrnamentSprite(kind)), isTrue);
      expect(sprite.width, inInclusiveRange(10, 15));
      expect(sprite.height, inInclusiveRange(15, 18));
      expect(sprite.dots.length, greaterThan(65));
      expect(sprite.dots.map((dot) => dot.color).toSet().length,
          greaterThanOrEqualTo(2));
      for (final dot in sprite.dots) {
        expect(dot.x.abs(), lessThan(sprite.width / 2));
        expect(dot.y.abs(), lessThan(sprite.height / 2));
        expect(
            dot.color, inInclusiveRange(0, christmasOrnamentColors.length - 1));
      }
      signatures.add(
          sprite.dots.map((dot) => '${dot.x},${dot.y},${dot.color}').join(';'));
    }
    expect(signatures, hasLength(5));
  });

  test('colored motif features survive rendering at phone ornament size',
      () async {
    final images = <Uint8List>[];
    for (final kind in ChristmasOrnamentKind.values) {
      final sprite = getChristmasOrnamentSprite(kind);
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder)..scale(3);
      for (final dot in sprite.dots) {
        canvas.drawRect(
          ui.Rect.fromCenter(
            center: ui.Offset(16 + dot.x * 1.24, 16 + dot.y * 1.24),
            width: 1.24,
            height: 0.99,
          ),
          ui.Paint()..color = christmasOrnamentColors[dot.color],
        );
      }
      final picture = recorder.endRecording();
      final image = await picture.toImage(96, 96);
      final pixels = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final bytes = Uint8List.fromList(pixels!.buffer.asUint8List());
      image.dispose();
      picture.dispose();
      var opaque = 0;
      for (var i = 3; i < bytes.length; i += 4) {
        if (bytes[i] > 200) opaque++;
      }
      expect(opaque, greaterThan(200), reason: kind.name);
      for (final earlier in images) {
        expect(listEquals(earlier, bytes), isFalse);
      }
      images.add(bytes);
    }
  });
}
