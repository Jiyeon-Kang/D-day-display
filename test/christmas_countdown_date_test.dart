import 'package:d_day_display/christmas_countdown_date.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('December 1 keeps the first screen shown before the event', () {
    final before = ChristmasCountdownDate.fromLocalDate(
      DateTime(2026, 11, 30, 23, 59, 59),
    );
    final start = ChristmasCountdownDate.fromLocalDate(DateTime(2026, 12, 1));

    expect(before.isVisible, isTrue);
    expect(before.daysRemaining, 24);
    expect(before.displayLabel, 'D-24');
    expect(start.isVisible, isTrue);
    expect(start.daysRemaining, 24);
    expect(start.displayLabel, 'D-24');
    expect(start.subtitle, '크리스마스까지 24일');
  });

  test('calendar day count stays the same throughout a day', () {
    for (final hour in [0, 12, 23]) {
      final date = ChristmasCountdownDate.fromLocalDate(
        DateTime(2026, 12, 10, hour, 59, 59),
      );
      expect(date.daysRemaining, 15);
      expect(date.displayLabel, 'D-15');
      expect(date.semanticsLabel, contains('15일 남았습니다'));
    }
  });

  test('Christmas Eve remains D-1 until local midnight', () {
    final eve = ChristmasCountdownDate.fromLocalDate(
      DateTime(2026, 12, 24, 23, 59, 59),
    );

    expect(eve.daysRemaining, 1);
    expect(eve.displayLabel, 'D-1');
    expect(eve.isChristmas, isFalse);
  });

  test('December 5 and 6 keep the birthday greeting during the event', () {
    for (final day in [5, 6]) {
      final birthday = ChristmasCountdownDate.fromLocalDate(
        DateTime(2026, 12, day, 23, 59),
      );
      expect(birthday.isVisible, isTrue);
      expect(birthday.isBirthday, isTrue);
      expect(birthday.displayLabel, '雫、誕生日おめでとう〜');
      expect(birthday.semanticsLabel, '雫、誕生日おめでとう〜');
      expect(birthday.daysRemaining, 25 - day);
    }
  });

  test('birthday scenes are not used before, after, or outside December', () {
    for (final date in [
      DateTime(2026, 12, 4),
      DateTime(2026, 12, 7),
      DateTime(2026, 11, 5),
      DateTime(2026, 6, 6),
      DateTime(2025, 12, 5),
      DateTime(2027, 12, 5),
      DateTime(2027, 12, 6),
    ]) {
      final countdown = ChristmasCountdownDate.fromLocalDate(date);
      expect(countdown.isBirthday, isFalse);
    }
    expect(
      ChristmasCountdownDate.fromLocalDate(DateTime(2026, 12, 4)).displayLabel,
      'D-21',
    );
    expect(
      ChristmasCountdownDate.fromLocalDate(DateTime(2026, 12, 7)).displayLabel,
      'D-18',
    );
  });

  test('the particle greeting lasts through all of December 25', () {
    for (final hour in [0, 12, 23]) {
      final christmas = ChristmasCountdownDate.fromLocalDate(
        DateTime(2026, 12, 25, hour, 59, 59),
      );

      expect(christmas.isVisible, isTrue);
      expect(christmas.isChristmas, isTrue);
      expect(christmas.daysRemaining, 0);
      expect(christmas.displayLabel, 'merry christmas!');
      expect(christmas.subtitle, '메리 크리스마스');
      expect(christmas.semanticsLabel, contains('오늘은 크리스마스'));
    }
  });

  test('the Christmas display stays complete through December 31', () {
    for (final date in [
      DateTime(2026, 12, 26),
      DateTime(2026, 12, 31),
    ]) {
      final countdown = ChristmasCountdownDate.fromLocalDate(date);
      expect(countdown.isVisible, isTrue);
      expect(countdown.daysRemaining, 0);
      expect(countdown.displayLabel, 'merry christmas!');
      expect(countdown.semanticsLabel, isNot(contains('오늘은 크리스마스')));
      expect(countdown.month, date.month);
      expect(countdown.day, date.day);
      expect(countdown.isBirthday, isFalse);
    }
  });

  test('dates after the event keep Christmas and the actual device date', () {
    for (final date in [
      DateTime(2027, 1, 1),
      DateTime(2027, 2, 5),
      DateTime(2027, 6, 6),
      DateTime(2027, 11, 30, 23, 59, 59),
      DateTime(2027, 12, 1),
      DateTime(2027, 12, 5),
      DateTime(2027, 12, 6),
      DateTime(2027, 12, 25),
      DateTime(2028, 2, 29),
      DateTime(2030, 12, 25),
    ]) {
      final countdown = ChristmasCountdownDate.fromLocalDate(date);
      expect(countdown.isVisible, isTrue);
      expect(countdown.daysRemaining, 0);
      expect(countdown.displayLabel, 'merry christmas!');
      expect(countdown.semanticsLabel, '크리스마스 완성 화면입니다. 메리 크리스마스.');
      expect(countdown.year, date.year);
      expect(countdown.month, date.month);
      expect(countdown.day, date.day);
      expect(countdown.isBirthday, isFalse);
      expect(countdown.isChristmas, isTrue);
    }
  });

  test('every date before the event shows D-24 and keeps its actual date', () {
    for (final date in [
      DateTime(2024, 2, 29),
      DateTime(2025, 12, 5),
      DateTime(2025, 12, 25),
      DateTime(2026, 1, 1),
      DateTime(2026, 11, 26),
      DateTime(2026, 11, 30, 23, 59, 59),
    ]) {
      final countdown = ChristmasCountdownDate.fromLocalDate(date);
      expect(countdown.isVisible, isTrue);
      expect(countdown.daysRemaining, 24);
      expect(countdown.displayLabel, 'D-24');
      expect(countdown.isBirthday, isFalse);
      expect(countdown.isChristmas, isFalse);
      expect(countdown.year, date.year);
      expect(countdown.month, date.month);
      expect(countdown.day, date.day);
    }
  });

  test('UTC instants are interpreted in the device’s local calendar', () {
    final localMidnight = DateTime(2026, 12, 1, 0, 5);
    final fromLocal = ChristmasCountdownDate.fromLocalDate(localMidnight);
    final fromUtc = ChristmasCountdownDate.fromLocalDate(localMidnight.toUtc());

    expect(fromUtc.year, fromLocal.year);
    expect(fromUtc.isVisible, isTrue);
    expect(fromUtc.daysRemaining, 24);
    expect(fromUtc.displayLabel, fromLocal.displayLabel);
  });
}
