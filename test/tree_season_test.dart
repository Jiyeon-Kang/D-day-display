import 'package:d_day_display/tree_season.dart';
import 'package:d_day_display/christmas_ornament.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('new kinds unlock in stages without changing existing ornaments', () {
    final previous = <ChristmasOrnamentKind>[];
    for (var day = 1; day <= 25; day++) {
      final season = TreeSeason.fromLocalDate(DateTime(2026, 12, day));
      final kinds =
          List.generate(season.ornamentCount, TreeSeason.ornamentKindForIndex);
      expect(kinds.take(previous.length), previous,
          reason: 'Day $day must preserve every earlier design');
      final unlocked = 1 + [7, 12, 17, 22].where((date) => day >= date).length;
      expect(kinds.toSet(), ChristmasOrnamentKind.values.take(unlocked).toSet(),
          reason: 'Day $day may show only its unlocked kinds');
      previous
        ..clear()
        ..addAll(kinds);
    }
  });

  test('the first ornament at each boundary introduces its new kind', () {
    const days = [1, 7, 12, 17, 22];
    for (var stage = 0; stage < days.length; stage++) {
      final firstSlot = (days[stage] - 1) * 3 ~/ 2;
      expect(TreeSeason.ornamentKindForIndex(firstSlot),
          ChristmasOrnamentKind.values[stage]);
    }
    expect(() => TreeSeason.ornamentKindForIndex(-1), throwsRangeError);
    expect(() => TreeSeason.ornamentKindForIndex(37), throwsRangeError);
  });

  test('ornaments grow by one or two every December day through Christmas', () {
    var previous = 0;
    for (var day = 1; day <= 25; day++) {
      final season = TreeSeason.fromLocalDate(DateTime(2026, 12, day));
      expect(season.ornamentCount - previous, inInclusiveRange(1, 2));
      previous = season.ornamentCount;
    }
    expect(TreeSeason.fromLocalDate(DateTime(2026, 12, 1)).ornamentCount, 1);
    expect(TreeSeason.fromLocalDate(DateTime(2026, 12, 7)).ornamentCount, 10);
    expect(previous, 37);
  });

  test('classic colors start on December 7 and the star appears on the 25th',
      () {
    for (var day = 1; day <= 25; day++) {
      final season = TreeSeason.fromLocalDate(DateTime(2026, 12, day));
      expect(season.useClassicColors, day >= 7);
      expect(season.showStar, day == 25);
    }
  });

  test('completed decorations remain through December 31', () {
    for (final date in [
      DateTime(2026, 12, 26),
      DateTime(2026, 12, 31),
    ]) {
      expect(
          TreeSeason.fromLocalDate(date),
          const TreeSeason(
              ornamentCount: 37, useClassicColors: true, showStar: true));
    }
  });

  test('all dates after the event keep the final tree without an annual reset',
      () {
    const completed =
        TreeSeason(ornamentCount: 37, useClassicColors: true, showStar: true);
    for (final date in [
      DateTime(2026, 12, 26),
      DateTime(2027, 1, 1),
      DateTime(2027, 11, 30),
      DateTime(2027, 12, 1),
      DateTime(2027, 12, 5),
      DateTime(2027, 12, 6),
      DateTime(2027, 12, 24),
      DateTime(2028, 2, 29),
      DateTime(2030, 12, 1),
    ]) {
      expect(TreeSeason.fromLocalDate(date), completed, reason: '$date');
    }
  });

  test('dates before the event keep the first tree and its original palette',
      () {
    for (final date in [
      DateTime(2024, 2, 29),
      DateTime(2025, 12, 25),
      for (var month = 1; month < 12; month++) ...[
        DateTime(2026, month, 1),
        DateTime(2026, month + 1, 0, 23, 59, 59),
      ],
      DateTime(2026, 11, 26),
      DateTime(2026, 11, 30, 23, 59, 59),
      DateTime(2026, 12, 1),
    ]) {
      expect(TreeSeason.fromLocalDate(date), const TreeSeason(ornamentCount: 1),
          reason: '$date');
    }
    expect(
        TreeSeason.ornamentKindForIndex(0), ChristmasOrnamentKind.gingerbread);
  });

  test('the final decoration and star appear at local Christmas midnight', () {
    expect(TreeSeason.fromLocalDate(DateTime(2026, 12, 24, 23, 59, 59)),
        const TreeSeason(ornamentCount: 36, useClassicColors: true));
    final christmas = TreeSeason.fromLocalDate(DateTime(2026, 12, 25));
    expect(
        christmas,
        const TreeSeason(
            ornamentCount: 37, useClassicColors: true, showStar: true));
    expect(christmas.hashCode,
        TreeSeason.fromLocalDate(DateTime(2026, 12, 25, 23, 59)).hashCode);
  });

  test('UTC instants are interpreted in the device local calendar', () {
    final instant = DateTime.utc(2026, 12, 7, 1);
    final local = instant.toLocal();
    expect(TreeSeason.fromLocalDate(instant),
        TreeSeason.fromLocalDate(DateTime(local.year, local.month, local.day)));
  });
}
