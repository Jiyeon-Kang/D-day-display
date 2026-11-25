import 'package:d_day_display/birthday_scene.dart';
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
  testWidgets('pause and resume preserve animation time', (tester) async {
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

    await tester.tap(find.text('재생'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    expect(clock.value, greaterThan(pausedTime));
    expect(find.text('일시정지'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });

  testWidgets('replay restarts the intro while playing or paused',
      (tester) async {
    await tester.pumpWidget(const ParticleTreeApp());
    await tester.pump();
    final clock = forestPainter(tester).time;

    for (final pauseBeforeReplay in [false, true]) {
      for (var frame = 0; frame < 200; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(clock.value, greaterThan(3));

      if (pauseBeforeReplay) {
        await tester.tap(find.text('일시정지'));
        await tester.pump();
        expect(find.text('재생'), findsOneWidget);
      }

      await tester.tap(find.text('다시 보기'));
      expect(clock.value, 0);
      await tester.pump();
      expect(find.text('일시정지'), findsOneWidget);
      expect(find.text('재생'), findsNothing);

      await tester.pump(const Duration(milliseconds: 16));
      expect(clock.value, greaterThan(0));
    }
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

  testWidgets(
      'date arrows select birthday scenes and today restores the device',
      (tester) async {
    addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
    await tester.pumpWidget(
      MaterialApp(
        home: ParticleTreePage(
          now: () => DateTime(2026, 12, 4, 10),
          showDateControls: true,
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(BirthdayScene), findsNothing);
    expect(find.text('2026.12.04 · 단말 날짜'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('next-date')));
    await tester.pump();
    expect(find.byType(BirthdayScene), findsOneWidget);
    expect(find.text('2026.12.05 · 테스트'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('next-date')));
    await tester.pump();
    expect(find.byType(BirthdayScene), findsOneWidget);
    expect(find.text('2026.12.06 · 테스트'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('next-date')));
    await tester.pump();
    expect(find.byType(BirthdayScene), findsNothing);
    expect(find.text('2026.12.07 · 테스트'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('previous-date')));
    await tester.pump();
    expect(find.byType(BirthdayScene), findsOneWidget);
    expect(find.text('2026.12.06 · 테스트'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('device-date')));
    await tester.pump();
    expect(find.byType(BirthdayScene), findsNothing);
    expect(find.text('2026.12.04 · 단말 날짜'), findsOneWidget);
    expect(find.text('일시정지'), findsOneWidget);
  });

  testWidgets('date testing controls can be omitted from the normal screen',
      (tester) async {
    addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
    await tester.pumpWidget(
      const MaterialApp(home: ParticleTreePage(showDateControls: false)),
    );
    expect(find.byKey(const ValueKey('previous-date')), findsNothing);
    expect(find.byKey(const ValueKey('next-date')), findsNothing);
    expect(find.byKey(const ValueKey('device-date')), findsNothing);
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
