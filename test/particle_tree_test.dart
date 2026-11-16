import 'package:d_day_display/main.dart';
import 'package:d_day_display/particle_forest.dart';
import 'package:d_day_display/particle_tree.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ParticleForestPainter forestPainter(WidgetTester tester) {
  final canvas = tester.widget<CustomPaint>(
    find.byWidgetPredicate(
      (widget) =>
          widget is CustomPaint && widget.painter is ParticleForestPainter,
    ),
  );
  return canvas.painter! as ParticleForestPainter;
}

void main() {
  testWidgets('pause, resume, and replay preserve the requested playback state',
      (tester) async {
    await tester.pumpWidget(const ParticleTreeApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    final clock = forestPainter(tester).time;
    expect(clock.value, greaterThan(0));

    await tester.tap(find.text('일시정지'));
    await tester.pump();
    final pausedTime = clock.value;
    await tester.pump(const Duration(seconds: 2));
    expect(clock.value, pausedTime);
    expect(find.text('재생'), findsOneWidget);

    await tester.tap(find.text('다시 보기'));
    await tester.pump();
    expect(clock.value, 0);
    expect(find.text('재생'), findsOneWidget);

    await tester.tap(find.text('재생'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    expect(clock.value, greaterThan(0));

    await tester.tap(find.text('다시 보기'));
    expect(clock.value, 0);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    expect(clock.value, greaterThan(0));
    expect(find.text('일시정지'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });

  testWidgets('backgrounding freezes time and resumes without a time jump',
      (tester) async {
    await tester.pumpWidget(const ParticleTreeApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    final clock = forestPainter(tester).time;
    final beforeBackground = clock.value;

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(seconds: 30));
    expect(clock.value, beforeBackground);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    expect(clock.value, closeTo(beforeBackground + 0.016, 0.000001));

    final beforeDroppedFrame = clock.value;
    await tester.pump(const Duration(seconds: 1));
    expect(clock.value, closeTo(beforeDroppedFrame + 0.04, 0.000001));
  });

  testWidgets('a manual pause survives leaving and returning to the app',
      (tester) async {
    await tester.pumpWidget(const ParticleTreeApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    await tester.tap(find.text('일시정지'));
    await tester.pump();
    final clock = forestPainter(tester).time;
    final pausedTime = clock.value;

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump(const Duration(seconds: 2));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(seconds: 2));

    expect(clock.value, pausedTime);
    expect(find.text('재생'), findsOneWidget);
    await tester.tap(find.text('재생'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    expect(clock.value, greaterThan(pausedTime));
  });

  for (final scenario in [
    (size: const Size(320, 568), textScale: 1.0),
    (size: const Size(320, 568), textScale: 3.0),
    (size: const Size(1024, 768), textScale: 2.0),
    (size: const Size(568, 320), textScale: 1.0),
  ]) {
    testWidgets(
        'controls fit ${scenario.size} at ${scenario.textScale}x text scale',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = scenario.size;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: scenario.size,
              padding: const EdgeInsets.only(bottom: 34),
              textScaler: TextScaler.linear(scenario.textScale),
            ),
            child: const ParticleTreePage(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));

      for (final label in ['다시 보기', '일시정지']) {
        final button = find.widgetWithText(OutlinedButton, label);
        final rect = tester.getRect(button);
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(scenario.size.width));
        expect(rect.top, greaterThanOrEqualTo(0));
        expect(rect.bottom, lessThanOrEqualTo(scenario.size.height - 34));
        expect(rect.height, greaterThanOrEqualTo(48));
      }
      expect(tester.takeException(), isNull);
    });
  }
}
