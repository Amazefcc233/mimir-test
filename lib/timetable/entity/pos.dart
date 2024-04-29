import 'dart:typed_data';

import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sit/l10n/time.dart';
import 'package:sit/utils/byte_io.dart';

import 'timetable.dart';
import '../i18n.dart';

part "pos.g.dart";

@JsonSerializable()
@CopyWith(skipFields: true)
class TimetablePos {
  /// starts with 0
  final int weekIndex;

  /// starts with 0
  final Weekday weekday;

  const TimetablePos({
    required this.weekIndex,
    required this.weekday,
  });

  static const initial = TimetablePos(weekIndex: 0, weekday: Weekday.monday);

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
      return TimetablePos(weekIndex: week - 1, weekday: Weekday.fromIndex(day - 1));
    } else {
      // if out of range, fallback will be return.
      return fallback ?? initial;
    }
  }
  Uint8List encodeByteList() {
    final writer = ByteWriter(16);
    writer.int8(weekIndex);
    writer.int8(weekday.index);
    return writer.build();
  }
  String l10n() {
    return "${i18n.weekOrderedName(number: weekIndex + 1)} ${weekday.l10n()}";
  }

  String toDartCode() {
    return "TimetablePos(weekIndex:$weekIndex,weekday:$weekday)";
  }

  factory TimetablePos.fromJson(Map<String, dynamic> json) => _$TimetablePosFromJson(json);

  Map<String, dynamic> toJson() => _$TimetablePosToJson(this);

  @override
  bool operator ==(Object other) {
    return other is TimetablePos &&
        runtimeType == other.runtimeType &&
        weekIndex == other.weekIndex &&
        weekday == other.weekday;
  }

  @override
  int get hashCode => Object.hash(weekIndex, weekday);

  @override
  String toString() {
    return (week: weekIndex, day: weekday).toString();
  }
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

// TODO: finish timetable lesson pos
class TimetableLessonPos {
  final String courseCode;

  /// starts with 0
  final int weekIndex;

  /// starts with 0
  final Weekday weekday;

  const TimetableLessonPos({
    required this.courseCode,
    required this.weekIndex,
    required this.weekday,
  });
}
