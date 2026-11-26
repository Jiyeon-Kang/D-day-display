import 'christmas_ornament.dart';

/// Annual tree decorations based on the device's local December calendar.
class TreeSeason {
  const TreeSeason({
    this.ornamentCount = 0,
    this.useClassicColors = false,
    this.showStar = false,
  });

  factory TreeSeason.fromLocalDate(DateTime date) {
    final local = date.toLocal();
    if (local.month != DateTime.december || local.day > 25) {
      return const TreeSeason();
    }
    return TreeSeason(
      ornamentCount: local.day * 3 ~/ 2,
      useClassicColors: local.day >= 7,
      showStar: local.day == 25,
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
