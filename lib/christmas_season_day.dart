/// The event year stays fixed when the device calendar crosses into a new year.
const christmasSeasonYear = 2026;

/// Clamp the local date to this event's December 1–25 display window.
/// Keep the actual device/test date separate from this display phase.
int christmasSeasonDay(DateTime date) {
  final local = date.toLocal();
  final start = DateTime(christmasSeasonYear, DateTime.december, 1);
  final christmas = DateTime(christmasSeasonYear, DateTime.december, 25);
  if (local.isBefore(start)) return 1;
  if (!local.isBefore(christmas)) return 25;
  return local.day;
}
