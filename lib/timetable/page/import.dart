import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mimir/credential/widgets/oa_scope.dart';
import 'package:mimir/design/adaptive/foundation.dart';
import 'package:mimir/design/animation/animated.dart';
import 'package:mimir/design/widgets/connectivity_checker.dart';
import 'package:mimir/design/adaptive/dialog.dart';
import 'package:mimir/school/entity/school.dart';
import 'package:mimir/school/utils.dart';
import 'package:mimir/school/widgets/selector.dart';
import 'package:mimir/timetable/utils.dart';
import 'package:rettulf/rettulf.dart';

import '../i18n.dart';
import '../entity/timetable.dart';
import '../init.dart';
import '../widgets/meta_editor.dart';

enum ImportStatus {
  none,
  importing,
  end,
  failed;
}

class ImportTimetablePage extends StatefulWidget {
  const ImportTimetablePage({super.key});

  @override
  State<ImportTimetablePage> createState() => _ImportTimetablePageState();
}

class _ImportTimetablePageState extends State<ImportTimetablePage> {
  bool canImport = false;
  var _status = ImportStatus.none;
  late SemesterInfo initial = () {
    final now = DateTime.now();
    return (
      year: now.month >= 9 ? now.year : now.year - 1,
      semester: now.month >= 3 && now.month <= 7 ? Semester.term2 : Semester.term1,
    );
  }();
  late SemesterInfo selected = initial;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final isImporting = _status == ImportStatus.importing;
    return Scaffold(
      appBar: AppBar(
        title: i18n.import.title.text(),
        actions: [
          CupertinoButton(onPressed: importFromFile, child: i18n.import.fromFileBtn.text()),
        ],
        bottom: !isImporting
            ? null
            : const PreferredSize(
                preferredSize: Size.fromHeight(4),
                child: LinearProgressIndicator(),
              ),
      ),
      body: (canImport
              ? buildImportPage(key: const ValueKey("Import Timetable"))
              : buildConnectivityChecker(context, const ValueKey("Connectivity Checker")))
          .animatedSwitched(),
    );
  }

  Future<void> importFromFile() async {
    try {
      final id2timetable = await importTimetableFromFile();
      if (id2timetable == null) return;
      if (!mounted) return;
      context.pop(id2timetable);
    } catch (err, stackTrace) {
      // TODO: Handle permission error
      debugPrint(err.toString());
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      context.showSnackBar("Format Error. Please select a timetable file.".text());
    }
  }

  Widget buildConnectivityChecker(BuildContext ctx, Key? key) {
    return ConnectivityChecker(
      key: key,
      iconSize: ctx.isPortrait ? 180 : 120,
      initialDesc: i18n.import.connectivityCheckerDesc,
      check: TimetableInit.network.checkConnectivity,
      onConnected: () {
        if (!mounted) return;
        setState(() {
          canImport = true;
        });
      },
    );
  }

  Widget buildTip(BuildContext ctx) {
    final tip = switch (_status) {
      ImportStatus.none => i18n.import.selectSemesterTip,
      ImportStatus.importing => i18n.import.importing,
      ImportStatus.end => i18n.import.endTip,
      ImportStatus.failed => i18n.import.failedTip,
    };
    return tip
        .text(
          key: ValueKey(_status),
          style: ctx.textTheme.titleLarge,
        )
        .animatedSwitched();
  }

  Widget buildImportPage({Key? key}) {
    return [
      buildTip(context).padSymmetric(v: 30),
      SemesterSelector(
        showNextYear: true,
        baseYear: getAdmissionYearFromStudentId(context.auth.credentials?.account),
        initial: initial,
        onSelected: (newSelection) {
          setState(() {
            selected = newSelection;
          });
        },
      ).padSymmetric(v: 30),
      buildImportButton(context).padAll(24),
    ].column(key: key, maa: MainAxisAlignment.center, caa: CrossAxisAlignment.center);
  }

  Future<({int id, SitTimetable timetable})?> handleTimetableData(
      BuildContext ctx, SitTimetable timetable, int year, Semester semester) async {
    final defaultName = i18n.import.defaultName(semester.localized(), year.toString(), (year + 1).toString());
    DateTime defaultStartDate;
    if (semester == Semester.term1) {
      defaultStartDate = findFirstWeekdayInCurrentMonth(DateTime(year, 9), DateTime.monday);
    } else {
      defaultStartDate = findFirstWeekdayInCurrentMonth(DateTime(year + 1, 2), DateTime.monday);
    }
    final meta = TimetableMeta(
      name: defaultName,
      semester: semester,
      startDate: defaultStartDate,
      schoolYear: year,
    );
    final newMeta = await ctx.show$Sheet$<TimetableMeta>(
      (ctx) => MetaEditor(meta: meta).padOnly(b: MediaQuery.of(ctx).viewInsets.bottom),
      dismissible: false,
    );
    if (newMeta != null) {
      timetable = timetable.copyWithMeta(newMeta);
      final id = addNewTimetable(timetable);
      return (id: id, timetable: timetable);
    }
    return null;
  }

  Widget buildImportButton(BuildContext ctx) {
    return FilledButton(
      onPressed: _status == ImportStatus.importing ? null : _onImport,
      child: i18n.import.tryImportBtn
          .text(
            style: TextStyle(fontSize: ctx.textTheme.titleLarge?.fontSize),
          )
          .padAll(12),
    );
  }

  void _onImport() async {
    setState(() {
      _status = ImportStatus.importing;
    });
    try {
      final (:year, :semester) = selected;
      final timetable = await TimetableInit.service.getTimetable(year, semester);
      if (!mounted) return;
      setState(() {
        _status = ImportStatus.end;
      });
      final id2timetable = await handleTimetableData(context, timetable, year, semester);
      if (!mounted) return;
      context.pop(id2timetable);
    } catch (e, stackTrace) {
      if (e is ParallelWaitError) {
        final inner = e.errors.$1 as AsyncError;
        debugPrint(inner.toString());
        debugPrintStack(stackTrace: inner.stackTrace);
      } else {
        debugPrint(e.toString());
        debugPrintStack(stackTrace: stackTrace);
      }
      setState(() {
        _status = ImportStatus.failed;
      });
      if (!mounted) return;
      await context.showTip(title: i18n.import.failed, desc: i18n.import.failedDesc, ok: i18n.ok);
    } finally {
      if (_status == ImportStatus.importing) {
        setState(() {
          _status = ImportStatus.end;
        });
      }
    }
  }
}

DateTime findFirstWeekdayInCurrentMonth(DateTime current, int weekday) {
  // Calculate the first day of the current month while keeping the same year.
  DateTime firstDayOfMonth = DateTime(current.year, current.month, 1);

  // Calculate the difference in days between the first day of the current month
  // and the desired weekday.
  int daysUntilWeekday = (weekday - firstDayOfMonth.weekday + 7) % 7;

  // Calculate the date of the first occurrence of the desired weekday in the current month.
  DateTime firstWeekdayInMonth = firstDayOfMonth.add(Duration(days: daysUntilWeekday));

  return firstWeekdayInMonth;
}