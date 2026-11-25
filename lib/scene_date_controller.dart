import 'dart:async';

import 'package:flutter/foundation.dart';

import 'christmas_countdown_date.dart';

/// Keeps the scene on the device's local date unless a test date is selected.
class SceneDateController extends ChangeNotifier {
  SceneDateController({
    DateTime Function() now = DateTime.now,
    DateTime? initialPreviewDate,
    bool active = true,
  })  : _now = now,
        _active = active {
    final current = _now().toLocal();
    _deviceDate = _calendarDate(current);
    _testDate = initialPreviewDate == null
        ? null
        : _calendarDate(initialPreviewDate.toLocal());
    _scheduleRefresh(current);
  }

  final DateTime Function() _now;
  late DateTime _deviceDate;
  DateTime? _testDate;
  Timer? _refreshTimer;
  bool _active;
  bool _disposed = false;

  DateTime get date => _testDate ?? _deviceDate;

  bool get isTesting => _testDate != null;

  bool get isBirthday => ChristmasCountdownDate.fromLocalDate(date).isBirthday;

  void shiftDay(int offset) {
    if (offset == 0 || _disposed) return;
    final selected = date;
    setPreviewDate(
        DateTime(selected.year, selected.month, selected.day + offset));
  }

  void setPreviewDate(DateTime selected) {
    if (_disposed) return;
    final next = _calendarDate(selected.toLocal());
    final changed = !isTesting || next != _testDate;
    _testDate = next;
    _refreshTimer?.cancel();
    if (changed) notifyListeners();
  }

  void useDeviceDate() {
    if (_disposed) return;
    final wasTesting = isTesting;
    final previous = date;
    final current = _now().toLocal();
    _deviceDate = _calendarDate(current);
    _testDate = null;
    _scheduleRefresh(current);
    if (wasTesting || previous != date) notifyListeners();
  }

  void refresh() {
    if (_disposed) return;
    final previous = date;
    final current = _now().toLocal();
    _deviceDate = _calendarDate(current);
    _scheduleRefresh(current);
    if (!isTesting && previous != date) notifyListeners();
  }

  void setActive(bool active) {
    if (_disposed) return;
    _active = active;
    if (active) {
      refresh();
    } else {
      _refreshTimer?.cancel();
    }
  }

  void _scheduleRefresh(DateTime current) {
    _refreshTimer?.cancel();
    if (!_active || isTesting) return;
    final midnight = DateTime(current.year, current.month, current.day + 1);
    final remaining = midnight.difference(current);
    final delay = remaining < const Duration(seconds: 30)
        ? remaining + const Duration(milliseconds: 1)
        : const Duration(seconds: 30);
    _refreshTimer = Timer(delay, refresh);
  }

  static DateTime _calendarDate(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  @override
  void dispose() {
    _disposed = true;
    _refreshTimer?.cancel();
    super.dispose();
  }
}
