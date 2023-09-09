import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mimir/credential/symbol.dart';
import 'package:mimir/design/widgets/app.dart';
import 'package:mimir/school/class2nd/widgets/summary.dart';
import 'package:rettulf/rettulf.dart';

import 'entity/score.dart';
import "i18n.dart";
import 'init.dart';

class Class2ndAppCard extends StatefulWidget {
  const Class2ndAppCard({super.key});

  @override
  State<Class2ndAppCard> createState() => _Class2ndAppCardState();
}

class _Class2ndAppCardState extends State<Class2ndAppCard> {
  ScScoreSummary? summary;

  @override
  void initState() {
    super.initState();
    onRefresh();
  }

  void onRefresh() {
    Class2ndInit.scoreService.getScoreSummary().then((value) {
      if (summary != value) {
        summary = value;
        if (!mounted) return;
        setState(() {});
      }
    });
  }

  ScScoreSummary getTargetScore() {
    final admissionYear = int.tryParse(context.auth.credential?.account.substring(0, 2) ?? "") ?? 2000;
    return calcTargetScore(admissionYear);
  }

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: i18n.title.text(),
      view: summary == null
          ? const SizedBox()
          : Class2ndScoreSummeryCard(
              targetScore: getTargetScore(),
              summery: summary,
            ),
      leftActions: [
        FilledButton.icon(
          onPressed: () async {
            await context.push("/class2nd/activity");
          },
          label: "Activity".text(),
          icon: const Icon(Icons.local_activity_outlined),
        ),
        OutlinedButton(
          onPressed: () async {
            await context.push("/class2nd/attended");
          },
          child: "Attended".text(),
        )
      ],
      rightActions: [
        IconButton(
          onPressed: () async {},
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }
}
