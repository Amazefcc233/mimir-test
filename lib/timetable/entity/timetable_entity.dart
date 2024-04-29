import 'package:copy_with_extension/copy_with_extension.dart';
import 'package:sit/l10n/time.dart';
import 'package:sit/school/entity/school.dart';
import 'package:sit/school/entity/timetable.dart';
import 'package:sit/school/utils.dart';
import 'package:sit/timetable/utils.dart';

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
  });

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

  bool isFree() {
    return days.every((day) => day.isFree());
  }

  @override
  String toString() => "$days";

  SitTimetableDay operator [](Weekday weekday) => days[weekday.index];

  operator []=(Weekday weekday, SitTimetableDay day) => days[weekday.index] = day;
}

/// Lessons in the same Timeslot.
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
    return lessons.toString();
  }
}

class SitTimetableDay {
  late final SitTimetableWeek parent;
  final int index;

  /// The Default number of lesson in one day is 11. But the length of lessons can be more.
  /// When two lessons are overlapped, it can be 12+.
  /// A Timeslot contain one or more lesson.
  final List<SitTimetableLessonSlot> timeslot2LessonSlot;

  final Set<SitCourse> associatedCourses;

  SitTimetableDay({
    required this.index,
    required this.timeslot2LessonSlot,
    required this.associatedCourses,
  }) {
    for (final lessonSlot in timeslot2LessonSlot) {
      lessonSlot.parent = this;
    }
  }

  factory SitTimetableDay.$11slots(int dayIndex) {
    return SitTimetableDay(
      index: dayIndex,
      timeslot2LessonSlot: List.generate(11, (index) => SitTimetableLessonSlot(lessons: [])),
      associatedCourses: <SitCourse>{},
    );
  }

  bool isFree() {
    return timeslot2LessonSlot.every((lessonSlot) => lessonSlot.lessons.isEmpty);
  }

  void add({required SitTimetableLessonPart lesson, required int at}) {
    assert(0 <= at && at < timeslot2LessonSlot.length);
    if (0 <= at && at < timeslot2LessonSlot.length) {
      final lessonSlot = timeslot2LessonSlot[at];
      lessonSlot.lessons.add(lesson);
      associatedCourses.add(lesson.course);
    }
  }

  void clear() {
    for (final lessonSlot in timeslot2LessonSlot) {
      lessonSlot.lessons.clear();
      associatedCourses.clear();
    }
  }

  void replaceWith(SitTimetableDay other) {
    // associatedCourses
    setAssociatedCourses(other.associatedCourses);

    // timeslot2LessonSlot
    setLessonSlots(other.cloneLessonSlots());
  }

  void swap(SitTimetableDay other) {
    // associatedCourses
    final $associatedCourses = List.of(other.associatedCourses);
    other.setAssociatedCourses(associatedCourses);
    setAssociatedCourses($associatedCourses);

    // timeslot2LessonSlot
    final $timeslot2LessonSlot = other.cloneLessonSlots();
    other.setLessonSlots(cloneLessonSlots());
    setLessonSlots($timeslot2LessonSlot);
  }

  void setAssociatedCourses(Iterable<SitCourse> v) {
    associatedCourses.clear();
    associatedCourses.addAll(v);
  }

  void setLessonSlots(Iterable<SitTimetableLessonSlot> v) {
    timeslot2LessonSlot.clear();
    timeslot2LessonSlot.addAll(v);

    for (final lessonSlot in timeslot2LessonSlot) {
      lessonSlot.parent = this;
    }
  }

  List<SitTimetableLessonSlot> cloneLessonSlots() {
    return List.of(timeslot2LessonSlot.map((lessonSlot) {
      return SitTimetableLessonSlot(lessons: List.of(lessonSlot.lessons));
    }));
  }

  /// At all lessons [layer]
  Iterable<SitTimetableLessonPart> browseLessonsAt({required int layer}) sync* {
    for (final lessonSlot in timeslot2LessonSlot) {
      if (0 <= layer && layer < lessonSlot.lessons.length) {
        yield lessonSlot.lessons[layer];
      }
    }
  }

  bool hasAnyLesson() {
    for (final lessonSlot in timeslot2LessonSlot) {
      if (lessonSlot.lessons.isNotEmpty) {
        assert(associatedCourses.isNotEmpty);
        return true;
      }
    }
    return false;
  }

  @override
  String toString() => {
        "index": index,
        "timeslot2LessonSlot": timeslot2LessonSlot,
        "associatedCourses": associatedCourses,
      }.toString();
}

class SitTimetableLesson {
  /// The start index of this lesson in a [SitTimetableWeek]
  final int startIndex;

  /// The end index of this lesson in a [SitTimetableWeek]
  final int endIndex;
  final DateTime startTime;
  final DateTime endTime;

  /// A lesson may last two or more time slots.
  /// If current [SitTimetableLessonPart] is a part of the whole lesson, they all have the same [courseKey].
  final SitCourse course;

  /// How many timeslots this lesson takes.
  /// It's at least 1 timeslot.
  int get timeslotDuration => endIndex - startIndex + 1;

  SitTimetableLesson({
    required this.course,
    required this.startIndex,
    required this.endIndex,
    required this.startTime,
    required this.endTime,
  });
}

@CopyWith(skipFields: true)
class SitTimetableLessonPart {
  final SitTimetableLesson type;

  /// The start index of this lesson in a [SitTimetableWeek]
  final int index;

  final DateTime startTime;
  final DateTime endTime;

  SitCourse get course => type.course;

  const SitTimetableLessonPart({
    required this.type,
    required this.index,
    required this.startTime,
    required this.endTime,
  });

  @override
  String toString() => "[$index] $course";
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
          final thatDay = reflectWeekDayIndexToDate(
            weekIndex: week.index,
            weekday: Weekday.fromIndex(day.index),
            startDate: startDate,
          );
          final fullClassTime = course.calcBeginEndTimePoint();
          final lesson = SitTimetableLesson(
            course: course,
            startIndex: timeslots.start,
            endIndex: timeslots.end,
            startTime: thatDay.addTimePoint(fullClassTime.begin),
            endTime: thatDay.addTimePoint(fullClassTime.end),
          );
          for (int slot = timeslots.start; slot <= timeslots.end; slot++) {
            final classTime = course.calcBeginEndTimePointOfLesson(slot);
            day.add(
              at: slot,
              lesson: SitTimetableLessonPart(
                type: lesson,
                index: slot,
                startTime: thatDay.addTimePoint(classTime.begin),
                endTime: thatDay.addTimePoint(classTime.end),
              ),
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
    return entity;
  }
}