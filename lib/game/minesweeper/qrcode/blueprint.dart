import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:sit/game/qrcode/blueprint.dart';

import '../entity/blueprint.dart';
import '../storage.dart';

const blueprintMinesweeperDeepLink = GameBlueprintDeepLink<BlueprintMinesweeper>(
  "minesweeper",
  onHandleBlueprintMinesweeper,
);

Future<void> onHandleBlueprintMinesweeper({
  required BuildContext context,
  required String blueprint,
}) async {
  final blueprintObj = BlueprintMinesweeper.from(blueprint);
  final state = blueprintObj.create();
  StorageMinesweeper.save.save(state.toSave());
  context.push("/game/minesweeper?continue");
}
