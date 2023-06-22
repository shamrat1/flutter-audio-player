import 'package:audio_test/audio_file.dart';
import 'package:audio_test/seekbar.dart';
import 'package:flutter/material.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:rxdart/rxdart.dart';

class SingleAudioScreen extends StatefulWidget {
  SingleAudioScreen({Key? key, required this.audioUrls}) : super(key: key);
  final List<SongModel> audioUrls;

  @override
  State<SingleAudioScreen> createState() => _SingleAudioScreenState();
}

class _SingleAudioScreenState extends State<SingleAudioScreen> {
  final player = AudioPlayer();
  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.speech());
    // Listen to errors during playback.
    player.playbackEventStream.listen((event) {},
        onError: (Object e, StackTrace stackTrace) {
      print('A stream error occurred: $e');
    });
    // Try to load audio from a source and catch any errors.
    try {
      final playlist = ConcatenatingAudioSource(
          children:
              widget.audioUrls.map((e) => AudioSource.file(e.data)).toList());
      await player.setAudioSource(playlist, initialIndex: 0);
      await player.setShuffleModeEnabled(true);
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

  Stream<AudioPlayerStreams> get _playerStream => Rx.combineLatest4<LoopMode,
          bool, int?, SequenceState?, AudioPlayerStreams>(
      player.loopModeStream,
      player.shuffleModeEnabledStream,
      player.currentIndexStream,
      player.sequenceStateStream,
      (a, b, c, d) => AudioPlayerStreams(a, b, c, d));

  @override
  void dispose() {
    super.dispose();
    player.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          elevation: 0,
          leading: IconButton(
            onPressed: () {},
            icon: const Icon(Icons.keyboard_arrow_down),
          ),
          actions: [
            IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close))
          ]),
      body: SafeArea(
        child: StreamBuilder<AudioPlayerStreams>(
            stream: _playerStream,
            builder: (context, playerSnapshot) {
              // player.sequenceStateStream

              var playerData = playerSnapshot.data;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Hero(
                    tag: widget.audioUrls[playerData?.currentIndex ?? 0].data,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      width: double.infinity,
                      height: MediaQuery.sizeOf(context).height * 0.35,
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.music_note_rounded,
                        size: 250,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),

                  Text(
                    widget.audioUrls[playerData?.currentIndex ?? 0].title,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  Text(
                    widget.audioUrls[playerData?.currentIndex ?? 0].artist ??
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
              );
            }),
      ),
    );
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
  AudioPlayerStreams(
      this.loopMode, this.shuffling, this.currentIndex, this.sequence);
}
