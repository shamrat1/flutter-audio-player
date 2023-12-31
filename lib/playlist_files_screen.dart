import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:audio_test/audio_screen.dart';
import 'package:audio_test/constants.dart';
import 'package:audio_test/overlay_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

class PlaylistFiles extends StatefulWidget {
  const PlaylistFiles({super.key, required this.playlist});
  final PlaylistModel playlist;
  @override
  State<PlaylistFiles> createState() => _PlaylistFilesState();
}

class _PlaylistFilesState extends State<PlaylistFiles> {
  bool _loading = false;
  List<SongModel> songs = [];

  @override
  void initState() {
    super.initState();
    _getAudioQuery();
  }

  void _getAudioQuery() async {
    if (!_loading) {
      setState(() {
        _loading = true;
      });
    }
    List<SongModel> audios = await OnAudioQuery()
        .queryAudiosFrom(AudiosFromType.PLAYLIST, widget.playlist.id);

    setState(() {
      songs = audios;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AnimatedTextKit(
          totalRepeatCount: 1,
          animatedTexts: [
            TypewriterAnimatedText(
              widget.playlist.playlist,
              textStyle: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w400,
              ),
              speed: const Duration(milliseconds: 150),
            ),
          ],
        ),
        actions: songs.isNotEmpty
            ? [
                IconButton(
                  onPressed: () => OverlayService().addAudioTitleOverlay(
                      context,
                      SingleAudioScreen(
                        audioUrls: songs,
                      )),
                  icon: const Icon(Icons.play_arrow_rounded),
                ),
                IconButton(
                  onPressed: () => OverlayService().addAudioTitleOverlay(
                      context,
                      SingleAudioScreen(
                        audioUrls: songs,
                        shuffle: true,
                      )),
                  icon: const Icon(CupertinoIcons.shuffle),
                ),
              ]
            : null,
      ),
      body: ListView.builder(
        itemCount: songs.length,
        itemBuilder: (context, i) {
          return ListTile(
            title: Text(
              songs[i].title,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge!
                  .copyWith(fontSize: 17),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              Constants.formatDuration((songs[i].duration ?? 0) ~/ 1000),
            ),
            leading: Hero(
              tag: songs[i].data,
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
              onSelected: (value) async {
                if (value == 2) {
                  setState(() {
                    _loading = true;
                  });
                  await OnAudioQuery()
                      .removeFromPlaylist(widget.playlist.id, songs[i].id);
                  _getAudioQuery();
                  setState(() {
                    _loading = false;
                  });
                }
              },
              itemBuilder: (context) {
                return [
                  const PopupMenuItem(
                    value: 1,
                    child: Text("Share"),
                  ),
                  PopupMenuItem(
                    value: 2,
                    child: Text(
                      "Remove from ${widget.playlist.playlist}",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ];
              },
            ),
            onTap: () {
              OverlayService().addAudioTitleOverlay(
                  context,
                  SingleAudioScreen(
                    audioUrls: songs,
                    index: i,
                  ));
            },
          );
        },
      ),
    );
  }
}
