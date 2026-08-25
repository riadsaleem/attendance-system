import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppTimes {
  const AppTimes({
    this.schoolStart = const TimeOfDay(hour: 8, minute: 30),
    this.staffStart = const TimeOfDay(hour: 9, minute: 0),
  });

  final TimeOfDay schoolStart;
  final TimeOfDay staffStart;

  String get schoolStartLabel => _format(schoolStart);
  String get staffStartLabel => _format(staffStart);

  static String _format(TimeOfDay t) {
    final String h = t.hourOfPeriod == 0 ? '12' : '${t.hourOfPeriod}';
    final String m = t.minute.toString().padLeft(2, '0');
    return '$h:$m ${t.period == DayPeriod.am ? 'ص' : 'م'}';
  }
}

final appTimesProvider =
    StateNotifierProvider<TimesNotifier, AppTimes>((ref) => TimesNotifier());

class TimesNotifier extends StateNotifier<AppTimes> {
  TimesNotifier() : super(const AppTimes()) {
    _load();
  }

  static const String _schoolKey = 'school_start_minutes';
  static const String _staffKey = 'staff_start_minutes';

  Future<void> _load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int? school = prefs.getInt(_schoolKey);
    final int? staff = prefs.getInt(_staffKey);
    state = AppTimes(
      schoolStart: school == null
          ? state.schoolStart
          : TimeOfDay(hour: school ~/ 60, minute: school % 60),
      staffStart: staff == null
          ? state.staffStart
          : TimeOfDay(hour: staff ~/ 60, minute: staff % 60),
    );
  }

  Future<void> update({
    TimeOfDay? schoolStart,
    TimeOfDay? staffStart,
  }) async {
    state = AppTimes(
      schoolStart: schoolStart ?? state.schoolStart,
      staffStart: staffStart ?? state.staffStart,
    );
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
        _schoolKey, state.schoolStart.hour * 60 + state.schoolStart.minute);
    await prefs.setInt(
        _staffKey, state.staffStart.hour * 60 + state.staffStart.minute);
  }
}
