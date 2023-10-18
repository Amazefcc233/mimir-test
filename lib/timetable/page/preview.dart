import 'package:flutter/material.dart';
import 'package:rettulf/rettulf.dart';

import '../entity/display.dart';
import '../entity/timetable.dart';
import '../widgets/style.dart';
import '../entity/pos.dart';
import '../widgets/timetable/board.dart';

// TODO: new view page
/// There is no need to persist a preview after activity destroyed.
class TimetablePreviewPage extends StatefulWidget {
  final SitTimetable timetable;

  const TimetablePreviewPage({
    super.key,
    required this.timetable,
  });

  @override
  State<StatefulWidget> createState() => _TimetablePreviewPageState();
}

class _TimetablePreviewPageState extends State<TimetablePreviewPage> {
  final $displayMode = ValueNotifier(DisplayMode.weekly);
  late final $currentPos = ValueNotifier(widget.timetable.locate(DateTime.now()));
  final scrollController = ScrollController();
  late SitTimetableEntity timetable;

  @override
  void dispose() {
    $displayMode.dispose();
    $currentPos.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    timetable = widget.timetable.resolve();
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: widget.timetable.name.text(
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz_rounded),
            onPressed: () {
              $displayMode.value = $displayMode.value.toggle();
            },
          )
        ],
      ),
      body: TimetableStyleProv(
        builder: (ctx, style) => TimetableBoard(
          timetable: timetable,
          $displayMode: $displayMode,
          $currentPos: $currentPos,
        ),
      ),
    );
  }
}
