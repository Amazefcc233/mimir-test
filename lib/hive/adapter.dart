import 'package:mimir/credential/symbol.dart';
import 'package:mimir/mini_apps/symbol.dart';

import 'adapter/color.dart';
import 'adapter/size.dart';
import 'adapter/version.dart';
import 'using.dart';
import 'package:mimir/entities.dart';

class HiveAdapter {
  HiveAdapter._();

  static void registerAll() {
    ~CourseAdapter();
    ~BalanceAdapter();
    ~LibrarySearchHistoryItemAdapter();
    ~TimetableMetaLegacyAdapter();
    ~VersionAdapter();
    ~SizeAdapter();
    ~ColorAdapter();
    // Activity
    ~ActivityDetailAdapter();
    ~ActivityAdapter();
    ~ScScoreSummaryAdapter();
    ~ScActivityApplicationAdapter();
    ~ScScoreItemAdapter();
    ~ActivityTypeAdapter();
    // Exam Arrangement
    ~ExamEntryAdapter();
    // OA Announcement
    ~AnnounceDetailAdapter();
    ~AnnounceCatalogueAdapter();
    ~AnnounceRecordAdapter();
    ~AnnounceAttachmentAdapter();
    ~AnnounceListPageAdapter();
    // Application
    ~ApplicationDetailSectionAdapter();
    ~ApplicationDetailAdapter();
    ~ApplicationMetaAdapter();
    ~ApplicationMsgCountAdapter();
    ~ApplicationMsgAdapter();
    ~ApplicationMsgPageAdapter();
    ~ApplicationMessageTypeAdapter();

    // Credential
    ~OACredentialAdapter();
    ~UserTypeAdapter();

    // Exam Result
    ~ExamResultAdapter();
    ~ExamResultDetailAdapter();

    ~SchoolYearAdapter();
    ~SemesterAdapter();
  }
}

extension _TypeAdapterEx<T> on TypeAdapter<T> {
  void operator ~() {
    if (!Hive.isAdapterRegistered(typeId)) {
      Hive.registerAdapter(this);
    }
  }
}
