import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sit/utils/hive.dart';
import 'package:sit/storage/hive/init.dart';
import 'package:sit/school/entity/school.dart';

import '../entity/result.ug.dart';

class _K {
  static const ns = "/ug";
  static const lastSemesterInfo = "$ns/lastSemesterInfo";

  static String resultList(SemesterInfo info) => "$ns/resultList/$info";
}

class ExamResultUgStorage {
  Box get box => HiveInit.examResult;

  ExamResultUgStorage();

  List<ExamResultUg>? getResultList(SemesterInfo info) => box.safeGet<List>(_K.resultList(info))?.cast<ExamResultUg>();

  Future<void> setResultList(SemesterInfo info, List<ExamResultUg>? results) =>
      box.safePut<List>(_K.resultList(info), results);

  ValueListenable<Box> listenResultList(SemesterInfo info) => box.listenable(keys: [_K.resultList(info)]);

  SemesterInfo? get lastSemesterInfo => box.safeGet<SemesterInfo>(_K.lastSemesterInfo);

  set lastSemesterInfo(SemesterInfo? newV) => box.safePut<SemesterInfo>(_K.lastSemesterInfo, newV);

  Stream<BoxEvent> watchResultList(SemesterInfo Function() getFilter) =>
      box.watch().where((event) => event.key == _K.resultList(getFilter()));

  late final $resultListFamily = box.streamChangeProviderFamily<SemesterInfo>(
    (e, semester) => e.key == _K.resultList(semester),
  );
}
