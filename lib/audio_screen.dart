import 'dart:math';

import 'package:audio_test/constants.dart';
import 'package:audio_test/overlay_handler.dart';
import 'package:audio_test/played_till_state.dart';
import 'package:audio_test/rotating_music_note_icon.dart';
import 'package:audio_test/seekbar.dart';
import 'package:flutter/material.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SingleAudioScreen extends StatefulWidget {
  SingleAudioScreen(
      {Key? key, required this.audioUrls, this.shuffle = false, this.index})
      : super(key: key);
  final List<SongModel> audioUrls;
  final bool shuffle;
  final int? index;
  @override
  State<SingleAudioScreen> createState() => _SingleAudioScreenState();
}

class _SingleAudioScreenState extends State<SingleAudioScreen> {
  final player = AudioPlayer();
  late PlayedTillProvider provider;

  @override
  void initState() {
    super.initState();
    provider = context.read<PlayedTillProvider>();
    provider.init();
    _init();
  }

  Future<void> _init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
    // Listen to errors during playback.
    player.playbackEventStream.listen((event) {
      if (event.processingState == ProcessingState.completed) {
        // delete songs from last played till list
        provider.remove(widget.audioUrls[event.currentIndex ?? 0].id);
        print("YAHOOOOOOOOOOOOOOOOOOOO< completed");
      }
    }, onError: (Object e, StackTrace stackTrace) {
      print('A stream error occurred: $e');
    });
    // Try to load audio from a source and catch any errors.
    try {
      final playlist = ConcatenatingAudioSource(
          children: widget.audioUrls
              .map((e) => AudioSource.file(e.data,
                  tag: MediaItem(
                      id: e.id.toString(), title: e.title, artist: e.artist)))
              .toList());
      var index = widget.index ?? 0;
      if (widget.shuffle) {
        index = Random().nextInt(playlist.length);
      }
      await player.setAudioSource(playlist, initialIndex: index);
      await player.setShuffleModeEnabled(widget.shuffle);
      var songPlayedTillIndex = provider.exists(widget.audioUrls[index].id);
      print("song played till $songPlayedTillIndex");
      if (songPlayedTillIndex != -1) {
        await player.seek(provider.getDuration(songPlayedTillIndex));
      }

      await player.play();
    } catch (e) {
      print("Error loading audio source: $e");
    }
  }

  Stream<PositionData> get _positionDataStream =>
      Rx.combineLatest3<Duration, Duration, Duration?, PositionData>(
          player.positionStream,
          player.bufferedPositionStream,
          player.durationStream,
          (position, bufferedPosition, duration) => PositionData(
              position, bufferedPosition, duration ?? Duration.zero));

  Stream<AudioPlayerStreams> get _playerStream => Rx.combineLatest5<LoopMode,
          bool, int?, SequenceState?, PlayerState, AudioPlayerStreams>(
      player.loopModeStream,
      player.shuffleModeEnabledStream,
      player.currentIndexStream,
      player.sequenceStateStream,
      player.playerStateStream,
      (a, b, c, d, e) => AudioPlayerStreams(
            a,
            b,
            c,
            d,
            e,
          ));

  @override
  void dispose() async {
    super.dispose();
    var song = widget.audioUrls[player.currentIndex ?? 0];
    print("${song.id} && ${player.position.inSeconds}");
    provider.addOrEdit(song.id, player.position.inSeconds);
    player.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OverlayHandlerProvider>(
        builder: (context, overlayProvider, _) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Scaffold(
          appBar: overlayProvider.inPipMode
              ? null
              : AppBar(elevation: 0, actions: [
                  IconButton(
                    onPressed: () => overlayProvider.enablePip(16 / 9),
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                  ),
                ]),
          body: StreamBuilder<AudioPlayerStreams>(
              stream: _playerStream,
              builder: (context, playerSnapshot) {
                // player.sequenceStateStream

                var playerData = playerSnapshot.data;
                if (overlayProvider.inPipMode) {
                  return InkWell(
                    onTap: () => overlayProvider.disablePip(),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        // mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Hero(
                            tag: widget
                                .audioUrls[playerData?.currentIndex ?? 0].data,
                            child: RotatingMusicNoteIcon(
                              isPlaying:
                                  playerData?.playerState?.playing ?? false,
                              height: Constants.VIDEO_TITLE_HEIGHT_PIP - 30,
                            ),
                          ),
                          const SizedBox(
                            width: 8,
                          ),
                          SizedBox(
                            width: (MediaQuery.of(context).size.width -
                                    Constants.VIDEO_TITLE_HEIGHT_PIP -
                                    10 -
                                    16) *
                                0.60,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  widget
                                      .audioUrls[playerData?.currentIndex ?? 0]
                                      .title,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .copyWith(fontSize: 14),
                                  maxLines: 2,
                                ),
                                const SizedBox(
                                  height: 8,
                                ),
                                StreamBuilder<PositionData>(
                                  stream: _positionDataStream,
                                  builder: (context, snapshot) {
                                    final positionData = snapshot.data;
                                    if (positionData == null) {
                                      return Container();
                                    }
                                    var percent = (positionData
                                            .position.inMilliseconds /
                                        positionData.duration.inMilliseconds);
                                    return LinearPercentIndicator(
                                      padding: EdgeInsets.zero,
                                      percent: percent > 1 ? 1 : percent,
                                      lineHeight: 2,
                                      progressColor:
                                          Theme.of(context).colorScheme.primary,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          StreamBuilder<bool>(
                            stream: player.playingStream,
                            builder: (context, playingSnapshot) {
                              var isPlaying = (playingSnapshot.data ?? false);
                              var myIconSize = 47.0;
                              return GestureDetector(
                                onTap: () {
                                  if (isPlaying) {
                                    player.pause();
                                  } else {
                                    player.play();
                                  }
                                },
                                child: AnimatedCrossFade(
                                  firstChild: Icon(
                                    Icons.play_arrow_rounded,
                                    size: myIconSize,
                                  ),
                                  secondChild: Icon(
                                    Icons.pause_rounded,
                                    size: myIconSize,
                                  ),
                                  crossFadeState: isPlaying
                                      ? CrossFadeState.showSecond
                                      : CrossFadeState.showFirst,
                                  duration: const Duration(milliseconds: 300),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            onPressed: () {
                              overlayProvider.removeOverlay(context);
                            },
                            icon: Icon(
                              Icons.close_rounded,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                }
                return SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Hero(
                          tag: widget
                              .audioUrls[playerData?.currentIndex ?? 0].data,
                          child: RotatingMusicNoteIcon(
                            isPlaying:
                                playerData?.playerState?.playing ?? false,
                          ),
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          widget.audioUrls[playerData?.currentIndex ?? 0].title,
                          style: Theme.of(context).textTheme.headlineLarge,
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        widget.audioUrls[playerData?.currentIndex ?? 0]
                                .artist ??
                            "N/A",
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),

                      // Display play/pause button and volume/speed sliders.
                      ControlButtons(player),
                      StreamBuilder<PositionData>(
                        stream: _positionDataStream,
                        builder: (context, snapshot) {
                          final positionData = snapshot.data;
                          return SeekBar(
                            duration: positionData?.duration ?? Duration.zero,
                            position: positionData?.position ?? Duration.zero,
                            bufferedPosition:
                                positionData?.bufferedPosition ?? Duration.zero,
                            onChangeEnd: player.seek,
                          );
                        },
                      ),
                    ],
                  ),
                );
              }),
        ),
      );
    });
  }
}

/// Displays the play/pause button and volume/speed sliders.
class ControlButtons extends StatelessWidget {
  final AudioPlayer player;

  const ControlButtons(this.player, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        StreamBuilder<bool>(
          stream: player.shuffleModeEnabledStream,
          builder: (context, snapshot) {
            return IconButton(
              onPressed: () {
                if ((snapshot.data ?? false)) {
                  player.setShuffleModeEnabled(false);
                } else {
                  player.setShuffleModeEnabled(true);
                }
              },
              icon: Icon((snapshot.data ?? false)
                  ? Icons.shuffle_on_rounded
                  : Icons.shuffle_rounded),
            );
          },
        ),
        IconButton(
          onPressed: () {
            player.seekToPrevious();
          },
          icon: const Icon(Icons.skip_previous),
        ),

        StreamBuilder<PlayerState>(
          stream: player.playerStateStream,
          builder: (context, snapshot) {
            final playerState = snapshot.data;
            final processingState = playerState?.processingState;
            final playing = playerState?.playing;
            if (processingState == ProcessingState.loading ||
                processingState == ProcessingState.buffering) {
              return Container(
                margin: const EdgeInsets.all(8.0),
                width: 64.0,
                height: 64.0,
                child: const CircularProgressIndicator(),
              );
            } else if (playing != true) {
              return IconButton(
                icon: const Icon(Icons.play_arrow_rounded),
                iconSize: 80.0,
                onPressed: player.play,
              );
            } else if (processingState != ProcessingState.completed) {
              return IconButton(
                icon: const Icon(Icons.pause_rounded),
                iconSize: 80.0,
                onPressed: player.pause,
              );
            } else {
              return IconButton(
                icon: const Icon(Icons.replay_rounded),
                iconSize: 80.0,
                onPressed: () => player.seek(Duration.zero),
              );
            }
          },
        ),
        IconButton(
          onPressed: () {
            player.seekToNext();
          },
          icon: const Icon(
            Icons.skip_next,
          ),
        ),
        StreamBuilder<LoopMode>(
            stream: player.loopModeStream,
            builder: (context, snapshot) {
              var loopMode = snapshot.data ?? LoopMode.all;
              String child;
              switch (loopMode) {
                case LoopMode.all:
                  child = "All";
                  break;

                case LoopMode.one:
                  child = "1";
                  break;
                default:
                  child = "";
              }
              return IconButton(
                onPressed: () {
                  if (loopMode == LoopMode.off) {
                    player.setLoopMode(LoopMode.one);
                  } else if (loopMode == LoopMode.one) {
                    player.setLoopMode(LoopMode.all);
                  } else if (loopMode == LoopMode.all) {
                    player.setLoopMode(LoopMode.off);
                  }
                },
                icon: Stack(
                  children: [
                    const Icon(Icons.loop_rounded),
                    if (loopMode != LoopMode.off)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: Text(
                              child,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall!
                                  .copyWith(
                                      fontSize: 5,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary),
                            )),
                      )
                  ],
                ),
              );
            }),
        // StreamBuilder<double>(
        //   stream: player.speedStream,
        //   builder: (context, snapshot) => IconButton(
        //     icon: Text("${snapshot.data?.toStringAsFixed(1)}x",
        //         style: const TextStyle(fontWeight: FontWeight.bold)),
        //     onPressed: () {
        //       showSliderDialog(
        //         context: context,
        //         title: "Adjust speed",
        //         divisions: 10,
        //         min: 0.5,
        //         max: 1.5,
        //         value: player.speed,
        //         stream: player.speedStream,
        //         onChanged: player.setSpeed,
        //       );
        //     },
        //   ),
        // ),
      ],
    );
  }
}

class PositionData {
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;

  PositionData(this.position, this.bufferedPosition, this.duration);
}

class AudioPlayerStreams {
  final LoopMode loopMode;
  final bool shuffling;
  int? currentIndex;
  SequenceState? sequence;
  PlayerState? playerState;
  AudioPlayerStreams(this.loopMode, this.shuffling, this.currentIndex,
      this.sequence, this.playerState);
}
