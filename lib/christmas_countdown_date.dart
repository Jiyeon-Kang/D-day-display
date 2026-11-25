/// A December 1–25 countdown based on the device's local calendar date.
class ChristmasCountdownDate {
  const ChristmasCountdownDate._({
    required this.year,
    required this.daysRemaining,
  });

  factory ChristmasCountdownDate.fromLocalDate(DateTime date) {
    final local = date.toLocal();
    if (local.month != DateTime.december || local.day > 25) {
      return ChristmasCountdownDate._(year: local.year, daysRemaining: null);
    }

    // Count calendar days, without time-of-day or daylight-saving offsets.
    final today = DateTime.utc(local.year, local.month, local.day);
    final christmas = DateTime.utc(local.year, DateTime.december, 25);
    return ChristmasCountdownDate._(
      year: local.year,
      daysRemaining: christmas.difference(today).inDays,
    );
  }

  final int year;

  /// Null outside December 1–25; zero throughout Christmas Day.
  final int? daysRemaining;

  bool get isVisible => daysRemaining != null;

  bool get isChristmas => daysRemaining == 0;

  String get displayLabel {
    final remaining = daysRemaining;
    if (remaining == null) return '';
    return remaining == 0 ? 'merry christmas!' : 'D-$remaining';
  }

  String get subtitle {
    final remaining = daysRemaining;
    if (remaining == null) return '';
    return remaining == 0 ? '메리 크리스마스' : '크리스마스까지 $remaining일';
  }

  String get semanticsLabel {
    final remaining = daysRemaining;
    if (remaining == null) return '';
    return remaining == 0
        ? '오늘은 크리스마스입니다. 메리 크리스마스.'
        : '크리스마스까지 $remaining일 남았습니다.';
  }
}
