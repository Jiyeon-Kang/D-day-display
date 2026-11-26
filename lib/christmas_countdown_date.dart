import 'christmas_season_day.dart';

/// A local-calendar countdown that retains its completed Christmas display.
class ChristmasCountdownDate {
  const ChristmasCountdownDate._({
    required this.year,
    required this.month,
    required this.day,
    required this.daysRemaining,
  });

  factory ChristmasCountdownDate.fromLocalDate(DateTime date) {
    final local = date.toLocal();
    return ChristmasCountdownDate._(
      year: local.year,
      month: local.month,
      day: local.day,
      daysRemaining: 25 - christmasSeasonDay(local),
    );
  }

  final int year;
  final int month;
  final int day;

  /// Zero from Christmas Day until the next December countdown begins.
  final int? daysRemaining;

  bool get isVisible => daysRemaining != null;

  bool get isChristmas => daysRemaining == 0;

  bool get isBirthday => month == DateTime.december && (day == 5 || day == 6);

  String get displayLabel {
    final remaining = daysRemaining;
    if (remaining == null) return '';
    if (isBirthday) return '雫、誕生日おめでとう〜';
    return remaining == 0 ? 'merry christmas!' : 'D-$remaining';
  }

  String get subtitle {
    final remaining = daysRemaining;
    if (remaining == null) return '';
    if (isBirthday) return '雫、誕生日おめでとう〜';
    return remaining == 0 ? '메리 크리스마스' : '크리스마스까지 $remaining일';
  }

  String get semanticsLabel {
    final remaining = daysRemaining;
    if (remaining == null) return '';
    if (isBirthday) return '雫、誕生日おめでとう〜';
    if (remaining == 0) {
      return month == DateTime.december && day == 25
          ? '오늘은 크리스마스입니다. 메리 크리스마스.'
          : '크리스마스 완성 화면입니다. 메리 크리스마스.';
    }
    return '크리스마스까지 $remaining일 남았습니다.';
  }
}
