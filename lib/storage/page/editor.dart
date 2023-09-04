import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:mimir/design/widgets/common.dart';
import 'package:mimir/hive/init.dart';
import 'package:mimir/widgets/page_grouper.dart';
import 'package:rettulf/rettulf.dart';

import '../using.dart';

class LocalStoragePage extends StatefulWidget {
  const LocalStoragePage({super.key});

  @override
  State<LocalStoragePage> createState() => _LocalStoragePageState();
}

class _LocalStoragePageState extends State<LocalStoragePage> {
  final Map<String, Box> name2Box = {};

  @override
  void initState() {
    super.initState();
    for (final entry in HiveBoxInit.name2Box.entries) {
      final boxName = entry.key;
      final box = entry.value;
      if (box.isOpen) {
        name2Box[boxName] = box;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final boxes = name2Box.entries
        .where((name2Box) => name2Box.value.isNotEmpty)
        .map((e) => (name: e.key, box: e.value))
        .toList();
    return context.isPortrait ? StorageListPortrait(boxes) : StorageListLandscape(boxes);
  }
}

class StorageListPortrait extends StatefulWidget {
  final List<({String name, Box box})> boxes;

  const StorageListPortrait(this.boxes, {super.key});

  @override
  State<StorageListPortrait> createState() => _StorageListPortraitState();
}

class _StorageListPortraitState extends State<StorageListPortrait> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: i18n.title.text()),
      body: ListView.separated(
        itemCount: widget.boxes.length,
        itemBuilder: (ctx, i) {
          final (:name, :box) = widget.boxes[i];
          return BoxSection(box: box, boxName: name);
        },
        separatorBuilder: (BuildContext context, int index) {
          return const Divider();
        },
      ),
    );
  }
}

class BoxSection extends StatefulWidget {
  final String boxName;
  final Box<dynamic> box;

  const BoxSection({super.key, required this.box, required this.boxName});

  @override
  State<StatefulWidget> createState() => _BoxSectionState();
}

class _BoxSectionState extends State<BoxSection> {
  String get boxName => widget.boxName;

  Box<dynamic> get box => widget.box;

  Widget buildTitle(BuildContext ctx) {
    final box = this.box;
    final boxNameStyle = ctx.textTheme.headlineSmall;
    final action = PopupMenuButton(
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16.0))),
      position: PopupMenuPosition.under,
      padding: EdgeInsets.zero,
      itemBuilder: (ctx) =>
      <PopupMenuEntry>[
        PopupMenuItem(
          child: ListTile(
            leading: const Icon(Icons.edit, color: Colors.redAccent),
            title: i18n.clear.text(style: const TextStyle(color: Colors.redAccent)),
            onTap: () async {
              ctx.pop();
              final confirm = await _showDeleteBoxRequest(ctx);
              if (confirm == true) {
                box.clear();
                // Add a delay to ensure the box is really empty.
                await Future.delayed(const Duration(milliseconds: 500));
                if (!mounted) return;
                setState(() {});
              }
            },
          ),
        ),
      ],
    );
    return [
      Text(boxName, style: boxNameStyle, textAlign: TextAlign.center).expanded(),
      action,
    ].row();
  }

  @override
  Widget build(BuildContext context) {
    final curBox = box;
    return [
      buildTitle(context),
      BoxItemList(box: curBox),
    ].column(mas: MainAxisSize.min).sized(w: double.infinity).padSymmetric(v: 5, h: 10);
  }
}

class BoxItemList extends StatefulWidget {
  final Box<dynamic> box;

  const BoxItemList({super.key, required this.box});

  @override
  State<BoxItemList> createState() => _BoxItemListState();
}

class _BoxItemListState extends State<BoxItemList> {
  int currentPage = 0;
  static const pageSize = 6;

  @override
  Widget build(BuildContext context) {
    final box = widget.box;
    if (box.isEmpty) {
      return const Icon(
        Icons.inbox_outlined,
        size: 32,
      ).padAll(10);
    } else {
      return buildList(context);
    }
  }

  Widget buildList(BuildContext ctx) {
    final keys = widget.box.keys.toList();
    final length = keys.length;
    if (length < pageSize) {
      return buildBoxItems(ctx, keys);
    } else {
      final start = currentPage * pageSize;
      var totalPages = length ~/ pageSize;
      if (length % pageSize != 0) {
        totalPages++;
      }
      final end = min(start + pageSize, length);
      return [
        buildPaginated(ctx, totalPages).padAll(10),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.fastLinearToSlowEaseIn,
          child: buildBoxItems(ctx, keys.sublist(start, end)),
        ),
      ].column();
    }
  }

  Widget buildBoxItems(BuildContext ctx, List<dynamic> keys) {
    final routeStyle = context.textTheme.titleMedium;
    final typeStyle = context.textTheme.bodySmall;
    final contentStyle = context.textTheme.bodyMedium;
    return keys
        .map((e) =>
        BoxItem(
          keyInBox: e,
          box: widget.box,
          routeStyle: routeStyle,
          typeStyle: typeStyle,
          contentStyle: contentStyle,
          onBoxChanged: () {
            if (!mounted) return;
            setState(() {});
          },
        ))
        .toList()
        .column();
  }

  Widget buildPaginated(BuildContext ctx, int totalPage) {
    return PageGrouper(
      paginateButtonStyles: PageBtnStyles(),
      preBtnStyles: SkipBtnStyle(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          bottomLeft: Radius.circular(20),
        ),
      ),
      onPageChange: (number) {
        setState(() {
          currentPage = number - 1;
        });
      },
      totalPage: totalPage,
      btnPerGroup: (ctx.mediaQuery.size.width / 50.w).round().clamp(1, totalPage),
      currentPageIndex: currentPage + 1,
    );
  }
}

class BoxItem extends StatefulWidget {
  final TextStyle? routeStyle;

  final TextStyle? typeStyle;
  final TextStyle? contentStyle;
  final dynamic keyInBox;
  final Box<dynamic> box;
  final VoidCallback? onBoxChanged;

  const BoxItem({
    super.key,
    this.routeStyle,
    this.typeStyle,
    this.contentStyle,
    required this.keyInBox,
    required this.box,
    this.onBoxChanged,
  });

  @override
  State<BoxItem> createState() => _BoxItemState();

  static Widget skeleton(TextStyle? routeStyle, TextStyle? typeStyle, TextStyle? contentStyle) =>
      [
        Text(
          "...",
          style: routeStyle,
        ),
        Text("...", style: typeStyle),
        Text(
          '.........',
          maxLines: 3,
          style: contentStyle,
        ),
      ].column(caa: CrossAxisAlignment.start).align(at: Alignment.topLeft).padAll(10).inCard(elevation: 5);
}

class _BoxItemState extends State<BoxItem> {
  @override
  Widget build(BuildContext context) {
    final key = widget.keyInBox.toString();
    final value = widget.box.get(widget.keyInBox);
    final type = value.runtimeType.toString();
    Widget res = [
      Text(
        key,
        style: widget.routeStyle,
      ),
      Text(type, style: widget.typeStyle?.copyWith(color: Editor.isSupport(value) ? Colors.green : null)),
      Text(
        '$value',
        maxLines: 5,
        style: widget.contentStyle?.copyWith(overflow: TextOverflow.ellipsis),
      ),
    ].column(caa: CrossAxisAlignment.start).align(at: Alignment.topLeft).padAll(10).inCard(elevation: 5);
    if (value != null) {
      if (kDebugMode) {
        res = res.on(tap: () async => showContentDialog(context, widget.box, key, value));
        //res = buildContextMenu(context, res, key, widget.box);
        res = buildSwipe(context, res, key, value);
      } else {
        res = res.on(tap: () async => showContentDialog(context, widget.box, key, value, readonly: true));
      }
    }
    return res;
  }

  Widget buildSwipe(BuildContext ctx, Widget w, String key, dynamic value) {
    final DismissDirection dir;
    if (value == null) {
      dir = DismissDirection.none;
    } else if (_canEmptyValue(value)) {
      dir = DismissDirection.horizontal;
    } else {
      dir = DismissDirection.endToStart;
    }
    return Dismissible(
      key: ValueKey(key),
      direction: dir,
      confirmDismiss: (dir) async {
        if (dir == DismissDirection.startToEnd) {
          // Empty the value
          final confirm = await context.showRequest(
              title: i18n.warning,
              desc: i18n.emptyValueDesc,
              yes: i18n.confirm,
              no: i18n.cancel,
              highlight: true);
          if (confirm == true) {
            widget.box.put(key, _emptyValue(value));
            if (!mounted) return false;
            setState(() {});
          }
          return false;
        } else if (dir == DismissDirection.endToStart) {
          // Delete the item.
          final confirm = await _showDeleteItemRequest(ctx);
          if (confirm == true) {
            widget.box.delete(key);
            widget.onBoxChanged?.call();
            return true;
          }
        }
        return false;
      },
      child: w,
    );
  }

  Future<void> showContentDialog(BuildContext context, Box<dynamic> box, String key, dynamic value,
      {bool readonly = false}) async {
    if (readonly || !Editor.isSupport(value)) {
      await Editor.showReadonlyEditor(context, desc: key, initial: value);
    } else {
      final newValue = await Editor.showAnyEditor(context, value, desc: key);
      bool isModified = value != newValue;
      if (isModified) {
        box.put(key, newValue);
        if (!mounted) return;
        setState(() {});
      }
    }
  }
}

class StorageListLandscape extends StatefulWidget {
  final List<({String name, Box box})> boxes;

  const StorageListLandscape(this.boxes, {super.key});

  @override
  State<StorageListLandscape> createState() => _StorageListLandscapeState();
}

class _StorageListLandscapeState extends State<StorageListLandscape> {
  late String? selectedBoxName = widget.boxes.firstOrNull?.name;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: i18n.title.text(),
          elevation: 0,
        ),
        body: [
          buildBoxTitle().expanded(),
          const VerticalDivider(
            thickness: 5,
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: buildBoxContentView(ctx),
          ).padAll(10).flexible(flex: 2)
        ].row());
  }

  Widget buildBoxTitle() {
    final boxNameStyle = context.textTheme.titleMedium;
    return ListView.builder(
      itemCount: widget.boxes.length,
      itemBuilder: (ctx, i) {
        final (:name, :box) = widget.boxes[i];
        final color = name == selectedBoxName ? context.theme.secondaryHeaderColor : null;
        final action = PopupMenuButton(
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16.0))),
          position: PopupMenuPosition.under,
          padding: EdgeInsets.zero,
          itemBuilder: (ctx) =>
          <PopupMenuEntry>[
            PopupMenuItem(
              child: ListTile(
                leading: const Icon(Icons.edit, color: Colors.redAccent),
                title: i18n.clear.text(style: const TextStyle(color: Colors.redAccent)),
                onTap: () async {
                  ctx.pop();
                  final confirm = await _showDeleteBoxRequest(ctx);
                  if (confirm == true) {
                    box.clear();
                    if (!mounted) return;
                    setState(() {});
                  }
                },
              ),
            ),
          ],
        );
        return [
          name.text(style: boxNameStyle).padAll(10).on(tap: () {
            if (selectedBoxName != name) {
              setState(() {
                selectedBoxName = name;
              });
            }
          }).expanded(),
          action,
        ].row().inCard(elevation: 3, color: color);
      },
    );
  }

  Widget buildBoxContentView(BuildContext ctx) {
    final name = selectedBoxName;
    final selected = widget.boxes.firstWhereOrNull((tuple) => tuple.name == name);
    if (selected == null) {
      return _buildUnselectBoxTip(ValueKey(name), ctx);
    }
    final routeStyle = context.textTheme.titleMedium;
    final typeStyle = context.textTheme.bodySmall;
    final contentStyle = context.textTheme.bodyMedium;
    final keys = selected.box.keys.toList();
    return ListView.builder(
      itemCount: keys.length,
      itemBuilder: (ctx, i) {
        return BoxItem(
          keyInBox: keys[i],
          box: selected.box,
          routeStyle: routeStyle,
          typeStyle: typeStyle,
          contentStyle: contentStyle,
          onBoxChanged: () {
            if (!mounted) return;
            setState(() {});
          },
        );
      },
    );
  }

  Widget _buildUnselectBoxTip(Key? key, BuildContext ctx) {
    return LeavingBlank(key: key, icon: Icons.unarchive_outlined, desc: i18n.selectBoxTip);
  }
}

/// THIS IS VERY DANGEROUS!!!
dynamic _emptyValue(dynamic value) {
  if (value is String) {
    return "";
  } else if (value is bool) {
    return false;
  } else if (value is int) {
    return 0;
  } else if (value is double) {
    return 0.0;
  } else if (value is List) {
    value.clear();
    return value;
  } else if (value is Set) {
    value.clear();
    return value;
  } else if (value is Map) {
    value.clear();
    return value;
  } else {
    return value;
  }
}

dynamic _canEmptyValue(dynamic value) {
  return value is String ||
      value is bool ||
      value is int ||
      value is double ||
      value is List ||
      value is Set ||
      value is Map;
}

Future<bool?> _showDeleteBoxRequest(BuildContext ctx) async {
  return await ctx.showRequest(
      title: i18n.delete,
      desc: i18n.clearBoxDesc,
      yes: i18n.confirm,
      no: i18n.cancel,
      highlight: true);
}

Future<bool?> _showDeleteItemRequest(BuildContext ctx) async {
  return await ctx.showRequest(
      title: i18n.delete,
      desc: i18n.deleteItemDesc,
      yes: i18n.delete,
      no: i18n.cancel,
      highlight: true);
}
