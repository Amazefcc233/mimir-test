import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:flutter/foundation.dart';
import 'package:sit/entity/campus.dart';
import 'package:sit/l10n/time.dart';
import 'package:sit/school/entity/school.dart';
import 'package:sit/school/entity/timetable.dart';
import 'package:sit/school/utils.dart';
import 'package:sit/timetable/utils.dart';
import 'package:collection/collection.dart';
import 'package:sit/utils/date.dart';
import 'patch.dart';
import 'platte.dart';
import 'timetable.dart';

part "timetable_entity.g.dart";

/// The entity to display.
class SitTimetableEntity with SitTimetablePaletteResolver {
  @override
  final SitTimetable type;

  /// The Default number of weeks is 20.
  final List<SitTimetableWeek> weeks;

  final _courseCode2CoursesCache = <String, List<SitCourse>>{};

  SitTimetableEntity({
    required this.type,
    required this.weeks,
  }) {
    for (final week in weeks) {
      week.parent = this;
    }
  }

  List<SitCourse> findAndCacheCoursesByCourseCode(String courseCode) {
    final found = _courseCode2CoursesCache[courseCode];
    if (found != null) {
      return found;
    } else {
      final res = <SitCourse>[];
      for (final course in type.courses.values) {
        if (course.courseCode == courseCode) {
          res.add(course);
        }
      }
      _courseCode2CoursesCache[courseCode] = res;
      return res;
    }
  }

  String get name => type.name;

  DateTime get startDate => type.startDate;

  int get schoolYear => type.schoolYear;

  Semester get semester => type.semester;

  Campus get campus => type.campus;

  String get signature => type.signature;

  SitTimetableDay? getDaySinceStart(int days) {
    if (days > maxWeekLength * 7) return null;
    final weekIndex = days ~/ 7;
    if (weekIndex < 0 || weekIndex >= weeks.length) return null;
    final week = weeks[weekIndex];
    final dayIndex = days % 7 - 1;
    return week.days[dayIndex];
  }

  SitTimetableWeek? getWeekOn(DateTime date) {
    if (startDate.isAfter(date)) return null;
    final diff = date.difference(startDate);
    if (diff.inDays > maxWeekLength * 7) return null;
    final weekIndex = diff.inDays ~/ 7;
    if (weekIndex < 0 || weekIndex >= weeks.length) return null;
    return weeks[weekIndex];
  }

  SitTimetableDay? getDayOn(DateTime date) {
    if (startDate.isAfter(date)) return null;
    final diff = date.difference(startDate);
    if (diff.inDays > maxWeekLength * 7) return null;
    final weekIndex = diff.inDays ~/ 7;
    if (weekIndex < 0 || weekIndex >= weeks.length) return null;
    final week = weeks[weekIndex];
    // don't -1 here, because inDays always omitted fraction.
    final dayIndex = diff.inDays % 7;
    return week.days[dayIndex];
  }
}

class SitTimetableWeek {
  late final SitTimetableEntity parent;
  final int index;

  /// The 7 days in a week
  final List<SitTimetableDay> days;

  SitTimetableWeek({
    required this.index,
    required this.days,
  }) {
    for (final day in days) {
      day.parent = this;
    }
  }

  factory SitTimetableWeek.$7days(int weekIndex) {
    return SitTimetableWeek(
      index: weekIndex,
      days: List.generate(7, (index) => SitTimetableDay.$11slots(index)),
    );
  }

  bool get isFree => days.every((day) => day.isFree);

  @override
  String toString() => "$days";

  SitTimetableDay operator [](Weekday weekday) => days[weekday.index];

  operator []=(Weekday weekday, SitTimetableDay day) => days[weekday.index] = day;
}

/// Lessons in the same timeslot.
@CopyWith(skipFields: true)
class SitTimetableLessonSlot {
  late final SitTimetableDay parent;
  final List<SitTimetableLessonPart> lessons;

  SitTimetableLessonSlot({required this.lessons});

  SitTimetableLessonPart? lessonAt(int index) {
    return lessons.elementAtOrNull(index);
  }

  @override
  String toString() {
    return "${_formatDay(parent.date)} $lessons".toString();
  }
}

String _formatDay(DateTime date) {
  return "${date.year}/${date.month}/${date.day}";
}

String _formatTime(DateTime date) {
  return "${date.year}/${date.month}/${date.day} ${date.hour}:${date.minute}";
}

class SitTimetableDay {
  late final SitTimetableWeek parent;
  final int index;

  /// The Default number of lessons in one day is 11. But it can be extended.
  /// For example,
  /// A Timeslot could contain one or more lesson.
  final List<SitTimetableLessonSlot> _timeslot2LessonSlot;

  List<SitTimetableLessonSlot> get timeslot2LessonSlot => UnmodifiableListView(_timeslot2LessonSlot);

  late final Set<SitCourse> _associatedCourses =
      _timeslot2LessonSlot.map((slot) => slot.lessons).flattened.map((part) => part.course).toSet();

  Set<SitCourse> get associatedCourses => UnmodifiableSetView(_associatedCourses);

  bool _frozen = false;

  bool get frozen => _frozen;

  void freeze() {
    _frozen = true;
    throw UnimplementedError();
  }

  DateTime get date => reflectWeekDayIndexToDate(
        startDate: parent.parent.startDate,
        weekIndex: parent.index,
        weekday: Weekday.fromIndex(index),
      );

  SitTimetableDay({
    required int index,
    required List<SitTimetableLessonSlot> timeslot2LessonSlot,
  }) : this._internal(index, List.of(timeslot2LessonSlot));

  SitTimetableDay._internal(this.index, this._timeslot2LessonSlot) {
    for (final lessonSlot in timeslot2LessonSlot) {
      lessonSlot.parent = this;
    }
  }

  factory SitTimetableDay.$11slots(int dayIndex) {
    return SitTimetableDay._internal(
      dayIndex,
      List.generate(11, (index) => SitTimetableLessonSlot(lessons: <SitTimetableLessonPart>[])),
    );
  }

  bool get isFree => _timeslot2LessonSlot.every((lessonSlot) => lessonSlot.lessons.isEmpty);

  void add({required SitTimetableLessonPart lesson, required int at}) {
    if (frozen) throw throw UnsupportedError("Cannot modify a frozen $SitTimetableDay.");
    assert(0 <= at && at < _timeslot2LessonSlot.length);
    if (0 <= at && at < _timeslot2LessonSlot.length) {
      final lessonSlot = _timeslot2LessonSlot[at];
      lessonSlot.lessons.add(lesson);
      lesson.type.parent = this;
    }
  }

  void clear() {
    if (frozen) throw throw UnsupportedError("Cannot modify a frozen $SitTimetableDay.");
    for (final lessonSlot in _timeslot2LessonSlot) {
      lessonSlot.lessons.clear();
    }
  }

  void replaceWith(SitTimetableDay other) {
    // timeslot2LessonSlot
    setLessonSlots(other.cloneLessonSlots());
  }

  void swap(SitTimetableDay other) {
    // timeslot2LessonSlot
    final $timeslot2LessonSlot = other.cloneLessonSlots();
    other.setLessonSlots(cloneLessonSlots());
    setLessonSlots($timeslot2LessonSlot);
  }

  void setLessonSlots(Iterable<SitTimetableLessonSlot> v) {
    _timeslot2LessonSlot.clear();
    _timeslot2LessonSlot.addAll(v);

    for (final lessonSlot in _timeslot2LessonSlot) {
      lessonSlot.parent = this;
      for (final part in lessonSlot.lessons) {
        part.type.parent = this;
      }
    }
  }

  List<SitTimetableLessonSlot> cloneLessonSlots() {
    final old2newLesson = <SitTimetableLesson, SitTimetableLesson>{};
    final timeslots = List.of(
      _timeslot2LessonSlot.map(
        (lessonSlot) {
          return SitTimetableLessonSlot(
            lessons: List.of(
              lessonSlot.lessons.map(
                (lessonPart) {
                  final oldLesson = lessonPart.type;
                  final lesson = old2newLesson[oldLesson] ??
                      oldLesson.copyWith(
                        parts: [],
                      );
                  old2newLesson[oldLesson] ??= lesson;
                  final part = lessonPart.copyWith(
                    type: lesson,
                  );
                  return part;
                },
              ),
            ),
          );
        },
      ),
    );

    for (final slot in timeslots) {
      for (final lessonPart in slot.lessons) {
        lessonPart.type.parts
            .addAll(timeslots.map((slot) => slot.lessons).flattened.where((part) => part.type == lessonPart.type));
      }
    }
    return timeslots;
  }

  /// At all lessons [layer]
  Iterable<SitTimetableLessonPart> browseLessonsAt({required int layer}) sync* {
    for (final lessonSlot in _timeslot2LessonSlot) {
      if (0 <= layer && layer < lessonSlot.lessons.length) {
        yield lessonSlot.lessons[layer];
      }
    }
  }

  bool hasAnyLesson() {
    for (final lessonSlot in _timeslot2LessonSlot) {
      if (lessonSlot.lessons.isNotEmpty) {
        assert(associatedCourses.isNotEmpty);
        return true;
      }
    }
    return false;
  }

  @override
  String toString() => {
        "date": _formatDay(date),
        "index": index,
        "timeslot2LessonSlot": _timeslot2LessonSlot,
        "associatedCourses": associatedCourses,
      }.toString();
}

@CopyWith(skipFields: true)
class SitTimetableLesson {
  late SitTimetableDay parent;

  /// A lesson may last two or more time slots.
  /// If current [SitTimetableLessonPart] is a part of the whole lesson, they all have the same [courseKey].
  final SitCourse course;

  /// in timeslot order
  final List<SitTimetableLessonPart> parts;

  SitTimetableLesson({
    required this.course,
    required this.parts,
  });

  /// How many timeslots this lesson takes.
  /// It's at least 1 timeslot.
  int get timeslotDuration => endIndex - startIndex + 1;

  /// The start index of this lesson in a [SitTimetableWeek]
  int get startIndex => parts.first.index;

  /// The end index of this lesson in a [SitTimetableWeek]
  int get endIndex => parts.last.index;

  DateTime get startTime => parts.first.startTime;

  DateTime get endTime => parts.last.endTime;

  @override
  String toString() {
    return "${course.courseName} ${_formatTime(startTime)} => ${_formatTime(endTime)}";
  }
}

@CopyWith(skipFields: true)
class SitTimetableLessonPart {
  final SitTimetableLesson type;

  /// The start index of this lesson in a [SitTimetableWeek]
  final int index;

  late SitTimetableDay _dayCache = type.parent;

  ({DateTime start, DateTime end})? _timeCache;

  ({DateTime start, DateTime end}) get time {
    final timeCache = _timeCache;

    if (_dayCache == type.parent && timeCache != null) {
      return timeCache;
    } else {
      final thatDay = type.parent.date;
      final classTime = course.calcBeginEndTimePointOfLesson(type.parent.parent.parent.type.campus, index);
      _dayCache = type.parent;
      final time = (start: thatDay.addTimePoint(classTime.begin), end: thatDay.addTimePoint(classTime.end));
      _timeCache = time;
      return time;
    }
  }

  DateTime get startTime => time.start;

  DateTime get endTime => time.end;

  SitCourse get course => type.course;

  SitTimetableLessonPart({
    required this.type,
    required this.index,
  });

  @override
  String toString() => "[$index] $type";
}

extension SitTimetable4EntityX on SitTimetable {
  SitTimetableEntity resolve() {
    final weeks = List.generate(20, (index) => SitTimetableWeek.$7days(index));

    for (final course in courses.values) {
      if (course.hidden) continue;
      final timeslots = course.timeslots;
      for (final weekIndex in course.weekIndices.getWeekIndices()) {
        assert(
          0 <= weekIndex && weekIndex < maxWeekLength,
          "Week index is more out of range [0,$maxWeekLength) but $weekIndex.",
        );
        if (0 <= weekIndex && weekIndex < maxWeekLength) {
          final week = weeks[weekIndex];
          final day = week.days[course.dayIndex];
          final parts = <SitTimetableLessonPart>[];
          final lesson = SitTimetableLesson(
            course: course,
            parts: parts,
          );
          for (int slot = timeslots.start; slot <= timeslots.end; slot++) {
            final part = SitTimetableLessonPart(
              type: lesson,
              index: slot,
            );
            parts.add(part);
            day.add(
              at: slot,
              lesson: part,
            );
          }
        }
      }
    }
    final entity = SitTimetableEntity(
      type: this,
      weeks: weeks,
    );

    void processPatch(TimetablePatchEntry patch) {
      if (patch is TimetablePatchSet) {
        for (final patch in patch.patches) {
          processPatch(patch);
        }
      } else if (patch is TimetableRemoveDayPatch) {
        for (final loc in patch.all) {
          final day = loc.resolveDay(entity);
          if (day != null) {
            day.clear();
          }
        }
      } else if (patch is TimetableMoveDayPatch) {
        final source = patch.source;
        final target = patch.target;
        final sourceDay = source.resolveDay(entity);
        final targetDay = target.resolveDay(entity);
        if (sourceDay != null && targetDay != null) {
          targetDay.replaceWith(sourceDay);
          sourceDay.clear();
        }
      } else if (patch is TimetableCopyDayPatch) {
        final source = patch.source;
        final target = patch.target;
        final sourceDay = source.resolveDay(entity);
        final targetDay = target.resolveDay(entity);
        if (sourceDay != null && targetDay != null) {
          targetDay.replaceWith(sourceDay);
        }
      } else if (patch is TimetableSwapDaysPatch) {
        final a = patch.a;
        final b = patch.b;
        final aDay = a.resolveDay(entity);
        final bDay = b.resolveDay(entity);
        if (aDay != null && bDay != null) {
          aDay.swap(bDay);
        }
      }
    }

    for (final patch in patches) {
      processPatch(patch);
    }

    if (kDebugMode) {
      for (final week in entity.weeks) {
        for (final day in week.days) {
          assert(day.parent == week);
          for (final slot in day.timeslot2LessonSlot) {
            assert(slot.parent == day);
            for (final lessonPart in slot.lessons) {
              assert(lessonPart.type.parts.contains(lessonPart));
              assert(lessonPart.type.startTime.inTheSameDay(day.date));
            }
          }
        }
      }
    }
    return entity;
  }
}
