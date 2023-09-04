import 'package:hive/hive.dart';
import 'package:mimir/mini_apps/edu_email/service/email.dart';

import 'storage/email.dart';

class EduEmailInit {
  static late EduEmailStorage storage;
  static late MailService service;

  static Future<void> init({
    required Box<dynamic> box,
  }) async {
    storage = EduEmailStorage(box);
    service = MailService();
  }
}
