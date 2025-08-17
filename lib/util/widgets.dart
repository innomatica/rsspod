import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:logging/logging.dart' show Logger;
import 'package:rsspod/util/constants.dart'
    show assetImagePodcaster, defaultChannelImage, defaultEpisodeImage;

import '../model/channel.dart';
import '../model/episode.dart';

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
      return item is Channel
          ? Image.file(
              File(item.imagePath),
              width: width,
              height: height,
              fit: BoxFit.cover,
              opacity: AlwaysStoppedAnimation(opacity ?? 1.0),
              errorBuilder: (context, error, stackTrace) {
                _logger.fine('error:$error');
                return Image.network(
                  item.imageUrl,
                  width: width,
                  height: height,
                  fit: BoxFit.cover,
                  opacity: AlwaysStoppedAnimation(opacity ?? 1.0),
                );
              },
            )
          : item is Episode
          ? Image.file(
              File(item.channelImagePath),
              width: width,
              height: height,
              fit: BoxFit.cover,
              opacity: AlwaysStoppedAnimation(opacity ?? 1.0),
              errorBuilder: (context, error, stackTrace) {
                return Image.network(
                  item.channelImageUrl,
                  width: width,
                  height: height,
                  fit: BoxFit.cover,
                  opacity: AlwaysStoppedAnimation(opacity ?? 1.0),
                );
              },
            )
          : _getAssetImage(
              defaultChannelImage,
              width: width,
              height: height,
              opacity: opacity,
            );
    } catch (e) {
      _logger.warning(e.toString());
      return _getAssetImage(
        assetImagePodcaster,
        width: width,
        height: height,
        opacity: opacity,
      );
    }
  }
}

class EpisodeImage extends StatelessWidget {
  final Episode episode;
  final double? width;
  final double? height;
  final double? opacity;
  EpisodeImage(
    this.episode, {
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
      return Image.file(
        File(episode.imagePath),
        width: width,
        height: height,
        fit: BoxFit.cover,
        opacity: AlwaysStoppedAnimation(opacity ?? 1.0),
        errorBuilder: (_, _, _) {
          return episode.imageUrl != null
              ? Image.network(
                  episode.imageUrl!,
                  width: width,
                  height: height,
                  fit: BoxFit.cover,
                  opacity: AlwaysStoppedAnimation(opacity ?? 1.0),
                  errorBuilder: (_, _, _) => _getAssetImage(
                    defaultEpisodeImage,
                    width: width,
                    height: height,
                    opacity: opacity,
                  ),
                )
              : _getAssetImage(
                  defaultEpisodeImage,
                  width: width,
                  height: height,
                  opacity: opacity,
                );
        },
      );
    } catch (e) {
      _logger.warning(e.toString());
      return _getAssetImage(
        defaultEpisodeImage,
        width: width,
        height: height,
        opacity: opacity,
      );
    }
  }
}

Image _getAssetImage(
  String assetName, {
  double? width,
  double? height,
  double? opacity,
}) {
  return Image.asset(
    assetName,
    width: width,
    height: height,
    fit: BoxFit.cover,
    opacity: AlwaysStoppedAnimation(opacity ?? 1.0),
  );
}

IconData mediaIcon(String? mediaType) {
  if (mediaType?.contains('audio') == true) {
    return Icons.volume_up_rounded;
  }
  return Icons.question_mark_rounded;
}
