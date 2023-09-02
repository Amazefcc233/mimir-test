import 'cache/cache.dart';
import 'dao/getter.dart';
import 'service/getter.dart';
import 'storage/local.dart';
import 'using.dart';

class ExpenseTrackerInit {
  static late ExpenseGetDao remote;
  static late ExpenseStorage local;
  static late CachedExpenseGetDao cache;

  static void init({
    required ISession session,
    required Box expenseBox,
  }) {
    remote = ExpenseGetService(session);
    local = ExpenseStorage(expenseBox);
    cache = CachedExpenseGetDao(remoteDao: remote, storage: local);
  }
}