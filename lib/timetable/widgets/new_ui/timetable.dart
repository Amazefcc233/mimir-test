import 'package:flutter/widgets.dart';
import 'package:mimir/design/animation/animated.dart';
import 'package:rettulf/rettulf.dart';

import '../../entity/course.dart';
import '../../entity/entity.dart';
import '../../entity/pos.dart';
import '../../events.dart';
import 'daily.dart';
import 'header.dart';
import 'weekly.dart';

export 'daily.dart';

class TimetableViewer extends StatefulWidget {
  final ScrollController? scrollController;
  final SitTimetable timetable;

  final ValueNotifier<DisplayMode> $displayMode;

  final ValueNotifier<TimetablePos> $currentPos;

  const TimetableViewer({
    required this.timetable,
    required this.$displayMode,
    required this.$currentPos,
    super.key,
    this.scrollController,
  });

  @override
  State<TimetableViewer> createState() => _TimetableViewerState();
}

class _TimetableViewerState extends State<TimetableViewer> {
  SitTimetable get timetable => widget.timetable;

  @override
  Widget build(BuildContext context) {
    return [
      buildTimetableBody(context),
      buildTableHeader(context),
    ].stack();
  }

  Widget buildTimetableBody(BuildContext ctx) {
    return widget.$displayMode >>
        (ctx, mode) => (mode == DisplayMode.daily
                    ? DailyTimetable(
                        scrollController: widget.scrollController,
                        $currentPos: widget.$currentPos,
                        timetable: timetable,
                      )
                    : WeeklyTimetable(
                        scrollController: widget.scrollController,
                        $currentPos: widget.$currentPos,
                        timetable: timetable,
                      ))
                .animatedSwitched(
              d: const Duration(milliseconds: 300),
            );
  }

  Widget buildTableHeader(BuildContext ctx) {
    return widget.$currentPos >>
        (ctx, cur) => TimetableHeader(
            currentWeek: cur.week,
            selectedDay: cur.day,
            startDate: timetable.startDate,
            onDayTap: (selectedDay) {
              if (widget.$displayMode.value == DisplayMode.daily) {
                eventBus.fire(JumpToPosEvent(TimetablePos(week: cur.week, day: selectedDay)));
              } else {
                widget.$currentPos.value = TimetablePos(week: cur.week, day: selectedDay);
              }
            });
  }
}
