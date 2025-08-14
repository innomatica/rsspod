import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart'
    show MediaItem;
import 'package:provider/provider.dart';

import '../util/helpers.dart' show secsToHhMmSs;

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final player = context.read<AudioPlayer>();
    return StreamBuilder(
      stream: player.sequenceStateStream,
      builder: (context, snapshot) {
        return snapshot.hasData && snapshot.data!.sequence.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 4.0,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  // color: Colors.transparent,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // title
                      Expanded(
                        child: TextButton(
                          // onPressed: onPressed,
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              builder: (context) => ModalPlayer(),
                            );
                          },
                          child: Text(
                            snapshot.data!.currentSource?.tag.title ?? '',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ),
                      ),
                      // rewind 30 sec
                      IconButton(
                        icon: Icon(Icons.replay_30_rounded),
                        onPressed: () async {
                          final newPos =
                              player.position - Duration(seconds: 30);
                          await player.seek(
                            newPos <= Duration.zero ? Duration.zero : newPos,
                          );
                        },
                      ),
                      // play or pause
                      StreamBuilder(
                        stream: player.playingStream,
                        builder: (context, snapshot) {
                          return snapshot.hasData
                              ? IconButton(
                                  onPressed: () async {
                                    snapshot.data!
                                        ? await player.pause()
                                        : await player.play();
                                  },
                                  icon: Icon(
                                    snapshot.data!
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                  ),
                                )
                              : SizedBox(width: 0);
                        },
                      ),
                      // forward 30
                      IconButton(
                        icon: Icon(Icons.forward_30_rounded),
                        onPressed: () async {
                          final newPos =
                              player.position + Duration(seconds: 30);
                          if (player.duration != null &&
                              newPos <= player.duration!) {
                            await player.seek(newPos);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              )
            : SizedBox(height: 0);
      },
    );
  }
}

class ModalPlayer extends StatelessWidget {
  const ModalPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final player = context.read<AudioPlayer>();
    bool ignoreStream = false;
    double playerPos = 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // playlist
          StreamBuilder(
            stream: player.sequenceStateStream,
            builder: (context, snapshot) {
              return snapshot.hasData
                  ? Column(
                      children: snapshot.data!.sequence.map((e) {
                        final myIndex = snapshot.data!.sequence.indexOf(e);
                        return ListTile(
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          contentPadding: EdgeInsets.only(left: 8),
                          selectedColor: Theme.of(context).colorScheme.tertiary,
                          selected: snapshot.data!.currentSource == e,
                          title: Text(
                            (e.tag as MediaItem).title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 16),
                          ),
                          onTap: () async {
                            if (myIndex != snapshot.data!.currentIndex) {
                              await player.seek(
                                Duration.zero,
                                index: snapshot.data!.sequence.indexOf(e),
                              );
                            }
                          },
                          onLongPress: () {
                            context.go(
                              Uri(
                                path: '/episode',
                                queryParameters: {'guid': e.tag.id},
                              ).toString(),
                            );
                          },
                          // just_audio version 0.10 specific
                          trailing: IconButton(
                            icon: Icon(Icons.playlist_remove_rounded),
                            onPressed: () {
                              player.removeAudioSourceAt(myIndex);
                            },
                          ),
                        );
                      }).toList(),
                    )
                  : SizedBox(height: 0);
            },
          ),
          // first row: speed, position, volume
          StreamBuilder<Duration>(
            stream: player.positionStream,
            builder: (context, snapshot) {
              return StatefulBuilder(
                builder: (context, setState) {
                  if (!ignoreStream && snapshot.hasData) {
                    playerPos =
                        snapshot.data?.inSeconds.toDouble() ?? playerPos;
                  }
                  return Column(
                    children: [
                      // position slider
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 8.0,
                        ),
                        child: Slider(
                          value: playerPos,
                          max: player.duration?.inSeconds.toDouble() ?? 100.0,
                          padding: EdgeInsets.only(
                            top: 16,
                            left: 16,
                            right: 16,
                          ),
                          onChangeStart: (value) {
                            setState(() => ignoreStream = true);
                          },
                          onChanged: (value) {
                            setState(() => playerPos = value);
                          },
                          onChangeEnd: (value) async {
                            await player.seek(Duration(seconds: value.toInt()));
                            ignoreStream = false;
                          },
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(secsToHhMmSs(player.position.inSeconds)),
                          Text(secsToHhMmSs(player.duration?.inSeconds)),
                        ],
                      ),
                    ],
                  );
                },
              );
            },
          ),
          // second row: begin, rewind, play, forward, end
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 16,
            children: [
              // to the beginning
              IconButton(
                icon: Icon(Icons.skip_previous_rounded, size: 26.0),
                onPressed: () async => await player.seek(Duration.zero),
              ),
              // rewind 30 sec
              IconButton(
                icon: Icon(Icons.replay_30_rounded, size: 26.0),
                onPressed: () async {
                  final newPos = player.position - Duration(seconds: 30);
                  await player.seek(
                    newPos <= Duration.zero ? Duration.zero : newPos,
                  );
                },
              ),
              // play or pause
              StreamBuilder<bool>(
                stream: player.playingStream,
                builder: (context, snapshot) {
                  return IconButton(
                    icon: Icon(
                      snapshot.data == true
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      size: 48.0,
                    ),
                    onPressed: () async {
                      player.playing
                          ? await player.pause()
                          : await player.play();
                    },
                  );
                },
              ),
              // forward 30
              IconButton(
                icon: Icon(Icons.forward_30_rounded, size: 26.0),
                onPressed: () async {
                  final newPos = player.position + Duration(seconds: 30);
                  if (player.duration != null && newPos <= player.duration!) {
                    await player.seek(newPos);
                  }
                },
              ),
              IconButton(
                icon: Icon(Icons.skip_next_rounded, size: 26.0),
                onPressed: () async {
                  if (player.duration != null) {
                    await player.seek(player.duration!);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// speed selector
// StreamBuilder<Object>(
//   stream: player.speedStream,
//   builder: (context, snapshot) {
//     return DropdownButton<double>(
//       value: snapshot.data as double? ?? 1.0,
//       items: [
//         DropdownMenuItem(value: 2.0, child: Text('2.0x')),
//         DropdownMenuItem(value: 1.5, child: Text('1.5x')),
//         DropdownMenuItem(value: 1.25, child: Text('1.25x')),
//         DropdownMenuItem(value: 1.0, child: Text('1.0x')),
//         DropdownMenuItem(value: 0.75, child: Text('0.75x')),
//         DropdownMenuItem(value: 0.5, child: Text('0.5x')),
//       ],
//       onChanged: (value) {
//         if (value != null) {
//           player.setSpeed(value);
//         }
//       },
//     );
//   },
// ),
