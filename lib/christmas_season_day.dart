/// The most recent December celebration stays complete until December starts
/// again. Keep the actual device/test date separate from this display phase.
int christmasSeasonDay(DateTime date) {
  final local = date.toLocal();
  if (local.month != DateTime.december || local.day >= 25) return 25;
  return local.day;
}
