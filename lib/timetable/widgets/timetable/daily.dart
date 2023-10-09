import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:mimir/design/widgets/card.dart';
import 'package:mimir/school/entity/school.dart';
import 'package:mimir/timetable/platte.dart';
import 'package:mimir/timetable/widgets/free.dart';
import 'package:rettulf/rettulf.dart';

import '../../entity/timetable.dart';
import '../../events.dart';
import '../../utils.dart';
import '../style.dart';
import '../../entity/pos.dart';
import 'header.dart';

class DailyTimetable extends StatefulWidget {
  final ScrollController? scrollController;
  final SitTimetable timetable;

  final ValueNotifier<TimetablePos> $currentPos;

  @override
  State<StatefulWidget> createState() => DailyTimetableState();

  const DailyTimetable({
    super.key,
    required this.timetable,
    required this.$currentPos,
    this.scrollController,
  });
}

class DailyTimetableState extends State<DailyTimetable> {
  SitTimetable get timetable => widget.timetable;

  TimetablePos get currentPos => widget.$currentPos.value;

  set currentPos(TimetablePos newValue) => widget.$currentPos.value = newValue;

  /// 翻页控制
  late PageController _pageController;

  int pos2PageOffset(TimetablePos pos) => (pos.week - 1) * 7 + pos.day - 1;

  TimetablePos page2Pos(int page) {
    final week = page ~/ 7 + 1;
    final day = page % 7 + 1;
    return TimetablePos(week: week, day: day);
  }

  late StreamSubscription<JumpToPosEvent> $jumpToPos;

  @override
  void initState() {
    super.initState();
    final pos = timetable.locate(DateTime.now());
    _pageController = PageController(initialPage: pos2PageOffset(pos))..addListener(onPageChange);
    $jumpToPos = eventBus.on<JumpToPosEvent>().listen((event) {
      jumpTo(event.where);
    });
  }

  @override
  void dispose() {
    $jumpToPos.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      final targetOffset = pos2PageOffset(currentPos);
      final currentOffset = _pageController.page?.round() ?? targetOffset;
      if (currentOffset != targetOffset) {
        _pageController.jumpToPage(targetOffset);
      }
    });
    return [
      widget.$currentPos >>
          (ctx, cur) => TimetableHeader(
                selectedDay: cur.day,
                currentWeek: cur.week,
                startDate: timetable.startDate,
                onDayTap: (selectedDay) {
                  eventBus.fire(JumpToPosEvent(TimetablePos(week: cur.week, day: selectedDay)));
                },
              ),
      PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.horizontal,
        itemCount: 20 * 7,
        itemBuilder: (_, int index) {
          int weekIndex = index ~/ 7;
          int dayIndex = index % 7;
          final todayPos = timetable.locate(DateTime.now());
          return _OneDayPage(
            scrollController: widget.scrollController,
            timetable: timetable,
            todayPos: todayPos,
            weekIndex: weekIndex,
            dayIndex: dayIndex,
          );
        },
      ).expanded(),
    ].column();
  }

  void onPageChange() {
    setState(() {
      final page = (_pageController.page ?? 0).round();
      final newPos = page2Pos(page);
      if (currentPos != newPos) {
        currentPos = newPos;
      }
    });
  }

  void jumpTo(TimetablePos pos) {
    if (_pageController.hasClients) {
      final targetOffset = pos2PageOffset(pos);
      final currentPos = _pageController.page ?? targetOffset;
      final distance = (targetOffset - currentPos).abs();
      _pageController.animateToPage(
        targetOffset,
        duration: calcuSwitchAnimationDuration(distance),
        curve: Curves.fastEaseInToSlowEaseOut,
      );
    }
  }
}

class _OneDayPage extends StatefulWidget {
  final ScrollController? scrollController;
  final SitTimetable timetable;
  final TimetablePos todayPos;
  final int weekIndex;
  final int dayIndex;

  const _OneDayPage({
    super.key,
    required this.timetable,
    required this.todayPos,
    required this.weekIndex,
    required this.dayIndex,
    this.scrollController,
  });

  @override
  State<_OneDayPage> createState() => _OneDayPageState();
}

class _OneDayPageState extends State<_OneDayPage> with AutomaticKeepAliveClientMixin {
  SitTimetable get timetable => widget.timetable;

  /// Cache the who page to avoid expensive rebuilding.
  Widget? _cached;
  Size? lastSize;

  @override
  Widget build(BuildContext context) {
    final size = context.mediaQuery.size;
    if (lastSize != size) {
      _cached = null;
      lastSize = size;
    }
    super.build(context);
    final cache = _cached;
    if (cache != null) {
      return cache;
    } else {
      final res = buildPage(context);
      _cached = res;
      return res;
    }
  }

  Widget buildPage(BuildContext ctx) {
    int weekIndex = widget.weekIndex;
    int dayIndex = widget.dayIndex;
    final week = timetable.weeks[weekIndex];
    if (week == null) {
      return FreeDayTip(
        timetable: timetable,
        todayPos: widget.todayPos,
        weekIndex: weekIndex,
        dayIndex: dayIndex,
      );
    } else {
      final day = week.days[dayIndex];
      if (!day.hasAnyLesson()) {
        return FreeDayTip(
          timetable: timetable,
          todayPos: widget.todayPos,
          weekIndex: weekIndex,
          dayIndex: dayIndex,
        );
      } else {
        final slotCount = day.timeslots2Lessons.length;
        final builder = _RowBuilder();
        for (int timeslot = 0; timeslot < slotCount; timeslot++) {
          builder.add(timeslot, buildLessonsInTimeslot(ctx, day.timeslots2Lessons[timeslot], timeslot));
        }
        // Since the course list is small, no need to use [ListView.builder].
        return ListView(
          controller: widget.scrollController,
          children: builder.build(),
        );
      }
    }
  }

  Widget? buildLessonsInTimeslot(BuildContext ctx, List<SitTimetableLesson> lessonsInSlot, int timeslot) {
    if (lessonsInSlot.isEmpty) {
      return null;
    } else if (lessonsInSlot.length == 1) {
      final lesson = lessonsInSlot[0];
      return timetable.buildSingleLesson(ctx, lesson, timeslot);
    } else {
      return LessonOverlapGroup(lessonsInSlot, timeslot, timetable);
    }
  }

  @override
  bool get wantKeepAlive => true;
}

class LessonCard extends StatelessWidget {
  final SitTimetableLesson lesson;
  final SitCourse course;
  final List<SitCourse> courseKey2Entity;
  final Color color;

  const LessonCard({
    super.key,
    required this.lesson,
    required this.course,
    required this.courseKey2Entity,
    required this.color,
  });

  static const iconSize = 45.0;

  @override
  Widget build(BuildContext context) {
    final Widget courseIcon = Image.asset(
      CourseCategory.iconPathOf(iconName: course.iconName),
      width: iconSize,
      height: iconSize,
    );
    return FilledCard(
      margin: const EdgeInsets.all(8),
      color: color,
      child: ListTile(
        leading: courseIcon,
        title: AutoSizeText(
          course.courseName,
          maxLines: 1,
        ),
        subtitle: [
          Text(beautifyPlace(course.place), softWrap: true, overflow: TextOverflow.ellipsis),
          course.teachers.join(', ').text(),
        ].column(caa: CrossAxisAlignment.start),
      ),
    );
  }
}

extension _LessonCardEx on SitTimetable {
  Widget buildSingleLesson(BuildContext context, SitTimetableLesson lesson, int timeslot) {
    final course = courseKey2Entity[lesson.courseKey];
    final color = TimetableStyle.of(context)
        .platte
        .resolveColor(course)
        .byTheme(context.theme)
        .harmonizeWith(context.colorScheme.primary);
    final classTime = course.buildingTimetable[timeslot];
    return [
      _buildClassTimeCard(color, classTime),
      LessonCard(
        lesson: lesson,
        course: course,
        courseKey2Entity: courseKey2Entity,
        color: color,
      ).expanded()
    ].row();
  }
}

Widget _buildClassTimeCard(Color color, ClassTime classTime) {
  return ElevatedText(
    color: color,
    margin: 10,
    child: [
      classTime.begin.toStringPrefixed0().text(style: const TextStyle(fontWeight: FontWeight.bold)),
      SizedBox(height: 5.h),
      classTime.end.toStringPrefixed0().text(),
    ].column(),
  );
}

class LessonOverlapGroup extends StatelessWidget {
  final List<SitTimetableLesson> lessonsInSlot;
  final int timeslot;
  final SitTimetable timetable;

  const LessonOverlapGroup(this.lessonsInSlot, this.timeslot, this.timetable, {super.key});

  @override
  Widget build(BuildContext context) {
    if (lessonsInSlot.isEmpty) return const SizedBox();
    final List<Widget> all = [];
    ClassTime? classTime;
    for (int lessonIndex = 0; lessonIndex < lessonsInSlot.length; lessonIndex++) {
      final lesson = lessonsInSlot[lessonIndex];
      final course = timetable.courseKey2Entity[lesson.courseKey];
      final color = TimetableStyle.of(context).platte.resolveColor(course).byTheme(context.theme);
      classTime = course.buildingTimetable[timeslot];
      final row = LessonCard(
        lesson: lesson,
        course: course,
        courseKey2Entity: timetable.courseKey2Entity,
        color: color,
      );
      all.add(row);
    }
    // [classTime] must be nonnull.
    // TODO: Color for class overlap.
    return OutlinedCard(
      child: [
        _buildClassTimeCard(TimetableStyle.of(context).platte.colors[0].byTheme(context.theme), classTime!),
        all.column().expanded(),
      ].row().padAll(3),
    );
  }
}

enum _RowBuilderState {
  row,
  divider,
  none;
}

class _RowBuilder {
  final List<Widget> _rows = [];
  _RowBuilderState lastAdded = _RowBuilderState.none;

  void add(int index, Widget? row) {
    // WOW! MEAL TIME!
    // For each four classes, there's a meal.
    if (index != 0 && index % 4 == 0 && lastAdded != _RowBuilderState.divider) {
      _rows.add(const Divider(thickness: 2));
      lastAdded = _RowBuilderState.divider;
    }
    if (row != null) {
      _rows.add(row);
      lastAdded = _RowBuilderState.row;
    }
  }

  List<Widget> build() {
    // Remove surplus dividers.
    for (int i = _rows.length - 1; 0 <= i; i--) {
      if (_rows[i] is Divider) {
        _rows.removeLast();
      } else {
        break;
      }
    }
    return _rows;
  }
}

class ElevatedText extends StatelessWidget {
  final Widget child;
  final Color color;
  final double margin;

  const ElevatedText({
    super.key,
    required this.color,
    required this.margin,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return FilledCard(
      color: color,
      child: child.padAll(margin),
    );
  }
}