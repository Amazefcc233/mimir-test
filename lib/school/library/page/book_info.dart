import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:rettulf/rettulf.dart';
import 'package:sit/design/adaptive/foundation.dart';
import 'package:sit/widgets/image.dart';
import 'package:sit/widgets/placeholder_future_builder.dart';

import '../entity/book_info.dart';
import '../entity/book_search.dart';
import '../entity/holding_preview.dart';
import '../init.dart';
import '../utils.dart';
import 'search.dart';
import 'search_result.dart';

class BookInfoPage extends StatefulWidget {
  /// 上一层传递进来的数据
  final BookImageHolding bookImageHolding;

  const BookInfoPage(this.bookImageHolding, {super.key});

  @override
  State<BookInfoPage> createState() => _BookInfoPageState();
}

class _BookInfoPageState extends State<BookInfoPage> {
  BookInfo? info;

  @override
  void initState() {
    super.initState();
    fetchDetails();
  }

  Future<void> fetchDetails() async {
    final info = await LibraryInit.bookInfo.query(widget.bookImageHolding.book.bookId);
    if (!context.mounted) return;
    setState(() {
      this.info = info;
    });
  }

  @override
  Widget build(BuildContext context) {
    final book = widget.bookImageHolding.book;
    final imgUrl = widget.bookImageHolding.image?.resourceLink;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            automaticallyImplyLeading: false,
            expandedHeight: 300.0,
            flexibleSpace: imgUrl == null
                ? null
                : CachedNetworkImage(
                    imageUrl: imgUrl,
                    placeholder: (context, url) => const CircularProgressIndicator.adaptive(),
                    errorWidget: (context, url, error) => const Icon(Icons.error),
                  ),
          ),
          SliverList.list(children: [
            ListTile(
              title: "Title".text(),
              subtitle: book.title.text(),
              visualDensity: VisualDensity.compact,
            ),
            ListTile(
              title: "Author".text(),
              subtitle: book.author.text(),
              visualDensity: VisualDensity.compact,
            ),
            ListTile(
              title: "ISBN".text(),
              subtitle: book.isbn.text(),
              visualDensity: VisualDensity.compact,
            ),
            ListTile(
              title: "Call No.".text(),
              subtitle: book.callNo.text(),
              visualDensity: VisualDensity.compact,
            ),
            ListTile(
              title: "Publisher".text(),
              subtitle: book.publisher.text(),
              visualDensity: VisualDensity.compact,
            ),
            ListTile(
              title: "Publish date".text(),
              subtitle: book.publishDate.text(),
              visualDensity: VisualDensity.compact,
            ),
          ]),
          const SliverToBoxAdapter(
            child: Divider(),
          ),
          SliverToBoxAdapter(
            child: buildBookDetails().padAll(10),
          ),
          const SliverToBoxAdapter(
            child: Divider(),
          ),
          SliverList.list(children: [
            buildTitle('馆藏信息'),
            buildHolding(widget.bookImageHolding.holding ?? []),
          ]),
          const SliverToBoxAdapter(
            child: Divider(),
          ),
          SliverList.list(children: [
            buildTitle('邻近的书'),
            NearBooksGroup(bookId: widget.bookImageHolding.book.bookId),
          ]),
        ],
      ),
    );
  }

  Widget buildBookDetails() {
    final info = this.info;
    if (info == null) return const CircularProgressIndicator.adaptive();
    return Table(
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(5),
      },
      // border: TableBorder.all(color: Colors.red),
      children: info.rawDetail.entries
          .map(
            (e) => TableRow(
              children: [
                Text(e.key, style: Theme.of(context).textTheme.titleSmall),
                SelectableText(e.value, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          )
          .toList(),
    );
  }

  Widget buildHoldingItem(HoldingPreviewItem item) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('索书号：' + item.callNo),
                  Text('所在馆：' + item.currentLocation),
                ],
              ),
            ),
            Text('在馆(${item.loanableCount})/馆藏(${item.copyCount})'),
          ],
        ),
      ),
    );
  }

  /// 构造馆藏信息列表
  Widget buildHolding(List<HoldingPreviewItem> items) {
    return Column(
      children: items.map(buildHoldingItem).toList(),
    );
  }

  /// 构造标题样式的文本
  Widget buildTitle(String text) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleLarge,
    );
  }
}

class NearBooksGroup extends StatefulWidget {
  final int maxSize;
  final String bookId;

  const NearBooksGroup({
    super.key,
    required this.bookId,
    this.maxSize = 5,
  });

  @override
  State<NearBooksGroup> createState() => _NearBooksGroupState();
}

class _NearBooksGroupState extends State<NearBooksGroup> {
  List<String>? nearBookIdList;

  @override
  void initState() {
    super.initState();
    fetchNearBooks();
  }

  Future<void> fetchNearBooks() async {
    final nearBookIdList = await LibraryInit.holdingInfo.searchNearBookIdList(widget.bookId);
    if (!context.mounted) return;
    setState(() {
      this.nearBookIdList = nearBookIdList;
    });
  }

  @override
  Widget build(BuildContext context) {
    final nearBookIdList = this.nearBookIdList;
    if (nearBookIdList == null) return const CircularProgressIndicator.adaptive();
    return Column(
      children: nearBookIdList.sublist(0, widget.maxSize).map((bookId) {
        return buildBookItem(bookId);
      }).toList(),
    );
  }

  /// 构造邻近的书
  Widget buildBookItem(String bookId) {
    Future<BookImageHolding> get() async {
      final result = await LibraryInit.bookSearch.search(
        keyword: bookId,
        rows: 1,
        searchWay: SearchMethod.bookId,
      );
      final ret = await BookImageHolding.simpleQuery(
        LibraryInit.bookImageSearch,
        LibraryInit.holdingPreview,
        result.books,
      );
      return ret[0];
    }

    return PlaceholderFutureBuilder<BookImageHolding>(
      future: get(),
      builder: (ctx, data, state) {
        if (data == null) return const CircularProgressIndicator.adaptive();
        return BookCard(
          data,
          onTap: () async {
            await context.show$Sheet$((ctx) => BookInfoPage(data));
          },
        );
      },
    );
  }
}
