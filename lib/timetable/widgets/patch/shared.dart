import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rettulf/rettulf.dart';
import 'package:sit/design/adaptive/foundation.dart';
import 'package:sit/design/adaptive/menu.dart';
import 'package:sit/design/adaptive/multiplatform.dart';
import 'package:sit/l10n/extension.dart';
import 'package:sit/qrcode/page/view.dart';
import 'package:sit/qrcode/utils.dart';
import 'package:sit/settings/dev.dart';
import 'package:sit/timetable/entity/pos.dart';
import 'package:text_scroll/text_scroll.dart';

import '../../entity/loc.dart';
import '../../entity/patch.dart';
import '../../entity/timetable.dart';
import '../../i18n.dart';
import '../../page/preview.dart';
import '../../utils.dart';
import 'swap_days.dart';
import 'copy_day.dart';
import 'move_day.dart';
import 'remove_day.dart';

class TimetableDayLocModeSwitcher extends StatelessWidget {
  final TimetableDayLocMode selected;
  final ValueChanged<TimetableDayLocMode> onSelected;

  const TimetableDayLocModeSwitcher({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<TimetableDayLocMode>(
      segments: TimetableDayLocMode.values
          .map((e) => ButtonSegment<TimetableDayLocMode>(
                value: e,
                label: e.l10n().text(),
              ))
          .toList(),
      selected: <TimetableDayLocMode>{selected},
      onSelectionChanged: (newSelection) async {
        onSelected(newSelection.first);
      },
    );
  }
}

final _lastInitialDate = StateProvider<DateTime>((ref) => DateTime.now());

class TimetableDayLocPosSelectionTile extends StatelessWidget {
  final Widget title;
  final Widget? leading;
  final TimetablePos? pos;
  final SitTimetable timetable;
  final ValueChanged<TimetablePos> onChanged;

  const TimetableDayLocPosSelectionTile({
    super.key,
    required this.title,
    this.leading,
    this.pos,
    required this.onChanged,
    required this.timetable,
  });

  @override
  Widget build(BuildContext context) {
    final pos = this.pos;
    return ListTile(
      leading: leading,
      title: title,
      subtitle: pos == null ? i18n.unspecified.text() : pos.l10n().text(),
      trailing: FilledButton(
        child: i18n.select.text(),
        onPressed: () async {
          final newPos = await selectDayInTimetable(
            context: context,
            timetable: timetable,
            initialPos: pos,
            submitLabel: i18n.select,
          );
          if (newPos == null) return;
          onChanged(newPos);
        },
      ),
    );
  }
}

class TimetableDayLocDateSelectionTile extends ConsumerWidget {
  final Widget title;
  final Widget? leading;
  final DateTime? date;
  final SitTimetable timetable;
  final ValueChanged<DateTime> onChanged;

  const TimetableDayLocDateSelectionTile({
    super.key,
    this.leading,
    required this.title,
    this.date,
    required this.onChanged,
    required this.timetable,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final date = this.date;
    return ListTile(
      leading: leading,
      title: title,
      subtitle: date == null ? i18n.unspecified.text() : context.formatYmdWeekText(date).text(),
      trailing: FilledButton(
        child: i18n.select.text(),
        onPressed: () async {
          final now = DateTime.now();
          final newDate = await showDatePicker(
            context: context,
            initialDate: date ?? ref.read(_lastInitialDate),
            currentDate: date,
            firstDate: DateTime(now.year - 4),
            lastDate: DateTime(now.year + 2),
          );
          if (newDate == null) return;
          ref.read(_lastInitialDate.notifier).state = newDate;
          onChanged(newDate);
        },
      ),
    );
  }
}

class TimetablePatchMenuAction<TPatch extends TimetablePatch> extends StatelessWidget {
  final TPatch patch;
  final SitTimetable timetable;
  final ValueChanged<TPatch> onChanged;

  const TimetablePatchMenuAction({
    super.key,
    required this.patch,
    required this.timetable,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PullDownMenuButton(itemBuilder: (ctx) {
      return [
        PullDownItem(
          icon: context.icons.preview,
          title: i18n.preview,
          onTap: () async {
            await previewTimetable(context, timetable: timetable);
          },
        ),
        if (!kIsWeb)
          if (Dev.on)
            PullDownItem(
              title: "Share QR code",
              icon: context.icons.qrcode,
              onTap: () async {
                shareTimetablePatchQrCode(context, patch);
              },
            ),
      ];
    });
  }
}

extension TimetablePatchEntryX on TimetablePatchEntry {
  Widget build({
    required BuildContext context,
    required SitTimetable timetable,
    required ValueChanged<TimetablePatch> onChanged,
  }) {
    return switch (this) {
      TimetablePatchSet() => throw UnimplementedError(),
      TimetableUnknownPatch() => ListTile(
          title: i18n.unknown.text(),
        ),
      TimetableRemoveDayPatch() => TimetableRemoveDayPatchWidget(
          patch: this as TimetableRemoveDayPatch,
          timetable: timetable,
          onChanged: onChanged,
        ),
      TimetableMoveDayPatch() => TimetableMoveDayPatchWidget(
          patch: this as TimetableMoveDayPatch,
          timetable: timetable,
          onChanged: onChanged,
        ),
      TimetableCopyDayPatch() => TimetableCopyDayPatchWidget(
          patch: this as TimetableCopyDayPatch,
          timetable: timetable,
          onChanged: onChanged,
        ),
      TimetableSwapDaysPatch() => TimetableSwapDaysPatchWidget(
          patch: this as TimetableSwapDaysPatch,
          timetable: timetable,
          onChanged: onChanged,
        ),
    };
  }
}

void shareTimetablePatchQrCode(BuildContext context, TimetablePatchEntry patch) async {
  if (kIsWeb) return;
  final qrCodeData = Uri(
    scheme: R.scheme,
    path: "timetable-patch",
    query: encodeBytesForUrl(patch.encodeByteList()),
  );
  await context.show$Sheet$(
    (context) => QrCodePage(
      title: TextScroll(switch (patch) {
        TimetablePatchSet() => patch.name,
        TimetablePatch() => patch.l10n(),
      }),
      data: qrCodeData.toString(),
    ),
  );
}