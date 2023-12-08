import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sit/design/widgets/app.dart';
import 'package:sit/school/entity/school.dart';
import 'package:sit/school/event.dart';
import 'package:sit/school/exam_result/init.dart';
import 'package:sit/school/exam_result/page/evaluation.dart';
import 'package:sit/school/exam_result/widgets/ug.dart';
import 'package:sit/settings/settings.dart';
import 'package:sit/utils/async_event.dart';
import 'package:rettulf/rettulf.dart';
import 'package:sit/utils/guard_launch.dart';
import 'package:universal_platform/universal_platform.dart';

import 'entity/result.ug.dart';
import "i18n.dart";

const _recentLength = 2;

class ExamResultUgAppCard extends StatefulWidget {
  const ExamResultUgAppCard({super.key});

  @override
  State<ExamResultUgAppCard> createState() => _ExamResultUgAppCardState();
}

class _ExamResultUgAppCardState extends State<ExamResultUgAppCard> {
  List<ExamResultUg>? resultList;
  late final EventSubscription $refreshEvent;
  late final StreamSubscription $resultList;
  late final currentSemester = estimateCurrentSemester();

  @override
  void initState() {
    super.initState();
    $refreshEvent = schoolEventBus.addListener(() async {
      refresh();
    });
    $resultList = ExamResultInit.ugStorage.watchResultList(() => currentSemester).listen((event) {
      refresh();
    });
    refresh();
  }

  @override
  void dispose() {
    $refreshEvent.cancel();
    $resultList.cancel();
    super.dispose();
  }

  void refresh() {
    setState(() {
      resultList = ExamResultInit.ugStorage.getResultList(currentSemester);
    });
  }

  @override
  Widget build(BuildContext context) {
    final resultList = this.resultList;
    return AppCard(
      title: i18n.title.text(),
      view: resultList == null ? null : buildRecentResults(resultList),
      leftActions: [
        FilledButton.icon(
          onPressed: () async {
            await context.push("/exam-result/ug");
          },
          icon: const Icon(Icons.fact_check),
          label: i18n.check.text(),
        ),
        OutlinedButton(
          onPressed: () async {
            if (UniversalPlatform.isDesktop) {
              await guardLaunchUrl(context, teacherEvaluationUri);
            } else {
              await context.push("/teacher-eval");
            }
          },
          child: i18n.teacherEval.text(),
        )
      ],
    );
  }

  Widget? buildRecentResults(List<ExamResultUg> resultList) {
    if (resultList.isEmpty) return null;
    resultList.sort((a, b) => -ExamResultUg.compareByTime(a, b));
    final results = resultList.sublist(0, min(_recentLength, resultList.length));
    return Settings.school.examResult.listenAppCardShowResultDetails() >>
        (ctx, _) {
          final showDetails = Settings.school.examResult.appCardShowResultDetails;
          return results
              .map((result) => ExamResultUgCard(
                    result,
                    showDetails: showDetails,
                    elevated: true,
                  ))
              .toList()
              .column();
        };
  }
}
