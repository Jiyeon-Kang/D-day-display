import 'package:d_day_display/christmas_countdown.dart';
import 'package:d_day_display/particle_countdown_text.dart';
import 'package:d_day_display/particle_tree.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Finder particleTextCanvas() => find.byWidgetPredicate(
      (widget) =>
          widget is CustomPaint &&
          widget.painter is ParticleCountdownTextPainter,
    );

ParticleCountdownTextPainter countdownPainter(WidgetTester tester) =>
    tester.widget<CustomPaint>(particleTextCanvas()).painter!
        as ParticleCountdownTextPainter;

Finder countdownTextWidgets() => find.descendant(
      of: find.byType(ChristmasCountdown),
      matching: find.byType(Text),
    );

Future<void> showCountdown(
  WidgetTester tester,
  ChristmasCountdown countdown,
) async {
  addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
  await tester.pumpWidget(
    MaterialApp(home: Scaffold(body: Center(child: countdown))),
  );
  await tester.pump();
}

void main() {
  testWidgets('countdown is hidden outside the Christmas season',
      (tester) async {
    for (final date in [DateTime(2026, 11, 30), DateTime(2026, 12, 26)]) {
      await showCountdown(
        tester,
        ChristmasCountdown(
          key: ValueKey(date),
          now: () => date,
          animated: false,
        ),
      );

      expect(particleTextCanvas(), findsNothing);
      expect(countdownTextWidgets(), findsNothing);
      expect(tester.getSize(find.byType(ChristmasCountdown)).height, 0);
    }
  });

  testWidgets('December dates form particle letters without a text header',
      (tester) async {
    for (final scenario in [
      (date: DateTime(2026, 12, 1, 23, 59), label: 'D-24', days: 24),
      (date: DateTime(2026, 12, 10, 12), label: 'D-15', days: 15),
    ]) {
      await showCountdown(
        tester,
        ChristmasCountdown(
          key: ValueKey(scenario.date),
          now: () => scenario.date,
          animated: false,
        ),
      );

      expect(countdownPainter(tester).text, scenario.label);
      expect(countdownPainter(tester).time.value, greaterThanOrEqualTo(3));
      expect(countdownTextWidgets(), findsNothing);
    }
  });

  testWidgets('Christmas day forms the lowercase greeting from particles',
      (tester) async {
    await showCountdown(
      tester,
      ChristmasCountdown(
        now: () => DateTime(2026, 12, 25, 18),
        animated: false,
      ),
    );

    expect(countdownPainter(tester).text, 'merry christmas!');
    expect(countdownTextWidgets(), findsNothing);
  });

  testWidgets('the display changes at device-local midnight', (tester) async {
    var now = DateTime(2026, 12, 24, 23, 59, 59);
    await showCountdown(
      tester,
      ChristmasCountdown(now: () => now, animated: false),
    );
    expect(countdownPainter(tester).text, 'D-1');

    now = DateTime(2026, 12, 25, 0, 0, 1);
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 1));

    expect(countdownPainter(tester).text, 'merry christmas!');
    expect(countdownPainter(tester).time.value, greaterThanOrEqualTo(3));
  });

  testWidgets('returning to the app refreshes the device date immediately',
      (tester) async {
    var now = DateTime(2026, 12, 10, 20);
    await showCountdown(
      tester,
      ChristmasCountdown(now: () => now, animated: false),
    );
    expect(countdownPainter(tester).text, 'D-15');

    addTearDown(() => tester.binding
        .handleAppLifecycleStateChanged(AppLifecycleState.resumed));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    now = DateTime(2026, 12, 11, 8);
    await tester.pump(const Duration(seconds: 1));
    expect(countdownPainter(tester).text, 'D-15');

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(countdownPainter(tester).text, 'D-14');
  });

  testWidgets('date refresh continues while visual animation is disabled',
      (tester) async {
    var now = DateTime(2026, 12, 10, 12);
    await showCountdown(
      tester,
      ChristmasCountdown(now: () => now, animated: false),
    );
    expect(countdownPainter(tester).text, 'D-15');

    now = DateTime(2026, 12, 11, 12);
    await tester.pump(const Duration(seconds: 31));
    await tester.pump(const Duration(seconds: 1));

    expect(countdownPainter(tester).text, 'D-14');
    expect(countdownPainter(tester).time.value, greaterThanOrEqualTo(3));
  });

  testWidgets('preview is announced accessibly without adding a visible badge',
      (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      await showCountdown(
        tester,
        ChristmasCountdown(
          now: () => DateTime(2026, 11, 25),
          previewDate: DateTime(2026, 12, 10),
          animated: false,
        ),
      );

      expect(countdownPainter(tester).text, 'D-15');
      expect(
        find.bySemanticsLabel(RegExp('미리보기.*12월 10일.*15일')),
        findsOneWidget,
      );
      expect(countdownTextWidgets(), findsNothing);
    } finally {
      semantics.dispose();
    }
  });

  for (final textScale in [1.0, 3.0]) {
    testWidgets(
        'iPhone 15 particle letters fit above the trees at ${textScale}x text',
        (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(393, 852);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: const Size(393, 852),
              padding: const EdgeInsets.only(top: 59, bottom: 34),
              textScaler: TextScaler.linear(textScale),
            ),
            child: ParticleTreePage(previewDate: DateTime(2026, 12, 10)),
          ),
        ),
      );
      await tester.pump();

      final rect = tester.getRect(find.byType(ChristmasCountdown));
      expect(countdownPainter(tester).text, 'D-15');
      expect(countdownTextWidgets(), findsNothing);
      expect(rect.left, greaterThanOrEqualTo(16));
      expect(rect.right, lessThanOrEqualTo(393 - 16));
      expect(rect.top, greaterThanOrEqualTo(59));
      expect(rect.bottom, lessThanOrEqualTo(210));
      expect(find.text('다시 보기'), findsOneWidget);
      expect(find.text('일시정지'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('replay reforms the particle letters while playing or paused',
      (tester) async {
    addTearDown(() => tester.pumpWidget(const SizedBox.shrink()));
    await tester.pumpWidget(
      MaterialApp(
        home: ParticleTreePage(previewDate: DateTime(2026, 12, 10)),
      ),
    );
    await tester.pump();

    for (final pauseBeforeReplay in [false, true]) {
      for (var frame = 0; frame < 200; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(countdownPainter(tester).time.value, greaterThanOrEqualTo(3));

      if (pauseBeforeReplay) {
        await tester.tap(find.text('일시정지'));
        await tester.pump();
        final pausedTime = countdownPainter(tester).time.value;
        await tester.pump(const Duration(seconds: 1));
        expect(countdownPainter(tester).time.value, pausedTime);
      }

      await tester.tap(find.text('다시 보기'));
      await tester.pump();
      expect(countdownPainter(tester).text, 'D-15');
      expect(countdownPainter(tester).time.value, lessThan(0.05));
      expect(find.text('일시정지'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));
      expect(countdownPainter(tester).time.value, greaterThan(0));
    }
  });
}
