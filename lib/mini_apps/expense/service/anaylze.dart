import '../entity/local.dart';
import '../entity/remote.dart';

const deviceName2Type = {
  '开水': TransactionType.water,
  '浴室': TransactionType.shower,
  '咖啡吧': TransactionType.coffee,
  '食堂': TransactionType.food,
  '超市': TransactionType.store,
  '图书馆': TransactionType.library,
};

TransactionType analyzeType(Transaction trans) {
  if (trans.note.contains("充值")) {
    return TransactionType.topUp;
  } else if (trans.note.contains("补助")) {
    return TransactionType.subsidy;
  } else if (trans.note.contains("消费") || trans.isConsume) {
    for (MapEntry<String, TransactionType> entry in deviceName2Type.entries) {
      String name = entry.key;
      TransactionType type = entry.value;
      if (trans.deviceName.contains(name)) {
        return type;
      }
    }
  }
  return TransactionType.other;
}

Transaction analyzeFull(TransactionRaw raw) {
  var res = Transaction()
    ..datetime = parseDatetime(raw)
    ..balanceBefore = raw.cardbefbal
    ..balanceAfter = raw.cardaftbal
    ..deltaAmount = raw.amount.abs()
    ..deviceName = raw.devicename ?? ""
    ..note = raw.transname
    ..consumerId = raw.custid;
  res.type = analyzeType(res);
  return res;
}

DateTime parseDatetime(TransactionRaw raw) {
  final date = raw.transdate;
  final year = int.parse(date.substring(0, 4));
  final month = int.parse(date.substring(4, 6));
  final day = int.parse(date.substring(6, 8));

  final time = raw.transtime;
  final hour = int.parse(time.substring(0, 2));
  final min = int.parse(time.substring(2, 4));
  final sec = int.parse(time.substring(4, 6));
  return DateTime(year, month, day, hour, min, sec);
}