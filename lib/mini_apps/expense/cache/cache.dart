import '../dao/getter.dart';
import '../entity/local.dart';
import '../storage/local.dart';

class CachedExpenseGetDao implements ExpenseGetDao {
  final ExpenseGetDao remoteDao;
  final ExpenseStorage storage;

  CachedExpenseGetDao({
    required this.remoteDao,
    required this.storage,
  });

  Future<List<Transaction>> _fetchAndSave({
    required String studentID,
    required DateTime from,
    required DateTime to,
  }) async {
    final fetchedData = await remoteDao.fetch(studentID: studentID, from: from, to: to);
    storage.merge(records: fetchedData, start: from, end: to);
    return fetchedData;
  }

  @override
  Future<List<Transaction>> fetch({
    required String studentID,
    required DateTime from,
    required DateTime to,
    void Function(List<Transaction>)? onLocalQuery, // 本地查询完成
  }) async {
    queryInLocal() =>
        storage.getTransactionTsByRange(start: from, end: to).map((e) => storage.getTransactionByTs(e)!).toList();

    final cachedStart = storage.cachedTsStart;
    final cachedEnd = storage.cachedTsEnd;
    if (cachedStart == null && cachedEnd == null) {
      // 第一次获取数据
      onLocalQuery?.call([]);
      final result = await _fetchAndSave(studentID: studentID, from: from, to: to);
      return result;
    }

    onLocalQuery?.call(queryInLocal());
    if (to.isAfter(cachedEnd!)) await _fetchAndSave(studentID: studentID, from: cachedEnd, to: to);
    if (from.isBefore(cachedStart!)) await _fetchAndSave(studentID: studentID, from: from, to: cachedStart);

    return queryInLocal();
  }
}