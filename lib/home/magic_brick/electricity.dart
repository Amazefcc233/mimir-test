import 'package:flutter/material.dart';
import 'package:mimir/home/entity/ftype.dart';
import 'package:mimir/l10n/extension.dart';
import 'package:mimir/module/symbol.dart';
import 'package:mimir/route.dart';
import 'package:mimir/storage/init.dart';

import '../widgets/brick.dart';

class ElectricityBillItem extends StatefulWidget {
  const ElectricityBillItem({super.key});

  @override
  State<StatefulWidget> createState() => _ElectricityBillItemState();
}

class _ElectricityBillItemState extends State<ElectricityBillItem> {
  final Balance? lastBalance = Kv.home.lastBalance;
  String? content;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final b = lastBalance;
    if (b != null) {
      content = i18n.elecBillContent(b.roomNumber, b.balance.toStringAsPrecision(2));
    }
    return Brick(
      route: RouteTable.electricityBill,
      icon: SvgAssetIcon('assets/home/icon_electricity.svg'),
      title: FType.electricityBill.l10nName(),
      subtitle: content ?? FType.electricityBill.l10nDesc(),
    );
  }
}
