import 'dart:io';

import 'package:audio_test/audio_file.dart';
import 'package:audio_test/audio_screen.dart';
import 'package:audio_test/color_schemes.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple Player',
      theme: ThemeData(useMaterial3: true, colorScheme: lightColorScheme),
      darkTheme: ThemeData(useMaterial3: true, colorScheme: darkColorScheme),
      home: const MyHomePage(title: 'Simple Player'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _loading = true;
  List<SongModel> songs = [];

  @override
  void initState() {
    super.initState();
    requestPermission();
  }

  Future<void> requestPermission() async {
    if (Platform.isAndroid) {
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        await Permission.storage.request();
      }
    }
    _getAudioQuery();
  }

  void _getAudioQuery() async {
    if (!_loading) {
      setState(() {
        _loading = true;
      });
    }
    List<SongModel> audios = await OnAudioQuery().querySongs();

    setState(() {
      songs = audios;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            onPressed: _getAudioQuery,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (ctx) => SingleAudioScreen(
                audioUrls: songs,
                shuffle: true,
              ),
            ),
          );
        },
        child: const Icon(Icons.shuffle_rounded),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: songs.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(
                    songs[index].title,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge!
                        .copyWith(fontSize: 20),
                  ),
                  subtitle: Text(
                    formatDuration((songs[index].duration ?? 0) ~/ 1000),
                  ),
                  leading: Hero(
                    tag: songs[index].data,
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: Theme.of(context).colorScheme.background,
                        size: 35,
                      ),
                    ),
                  ),
                  trailing: PopupMenuButton(
                    onSelected: (value) {
                      print(value);
                    },
                    itemBuilder: (context) {
                      return const [
                        PopupMenuItem(
                          value: 1,
                          child: Text("Share"),
                        ),
                        PopupMenuItem(
                          value: 2,
                          child: Text("Delete"),
                        ),
                        PopupMenuItem(
                          value: 3,
                          child: Text("Delete"),
                        ),
                      ];
                    },
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (ctx) => SingleAudioScreen(
                          audioUrls: [songs[index]],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  String formatDuration(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int remainingSeconds = seconds % 60;

    String hoursString = (hours < 10) ? '0$hours' : hours.toString();
    String minutesString = (minutes < 10) ? '0$minutes' : minutes.toString();
    String secondsString = (remainingSeconds < 10)
        ? '0$remainingSeconds'
        : remainingSeconds.toString();

    if (hours == 0 || hours < 0) {
      return '$minutesString:$secondsString';
    }

    return '$hoursString:$minutesString:$secondsString';
  }
}
