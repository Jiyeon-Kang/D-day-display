import 'christmas_ornament.dart';
import 'christmas_season_day.dart';

/// Tree decorations within the fixed Christmas event's local calendar window.
class TreeSeason {
  const TreeSeason({
    this.ornamentCount = 0,
    this.useClassicColors = false,
    this.showStar = false,
  });

  factory TreeSeason.fromLocalDate(DateTime date) {
    final day = christmasSeasonDay(date);
    return TreeSeason(
      ornamentCount: day * 3 ~/ 2,
      useClassicColors: day >= 7,
      showStar: day == 25,
    );
  }

  /// One ornament on December 1, then one or two more each calendar day.
  final int ornamentCount;
  final bool useClassicColors;
  final bool showStar;

  /// Assign each slot when it is first added, so later unlocks never replace
  /// an existing ornament. New stages start with their newly unlocked design.
  static ChristmasOrnamentKind ornamentKindForIndex(int index) {
    RangeError.checkValueInInterval(index, 0, 36, 'index');
    const starts = [1, 7, 12, 17, 22];
    final addedDay = ((index + 1) * 2 + 2) ~/ 3;
    var stage = 0;
    while (stage + 1 < starts.length && addedDay >= starts[stage + 1]) {
      stage++;
    }
    final firstSlot = (starts[stage] - 1) * 3 ~/ 2;
    final kind = (stage + index - firstSlot) % (stage + 1);
    return ChristmasOrnamentKind.values[kind];
  }

  @override
  bool operator ==(Object other) =>
      other is TreeSeason &&
      other.ornamentCount == ornamentCount &&
      other.useClassicColors == useClassicColors &&
      other.showStar == showStar;

  @override
  int get hashCode => Object.hash(ornamentCount, useClassicColors, showStar);
}
