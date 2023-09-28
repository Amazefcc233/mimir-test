import 'package:flutter/material.dart';
import 'package:mimir/credential/widgets/oa_scope.dart';
import 'package:mimir/design/widgets/common.dart';
import 'package:mimir/school/class2nd/entity/list.dart';
import 'package:rettulf/rettulf.dart';

import '../entity/attended.dart';
import '../init.dart';
import '../widgets/attended.dart';
import '../widgets/summary.dart';
import '../i18n.dart';

class AttendedActivityPage extends StatefulWidget {
  const AttendedActivityPage({super.key});

  @override
  State<AttendedActivityPage> createState() => _AttendedActivityPageState();
}

class _AttendedActivityPageState extends State<AttendedActivityPage> {
  List<Class2ndAttendedActivity>? attended = Class2ndInit.scoreStorage.attendedList;
  final _scrollController = ScrollController();
  final $attended = Class2ndInit.scoreStorage.listenAttendedList();
  late bool isFetching = false;

  @override
  void initState() {
    super.initState();
    refresh(active: false);
    $attended.addListener(onAttendedChanged);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    $attended.removeListener(onAttendedChanged);
    super.dispose();
  }

  void onAttendedChanged() {
    setState(() {
      attended = Class2ndInit.scoreStorage.attendedList;
    });
  }

  Future<void> refresh({required bool active}) async {
    if (!mounted) return;
    setState(() => isFetching = true);
    try {
      final applicationList = await Class2ndInit.scoreService.fetchActivityApplicationList();
      final scoreItemList = await Class2ndInit.scoreService.fetchScoreItemList();
      final attended = applicationList.map((application) {
        // 对于每一次申请, 找到对应的加分信息
        final relatedScoreItems = scoreItemList.where((e) => e.activityId == application.activityId).toList();
        // TODO: 潜在的 BUG，可能导致得分页面出现重复项。
        return Class2ndAttendedActivity(
          applyId: application.applyId,
          activityId: application.activityId,
          // because the application.title might have trailing ellipsis
          title: relatedScoreItems.firstOrNull?.name ?? application.title,
          time: application.time,
          category: application.category,
          status: application.status,
          points: relatedScoreItems.fold<double>(0.0, (points, item) => points + item.points),
          honestyPoints: relatedScoreItems.fold<double>(0.0, (points, item) => points + item.honestyPoints),
        );
      }).toList();
      Class2ndInit.scoreStorage.attendedList = attended;
      if (!mounted) return;
      setState(() => isFetching = false);
    } catch (error, stackTrace) {
      debugPrint(error.toString());
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() => isFetching = false);
    }
  }

  Class2ndScoreSummary getTargetScore() {
    final admissionYear = int.tryParse(context.auth.credentials?.account.substring(0, 2) ?? "") ?? 2000;
    return getTargetScoreOf(admissionYear: admissionYear);
  }

  @override
  Widget build(BuildContext context) {
    final activities = attended;
    return Scaffold(
      body: RefreshIndicator(
        triggerMode: RefreshIndicatorTriggerMode.anywhere,
        onRefresh: () async {
          if (!isFetching) {
            await refresh(active: true);
          }
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              title: i18n.attended.title.text(),
              bottom: isFetching
                  ? const PreferredSize(
                      preferredSize: Size.fromHeight(4),
                      child: LinearProgressIndicator(),
                    )
                  : null,
            ),
            if (activities != null)
              if (activities.isEmpty)
                SliverToBoxAdapter(
                  child: LeavingBlank(
                    icon: Icons.inbox_outlined,
                    desc: i18n.noAttendedActivities,
                  ),
                )
              else
                SliverList.builder(
                  itemCount: activities.length,
                  itemBuilder: (ctx, i) {
                    final activity = activities[i];
                    return AttendedActivityCard(activity).hero(activity.applyId);
                  },
                ),
          ],
        ),
      ),
    );
  }
}