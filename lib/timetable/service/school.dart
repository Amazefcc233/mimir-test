import 'package:flutter/cupertino.dart';
import 'package:mimir/mini_apps/shared/entity/school.dart';
import 'package:mimir/network/session.dart';

import '../entity/course.dart';
import '../entity/entity.dart';

class TimetableService {
  static const _timetableUrl = 'http://jwxt.sit.edu.cn/jwglxt/kbcx/xskbcx_cxXsgrkb.html';

  final ISession session;

  TimetableService(this.session);

  static List<Course> _parseTimetable(Map<String, dynamic> json) {
    final List<dynamic> courseList = json['kbList'];

    return courseList.map((e) => Course.fromJson(e)).toList();
  }

  /// 获取课表
  Future<SitTimetable> getTimetable(SchoolYear schoolYear, Semester semester) async {
    final response = await session.request(
      _timetableUrl,
      ReqMethod.post,
      para: {'gnmkdm': 'N253508'},
      data: {
        // 学年名
        'xnm': schoolYear.toString(),
        // 学期名
        'xqm': semesterToFormField(semester)
      },
    );
    final json = response.data;
    final List<dynamic> courseList = json['kbList'];
    final rawCourses = courseList.map((e) => CourseRaw.fromJson(e)).toList();
    final timetableEntity = SitTimetable.parse(rawCourses);
    return timetableEntity;
  }
}
