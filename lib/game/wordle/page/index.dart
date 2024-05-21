// Thanks to https://github.com/Linloir/Flutter-Wordle

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../event_bus.dart';
import '../page/loading.dart';
import '../entity/vocabulary.dart';
import '../settings.dart';
import '../widget/selection_group.dart';

class GameWordlePage extends ConsumerStatefulWidget {
  const GameWordlePage({super.key});

  @override
  ConsumerState<GameWordlePage> createState() => _GameWordlePageState();
}

class _GameWordlePageState extends ConsumerState<GameWordlePage> {
  @override
  Widget build(BuildContext context) {
    final pref = ref.watch(SettingsWordle.$.$pref);
    return LoadingPage(
      dicName: pref.vocabulary.name,
      maxChances: 6,
    );
  }
}