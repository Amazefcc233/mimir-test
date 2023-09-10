import 'dart:convert';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:mimir/l10n/common.dart';
import 'package:rettulf/rettulf.dart';

const _i18n = CommonI18n();

enum _ImageMode {
  url,
  base64,
  error,
}

class ImageView extends StatefulWidget {
  /// It could be a url of image, or a base64 string.
  final String data;

  const ImageView(
    this.data, {
    super.key,
  });

  @override
  State<ImageView> createState() => _ImageViewState();
}

class _ImageViewState extends State<ImageView> {
  var mode = _ImageMode.url;
  Uint8List? imageData;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  @override
  void didUpdateWidget(covariant ImageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data != oldWidget.data) {
      refresh();
    }
  }

  void refresh() {
    setState(() {
      imageData = null;
    });
    if (widget.data.startsWith("data")) {
      setState(() {
        mode = _ImageMode.base64;
      });
      try {
        final parts = widget.data.split(",");
        final bytes = const Base64Decoder().convert(parts[1]);
        setState(() {
          imageData = bytes;
        });
      } catch (error) {
        setState(() {
          mode = _ImageMode.error;
        });
      }
    } else {
      setState(() {
        mode = _ImageMode.url;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? provider;
    final imageData = this.imageData;
    if (mode == _ImageMode.url) {
      provider = CachedNetworkImageProvider(widget.data);
    } else if (mode == _ImageMode.base64 && imageData != null) {
      provider = MemoryImage(imageData);
    } else {
      provider = null;
    }
    return InteractiveViewer(
      minScale: 1,
      maxScale: 10.0,
      child: provider == null ? buildBrokenImage() : buildImage(provider),
    );
  }

  Widget buildImage(ImageProvider provider) {
    return Image(
      image: provider,
      loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
        if (loadingProgress == null) {
          return child;
        } else {
          final current = loadingProgress.cumulativeBytesLoaded;
          final total = loadingProgress.expectedTotalBytes;
          if (total == null || total == 0) {
            return const CircularProgressIndicator();
          } else {
            return CircularProgressIndicator(value: current / total);
          }
        }
      },
      errorBuilder: (ctx, error, stacktrace) {
        return buildBrokenImage();
      },
    );
  }

  Widget buildBrokenImage() {
    return const FittedBox(
      fit: BoxFit.fill,
      child: Icon(Icons.broken_image_rounded),
    );
  }
}

class ImageViewPage extends StatelessWidget {
  final String data;
  final String? title;

  const ImageViewPage(
    this.data, {
    super.key,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    // TODO: Save the image.
    return Scaffold(
      appBar: AppBar(
        title: (title ?? _i18n.untitled).text(),
      ),
      body: ImageView(data).center(),
    );
  }
}
