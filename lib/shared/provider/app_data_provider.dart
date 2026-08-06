import 'package:flutter/material.dart';

class AppDateProvider extends ChangeNotifier {
  DateTime? _debugDate;

  DateTime get today => _debugDate ?? DateTime.now();

  bool get isDebugDateEnabled => _debugDate != null;

  void setDebugDate(DateTime date) {
    _debugDate = DateTime(date.year, date.month, date.day);
    notifyListeners();
  }

  void moveToNextDay() {
    final current = today;

    _debugDate = DateTime(current.year, current.month, current.day + 1);

    notifyListeners();
  }

  void startPrototypePeriod() {
    _debugDate = DateTime(2026, 8, 7);
    notifyListeners();
  }

  void clearDebugDate() {
    _debugDate = null;
    notifyListeners();
  }
}
