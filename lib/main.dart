import 'package:audio_test/audio_file.dart';
import 'package:audio_test/audio_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

List<AudioFile> audios = [
  AudioFile(
    name: "Nobel Prize Ceremony 2018",
    url: "https://s3.amazonaws.com/scifri-episodes/scifri20181123-episode.mp3",
    artist: "Nobel Prize Authority",
  ),
  AudioFile(
    name: "Kalimba",
    url:
        "https://www.learningcontainer.com/wp-content/uploads/2020/02/Kalimba.mp3",
    artist: "Apple",
  ),
  AudioFile(
    name: "Test Audio 2MB",
    url:
        "https://freetestdata.com/wp-content/uploads/2021/09/Free_Test_Data_2MB_MP3.mp3",
    artist: "Test Audio",
  ),
  AudioFile(
    name: "Test Audio 5MB",
    url:
        "https://freetestdata.com/wp-content/uploads/2021/09/Free_Test_Data_5MB_MP3.mp3",
    artist: "Test Audio 5MB",
  ),
];
List<AudioFile> audio = [
  AudioFile(
    name: "Audio File 1",
    url: "https://s3.amazonaws.com/scifri-episodes/scifri20181123-episode.mp3",
    artist: "Amazon AWS",
  ),
];

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
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
  int _counter = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (ctx) => SingleAudioScreen(
                        audioUrls: audios,
                      )));
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
