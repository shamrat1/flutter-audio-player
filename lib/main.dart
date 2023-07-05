import 'dart:io';

import 'package:audio_test/audio_file.dart';
import 'package:audio_test/audio_screen.dart';
import 'package:audio_test/color_schemes.dart';
import 'package:audio_test/constants.dart';
import 'package:audio_test/overlay_handler.dart';
import 'package:audio_test/overlay_service.dart';
import 'package:audio_test/playlist_files_screen.dart';
import 'package:flutter/material.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

void main() async {
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.ryanheise.bg_demo.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<OverlayHandlerProvider>(
      create: (_) => OverlayHandlerProvider(),
      child: MaterialApp(
        title: 'Simple Audio Player',
        theme: ThemeData(useMaterial3: true, colorScheme: lightColorScheme),
        darkTheme: ThemeData(useMaterial3: true, colorScheme: darkColorScheme),
        home: const MyHomePage(title: 'Simple Audio Player'),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  bool _playlisLoading = true;
  List<SongModel> songs = [];
  List<PlaylistModel> playlists = [];
  late TabController _tabController;
  int currentIndex = 0;
  TextEditingController nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    requestPermission();
    _tabController.addListener(tabChange);
  }

  @override
  void dispose() {
    super.dispose();
    _tabController.removeListener(tabChange);
    _tabController.dispose();
  }

  void tabChange() {
    setState(() {
      currentIndex = _tabController.index;
    });
  }

  Future<void> requestPermission() async {
    if (Platform.isAndroid) {
      var status = await Permission.storage.status;
      if (!status.isGranted) {
        await Permission.storage.request();
      }
    }
    _getAudioQuery();
    _getPlaylists();
  }

  Future<void> _getAudioQuery() async {
    if (!_loading) {
      setState(() {
        _loading = true;
      });
    }
    List<SongModel> audios = [];
    List<SongModel> myAudios = await OnAudioQuery().querySongs();
    for (var e in myAudios) {
      if ((e.duration ?? 0) > 5000) {
        audios.add(e);
      }
    }
    setState(() {
      songs = audios;
      _loading = false;
    });
  }

  Future<void> _getPlaylists() async {
    if (!_playlisLoading) {
      setState(() {
        _playlisLoading = true;
      });
    }
    var myplaylists = await OnAudioQuery().queryPlaylists();

    setState(() {
      playlists = myplaylists;
      _playlisLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        var state = Provider.of<OverlayHandlerProvider>(context, listen: false);
        if (state.overlayEntry != null && !state.inPipMode) {
          state.enablePip(16 / 9);
          return Future.value(false);
        }
        return Future.value(true);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          actions: [
            IconButton(
              onPressed: _getAudioQuery,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: "All Tracks"),
              Tab(text: "Playlists"),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            if (currentIndex == 0) {
              OverlayService().addAudioTitleOverlay(
                context,
                SingleAudioScreen(
                  audioUrls: songs,
                  shuffle: true,
                ),
              );
            } else {
              Constants.showBottomSheet(context, [
                const Text(
                  'Create a Playlist',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20.0,
                  ),
                ),
                const SizedBox(height: 16.0),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    label: const Text("Name of The Playlist"),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
                const SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: () async {
                    setState(() {
                      _playlisLoading = true;
                    });
                    await OnAudioQuery().createPlaylist(nameController.text);
                    await _getPlaylists();
                    nameController.clear();
                    setState(() {
                      _playlisLoading = false;
                    });
                    Navigator.pop(context);
                  },
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: 5,
                      horizontal: MediaQuery.of(context).size.width * 0.30,
                    ),
                    child: const Text('Save'),
                  ),
                ),
              ]);
            }
          },
          child: AnimatedCrossFade(
            firstChild: const Icon(Icons.shuffle_rounded),
            secondChild: const Icon(Icons.playlist_add_rounded),
            crossFadeState: currentIndex == 0
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            duration: const Duration(milliseconds: 400),
          ),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  RefreshIndicator(
                    onRefresh: () => _getAudioQuery(),
                    child: ListView.builder(
                      itemCount: songs.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(
                            songs[index].title,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge!
                                .copyWith(fontSize: 17),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            Constants.formatDuration(
                                (songs[index].duration ?? 0) ~/ 1000),
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
                          trailing: Constants.popupMenuForSongs(
                              context, playlists, songs[index]),
                          onTap: () {
                            OverlayService().addAudioTitleOverlay(
                                context,
                                SingleAudioScreen(
                                  audioUrls: [songs[index]],
                                ));
                          },
                        );
                      },
                    ),
                  ),
                  RefreshIndicator(
                    onRefresh: () => _getPlaylists(),
                    child: ListView.builder(
                      itemCount: playlists.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(playlists[index].playlist),
                          subtitle:
                              Text("${playlists[index].numOfSongs} Tracks"),
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(25),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.playlist_play_rounded,
                              color: Theme.of(context).colorScheme.background,
                              size: 35,
                            ),
                          ),
                          trailing: Constants.popupMenuForPlaylists(
                              context,
                              playlists[index],
                              TextEditingController(
                                  text: playlists[index].playlist)),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PlaylistFiles(
                                  playlist: playlists[index],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
