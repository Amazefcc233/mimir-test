import 'package:hive/hive.dart';
import 'package:mimir/session/sc.dart';
import 'package:mimir/session/sso/session.dart';

import 'cache/detail.dart';
import 'cache/list.dart';
import 'cache/score.dart';
import 'service/detail.dart';
import 'service/join.dart';
import 'service/list.dart';
import 'service/score.dart';
import 'storage/detail.dart';
import 'storage/list.dart';
import 'storage/score.dart';

class Class2ndInit {
  static late ScSession session;
  static late ScActivityListCache scActivityListService;
  static late ScActivityDetailCache scActivityDetailService;
  static late ScScoreCache scScoreService;
  static late ScJoinActivityService scJoinActivityService;

  static void init({
    required SsoSession ssoSession,
    required Box<dynamic> box,
  }) {
    session = ScSession(ssoSession);
    scActivityListService = ScActivityListCache(
      from: ScActivityListService(session),
      to: ScActivityListStorage(box),
      expiration: const Duration(minutes: 30),
    );
    scActivityDetailService = ScActivityDetailCache(
      from: ScActivityDetailService(session),
      to: ScActivityDetailStorage(box),
      expiration: const Duration(days: 180),
    );
    scScoreService = ScScoreCache(
      from: ScScoreService(session),
      to: ScScoreStorage(box),
      expiration: const Duration(minutes: 5),
    );
    scJoinActivityService = ScJoinActivityService(session);
  }
}
