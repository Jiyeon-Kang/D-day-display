import 'package:d_day_display/tree_season.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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

  test('dates outside the December 1 to 25 season have the neutral tree', () {
    for (final date in [
      DateTime(2026, 1, 25),
      DateTime(2026, 11, 30),
      DateTime(2026, 12, 26),
      DateTime(2026, 12, 31),
      DateTime(2027, 1, 1),
    ]) {
      expect(TreeSeason.fromLocalDate(date), const TreeSeason());
    }
  });

  test('local midnight and each year use calendar dates without elapsed hours',
      () {
    for (final year in [2026, 2027, 2028]) {
      expect(TreeSeason.fromLocalDate(DateTime(year, 12, 24, 23, 59, 59)),
          const TreeSeason(ornamentCount: 36, useClassicColors: true));
      final christmas = TreeSeason.fromLocalDate(DateTime(year, 12, 25));
      expect(
          christmas,
          const TreeSeason(
              ornamentCount: 37, useClassicColors: true, showStar: true));
      expect(christmas.hashCode,
          TreeSeason.fromLocalDate(DateTime(year, 12, 25, 23, 59)).hashCode);
    }
  });

  test('UTC instants are interpreted in the device local calendar', () {
    final instant = DateTime.utc(2026, 12, 7, 1);
    final local = instant.toLocal();
    expect(TreeSeason.fromLocalDate(instant),
        TreeSeason.fromLocalDate(DateTime(local.year, local.month, local.day)));
  });
}
