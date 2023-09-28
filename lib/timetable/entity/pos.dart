import 'package:quiver/core.dart';

import 'timetable.dart';

class TimetablePos {
  /// starts with 1
  /// If you want week index, please do
  /// ```dart
  /// final weekIndex = position.week - 1;
  /// ```
  final int week;

  /// starts with 1
  /// If you want day index, please do
  /// ```dart
  /// final dayIndex = position.day - 1;
  /// ```
  final int day;

  const TimetablePos({
    required this.week,
    required this.day,
  });

  static const initial = TimetablePos(week: 1, day: 1);

  static TimetablePos locate(
    DateTime current, {
    required DateTime relativeTo,
    TimetablePos? fallback,
  }) {
    // calculate how many days have passed.
    int totalDays = current.clearTime().difference(relativeTo.clearTime()).inDays;

    int week = totalDays ~/ 7 + 1;
    int day = totalDays % 7 + 1;
    if (totalDays >= 0 && 1 <= week && week <= 20 && 1 <= day && day <= 7) {
      return TimetablePos(week: week, day: day);
    } else {
      // if out of range, fallback will be return.
      return fallback ?? const TimetablePos(week: 1, day: 1);
    }
  }

  TimetablePos copyWith({int? week, int? day}) => TimetablePos(
        week: week ?? this.week,
        day: day ?? this.day,
      );

  @override
  bool operator ==(Object other) {
    return other is TimetablePos && runtimeType == other.runtimeType && week == other.week && day == other.day;
  }

  @override
  int get hashCode => hash2(week, day);
}

extension _DateTimeX on DateTime {
  DateTime clearTime([int hour = 0, int minute = 0, int second = 0]) {
    return DateTime(year, month, day, hour, minute, second);
  }
}

extension TimetableX on SitTimetable {
  TimetablePos locate(DateTime current) {
    return TimetablePos.locate(current, relativeTo: startDate);
  }
}