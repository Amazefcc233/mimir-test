// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timetable.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SitTimetable _$SitTimetableFromJson(Map<String, dynamic> json) => SitTimetable(
      weeks: (json['weeks'] as List<dynamic>)
          .map((e) => e == null ? null : SitTimetableWeek.fromJson(e as Map<String, dynamic>))
          .toList(),
      courseKey2Entity: (json['courseKey2Entity'] as List<dynamic>)
          .map((e) => SitCourse.fromJson(e as Map<String, dynamic>))
          .toList(),
      courseKeyCounter: json['courseKeyCounter'] as int,
      name: json['name'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      schoolYear: json['schoolYear'] as int,
      semester: $enumDecode(_$SemesterEnumMap, json['semester']),
    );

Map<String, dynamic> _$SitTimetableToJson(SitTimetable instance) => <String, dynamic>{
      'name': instance.name,
      'startDate': instance.startDate.toIso8601String(),
      'schoolYear': instance.schoolYear,
      'semester': _$SemesterEnumMap[instance.semester]!,
      'weeks': instance.weeks,
      'courseKey2Entity': instance.courseKey2Entity,
      'courseKeyCounter': instance.courseKeyCounter,
    };

const _$SemesterEnumMap = {
  Semester.all: 'all',
  Semester.term1: 'term1',
  Semester.term2: 'term2',
};

SitTimetableWeek _$SitTimetableWeekFromJson(Map<String, dynamic> json) => SitTimetableWeek(
      (json['days'] as List<dynamic>).map((e) => SitTimetableDay.fromJson(e as Map<String, dynamic>)).toList(),
    );

Map<String, dynamic> _$SitTimetableWeekToJson(SitTimetableWeek instance) => <String, dynamic>{
      'days': instance.days,
    };

SitTimetableDay _$SitTimetableDayFromJson(Map<String, dynamic> json) => SitTimetableDay(
      (json['timeslots2Lessons'] as List<dynamic>)
          .map((e) => (e as List<dynamic>).map((e) => SitTimetableLesson.fromJson(e as Map<String, dynamic>)).toList())
          .toList(),
    );

Map<String, dynamic> _$SitTimetableDayToJson(SitTimetableDay instance) => <String, dynamic>{
      'timeslots2Lessons': instance.timeslots2Lessons,
    };

SitTimetableLesson _$SitTimetableLessonFromJson(Map<String, dynamic> json) => SitTimetableLesson(
      json['startIndex'] as int,
      json['endIndex'] as int,
      json['courseKey'] as int,
    );

Map<String, dynamic> _$SitTimetableLessonToJson(SitTimetableLesson instance) => <String, dynamic>{
      'startIndex': instance.startIndex,
      'endIndex': instance.endIndex,
      'courseKey': instance.courseKey,
    };

SitCourse _$SitCourseFromJson(Map<String, dynamic> json) => SitCourse(
      courseKey: json['courseKey'] as int,
      courseName: json['courseName'] as String,
      courseCode: json['courseCode'] as String,
      classCode: json['classCode'] as String,
      campus: json['campus'] as String,
      place: json['place'] as String,
      iconName: json['iconName'] as String,
      weekIndices: _weekIndicesFromJson(json['weekIndices'] as List),
      timeslots: rangeFromString(json['timeslots'] as String),
      courseCredit: (json['courseCredit'] as num).toDouble(),
      creditHour: json['creditHour'] as int,
      dayIndex: json['dayIndex'] as int,
      teachers: (json['teachers'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$SitCourseToJson(SitCourse instance) => <String, dynamic>{
      'courseKey': instance.courseKey,
      'courseName': instance.courseName,
      'courseCode': instance.courseCode,
      'classCode': instance.classCode,
      'campus': instance.campus,
      'place': instance.place,
      'iconName': instance.iconName,
      'weekIndices': _weekIndicesToJson(instance.weekIndices),
      'timeslots': rangeToString(instance.timeslots),
      'courseCredit': instance.courseCredit,
      'creditHour': instance.creditHour,
      'dayIndex': instance.dayIndex,
      'teachers': instance.teachers,
    };
