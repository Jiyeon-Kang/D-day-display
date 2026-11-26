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

  @override
  bool operator ==(Object other) =>
      other is TreeSeason &&
      other.ornamentCount == ornamentCount &&
      other.useClassicColors == useClassicColors &&
      other.showStar == showStar;

  @override
  int get hashCode => Object.hash(ornamentCount, useClassicColors, showStar);
}
