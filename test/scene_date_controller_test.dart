import 'package:d_day_display/scene_date_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('uses the device local calendar until a test date is selected', () {
    final controller = SceneDateController(
      now: () => DateTime(2026, 12, 4, 23, 30),
    );
    addTearDown(controller.dispose);

    expect(controller.date, DateTime(2026, 12, 4));
    expect(controller.isTesting, isFalse);
    expect(controller.isBirthday, isFalse);

    controller.shiftDay(1);
    expect(controller.date, DateTime(2026, 12, 5));
    expect(controller.isTesting, isTrue);
    expect(controller.isBirthday, isTrue);

    controller.shiftDay(1);
    expect(controller.date, DateTime(2026, 12, 6));
    expect(controller.isBirthday, isTrue);

    controller.shiftDay(1);
    expect(controller.date, DateTime(2026, 12, 7));
    expect(controller.isBirthday, isFalse);

    controller.shiftDay(-1);
    expect(controller.date, DateTime(2026, 12, 6));
    expect(controller.isBirthday, isTrue);
  });

  test('calendar navigation crosses month, year, and leap-day boundaries', () {
    final controller = SceneDateController(
      initialPreviewDate: DateTime(2026, 12, 31, 22),
    );
    addTearDown(controller.dispose);

    controller.shiftDay(1);
    expect(controller.date, DateTime(2027, 1, 1));
    controller.shiftDay(-1);
    expect(controller.date, DateTime(2026, 12, 31));

    controller.setPreviewDate(DateTime(2028, 2, 28));
    controller.shiftDay(1);
    expect(controller.date, DateTime(2028, 2, 29));
    controller.shiftDay(1);
    expect(controller.date, DateTime(2028, 3, 1));
  });

  test(
      'reset returns to the current device date instead of the initial preview',
      () {
    var now = DateTime(2026, 11, 25, 10);
    final controller = SceneDateController(
      now: () => now,
      initialPreviewDate: DateTime(2026, 12, 5),
    );
    addTearDown(controller.dispose);

    expect(controller.isTesting, isTrue);
    expect(controller.isBirthday, isTrue);
    now = DateTime(2026, 11, 26, 8);
    controller.useDeviceDate();

    expect(controller.date, DateTime(2026, 11, 26));
    expect(controller.isTesting, isFalse);
    expect(controller.isBirthday, isFalse);
  });

  test('test date stays fixed while the device calendar changes', () {
    var now = DateTime(2026, 11, 25);
    final controller = SceneDateController(
      now: () => now,
      initialPreviewDate: DateTime(2026, 12, 5),
    );
    addTearDown(controller.dispose);
    var notifications = 0;
    controller.addListener(() => notifications++);

    now = DateTime(2027, 1, 1);
    controller.refresh();
    expect(controller.date, DateTime(2026, 12, 5));
    expect(notifications, 0);

    controller.useDeviceDate();
    expect(controller.date, DateTime(2027, 1, 1));
    expect(notifications, 1);
  });

  test('same-day clock changes do not rebuild the scene', () {
    var now = DateTime(2026, 12, 4, 1);
    final controller = SceneDateController(now: () => now);
    addTearDown(controller.dispose);
    var notifications = 0;
    controller.addListener(() => notifications++);

    now = DateTime(2026, 12, 4, 23);
    controller.refresh();
    expect(notifications, 0);

    now = DateTime(2026, 12, 5);
    controller.refresh();
    expect(notifications, 1);
    expect(controller.isBirthday, isTrue);
  });

  testWidgets('device-local midnight switches the scene without reopening',
      (tester) async {
    var now = DateTime(2026, 12, 4, 23, 59, 59);
    final controller = SceneDateController(now: () => now);
    try {
      expect(controller.isBirthday, isFalse);
      now = DateTime(2026, 12, 5, 0, 0, 1);
      await tester.pump(const Duration(seconds: 2));
      expect(controller.date, DateTime(2026, 12, 5));
      expect(controller.isBirthday, isTrue);
    } finally {
      controller.dispose();
    }
  });

  testWidgets('resuming immediately refreshes a date changed in the background',
      (tester) async {
    var now = DateTime(2026, 12, 6, 20);
    final controller = SceneDateController(now: () => now);
    try {
      controller.setActive(false);
      now = DateTime(2026, 12, 7, 8);
      await tester.pump(const Duration(hours: 12));
      expect(controller.isBirthday, isTrue);

      controller.setActive(true);
      expect(controller.date, DateTime(2026, 12, 7));
      expect(controller.isBirthday, isFalse);
    } finally {
      controller.dispose();
    }
  });
}
