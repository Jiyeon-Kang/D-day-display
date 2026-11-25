import 'package:d_day_display/christmas_countdown_date.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('countdown starts at local midnight on December 1', () {
    final before = ChristmasCountdownDate.fromLocalDate(
      DateTime(2026, 11, 30, 23, 59, 59),
    );
    final start = ChristmasCountdownDate.fromLocalDate(DateTime(2026, 12, 1));

    expect(before.isVisible, isFalse);
    expect(before.daysRemaining, isNull);
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

  test('December 5 and 6 display the birthday greeting every year', () {
    for (final year in [2026, 2027, 2028]) {
      for (final day in [5, 6]) {
        final birthday = ChristmasCountdownDate.fromLocalDate(
          DateTime(year, 12, day, 23, 59),
        );
        expect(birthday.isVisible, isTrue);
        expect(birthday.isBirthday, isTrue);
        expect(birthday.displayLabel, '雫、誕生日おめでとう〜');
        expect(birthday.semanticsLabel, '雫、誕生日おめでとう〜');
        expect(birthday.daysRemaining, 25 - day);
      }
    }
  });

  test('birthday scenes are not used before, after, or outside December', () {
    for (final date in [
      DateTime(2026, 12, 4),
      DateTime(2026, 12, 7),
      DateTime(2026, 11, 5),
      DateTime(2026, 6, 6),
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

  test('countdown disappears at midnight on December 26', () {
    final after = ChristmasCountdownDate.fromLocalDate(DateTime(2026, 12, 26));

    expect(after.isVisible, isFalse);
    expect(after.isChristmas, isFalse);
    expect(after.daysRemaining, isNull);
    expect(after.displayLabel, isEmpty);
    expect(after.subtitle, isEmpty);
    expect(after.semanticsLabel, isEmpty);
  });

  test('other months remain hidden, without counting toward next Christmas',
      () {
    for (final date in [
      DateTime(2026, 1, 1),
      DateTime(2026, 6, 25),
      DateTime(2026, 11, 25),
      DateTime(2026, 12, 31),
      DateTime(2027, 1, 1),
    ]) {
      final countdown = ChristmasCountdownDate.fromLocalDate(date);
      expect(countdown.isVisible, isFalse,
          reason: '$date is outside the season.');
      expect(countdown.daysRemaining, isNull);
    }
  });

  test('each year uses that year’s December 25, including leap years', () {
    for (final year in [2024, 2026, 2027, 2028, 2030]) {
      final first = ChristmasCountdownDate.fromLocalDate(DateTime(year, 12, 1));
      final christmas =
          ChristmasCountdownDate.fromLocalDate(DateTime(year, 12, 25));
      expect(first.year, year);
      expect(first.daysRemaining, 24);
      expect(christmas.daysRemaining, 0);
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
