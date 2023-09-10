import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mimir/design/widgets/app.dart';
import 'package:rettulf/rettulf.dart';

import "i18n.dart";

class OaAnnounceAppCard extends StatefulWidget {
  const OaAnnounceAppCard({super.key});

  @override
  State<OaAnnounceAppCard> createState() => _OaAnnounceAppCardState();
}

class _OaAnnounceAppCardState extends State<OaAnnounceAppCard> {
  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: i18n.title.text(),
      leftActions: [
        FilledButton(
          onPressed: () {
            context.push("/oa-announce");
          },
          child: "See all".text(),
        ),
      ],
    );
  }
}
