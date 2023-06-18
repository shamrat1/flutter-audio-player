import 'package:audio_test/audio_file.dart';
import 'package:audio_test/seekbar.dart';
import 'package:flutter/material.dart';
import 'package:audio_session/audio_session.dart';
import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';

class SingleAudioScreen extends StatefulWidget {
  SingleAudioScreen({Key? key, required this.audioUrls}) : super(key: key);
  final List<AudioFile> audioUrls;

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
          children: widget.audioUrls
              .map((e) => AudioSource.uri(Uri.parse(e.url)))
              .toList());
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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(actions: [
          IconButton(
              onPressed: () => Navigator.pop(context), icon: Icon(Icons.close))
        ]),
        body: SafeArea(
          child: StreamBuilder<AudioPlayerStreams>(
              stream: _playerStream,
              builder: (context, playerSnapshot) {
                // player.sequenceStateStream

                var playerData = playerSnapshot.data;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        (playerData?.currentIndex ?? 0).toString(),
                        style: Theme.of(context).textTheme.headline1,
                      ),
                    ),

                    Text(
                      widget.audioUrls[playerData?.currentIndex ?? 0].name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      widget.audioUrls[playerData?.currentIndex ?? 0].artist,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      (playerData?.sequence?.currentIndex ?? 0).toString(),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    // Display play/pause button and volume/speed sliders.
                    ControlButtons(player),
                    // Display seek bar. Using StreamBuilder, this widget rebuilds
                    // each time the position, buffered position or duration changes.
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
        IconButton(
          onPressed: () {
            player.seekToPrevious();
          },
          icon: const Icon(Icons.skip_previous),
        ),
        // Opens volume slider dialog
        IconButton(
          icon: const Icon(Icons.volume_up),
          onPressed: () {
            showSliderDialog(
              context: context,
              title: "Adjust volume",
              divisions: 10,
              min: 0.0,
              max: 1.0,
              value: player.volume,
              stream: player.volumeStream,
              onChanged: player.setVolume,
            );
          },
        ),

        /// This StreamBuilder rebuilds whenever the player state changes, which
        /// includes the playing/paused state and also the
        /// loading/buffering/ready state. Depending on the state we show the
        /// appropriate button or loading indicator.
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
                icon: const Icon(Icons.play_arrow),
                iconSize: 64.0,
                onPressed: player.play,
              );
            } else if (processingState != ProcessingState.completed) {
              return IconButton(
                icon: const Icon(Icons.pause),
                iconSize: 64.0,
                onPressed: player.pause,
              );
            } else {
              return IconButton(
                icon: const Icon(Icons.replay),
                iconSize: 64.0,
                onPressed: () => player.seek(Duration.zero),
              );
            }
          },
        ),
        // Opens speed slider dialog
        StreamBuilder<double>(
          stream: player.speedStream,
          builder: (context, snapshot) => IconButton(
            icon: Text("${snapshot.data?.toStringAsFixed(1)}x",
                style: const TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () {
              showSliderDialog(
                context: context,
                title: "Adjust speed",
                divisions: 10,
                min: 0.5,
                max: 1.5,
                value: player.speed,
                stream: player.speedStream,
                onChanged: player.setSpeed,
              );
            },
          ),
        ),
        IconButton(
          onPressed: () {
            player.seekToNext();
          },
          icon: Icon(
            Icons.skip_next,
          ),
        ),
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
