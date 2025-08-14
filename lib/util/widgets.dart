import 'package:flutter/material.dart';
import 'package:logging/logging.dart' show Logger;
import 'package:rsspod/util/constants.dart' show assetImagePodcaster;

import '../model/channel.dart';
import '../model/episode.dart';

const defaultImageSize = 100.0;

class FutureImage extends StatelessWidget {
  final Future<ImageProvider> future;
  final double? width;
  final double? height;
  final double? opacity;
  const FutureImage({
    super.key,
    required this.future,
    this.width,
    this.height,
    this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(5),
      child: FutureBuilder(
        future: future,
        builder: (context, snapshot) {
          return snapshot.hasData
              ? Image(
                  image: snapshot.data!,
                  width: width ?? defaultImageSize,
                  height: height ?? defaultImageSize,
                  fit: BoxFit.cover,
                  opacity: AlwaysStoppedAnimation(opacity ?? 1.0),
                )
              : SizedBox(
                  width: width ?? defaultImageSize,
                  height: height ?? defaultImageSize,
                  child: Container(color: Colors.grey),
                );
        },
      ),
    );
  }
}

class ChannelImage extends StatelessWidget {
  final dynamic item;
  final double? width;
  final double? height;
  final double? opacity;
  ChannelImage(
    this.item, {
    super.key,
    // required this.item,
    this.width,
    this.height,
    this.opacity,
  });

  final _logger = Logger("ChannelImage");

  @override
  Widget build(BuildContext context) {
    try {
      return item is Channel && item.imageUrl != null
          ? Image.network(
              item.imageUrl!,
              width: width,
              height: height,
              fit: BoxFit.cover,
              opacity: AlwaysStoppedAnimation(opacity ?? 1.0),
            )
          : item is Episode && item.channelImageUrl != null
          ? Image.network(
              item.channelImageUrl!,
              width: width,
              height: height,
              fit: BoxFit.cover,
              opacity: AlwaysStoppedAnimation(opacity ?? 1.0),
            )
          : Image.asset(
              assetImagePodcaster,
              width: width,
              height: height,
              fit: BoxFit.cover,
              opacity: AlwaysStoppedAnimation(opacity ?? 1.0),
            );
    } catch (e) {
      _logger.warning(e.toString());
      return Image.asset(
        assetImagePodcaster,
        width: width,
        height: height,
        fit: BoxFit.cover,
        opacity: AlwaysStoppedAnimation(opacity ?? 1.0),
      );
    }
  }
}

IconData mediaIcon(String? mediaType) {
  if (mediaType?.contains('audio') == true) {
    return Icons.volume_up_rounded;
  }
  return Icons.question_mark_rounded;
}
