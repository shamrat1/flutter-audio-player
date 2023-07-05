import 'package:flutter/material.dart';
import 'package:on_audio_query/on_audio_query.dart';

class Constants {
  static const double BOTTOM_PADDING_PIP = 16;
  static const double VIDEO_HEIGHT_PIP = 200;
  static const double VIDEO_TITLE_HEIGHT_PIP = 82;

  static void showBottomSheet(BuildContext context, List<Widget> childrens,
      {double? height}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return SizedBox(
          width: double.infinity,
          height: height ?? (200 + MediaQuery.of(context).viewInsets.bottom),
          // padding: EdgeInsets.only(
          //   bottom: MediaQuery.of(context).viewInsets.bottom,
          // ),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16),
            child: ListView(
              children: [
                ...childrens,
              ],
            ),
          ),
        );
      },
    );
  }

  static String formatDuration(int seconds) {
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

  static PopupMenuButton<int> popupMenuForSongs(
      BuildContext context, List<PlaylistModel> playlists, SongModel song) {
    return PopupMenuButton(
      onSelected: (value) {
        if (value == 3) {
          Constants.showBottomSheet(
              context,
              [
                const Text(
                  'Select a Playlist',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20.0,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16.0),
                for (var i = 0; i < playlists.length; i++)
                  ListTile(
                    title: Text(playlists[i].playlist),
                    onTap: () async {
                      await OnAudioQuery()
                          .addToPlaylist(playlists[i].id, song.id);
                      Navigator.pop(context);
                    },
                  ),
              ],
              height: MediaQuery.of(context).size.height * 0.6);
        }
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
            child: Text("Add To Playlist"),
          ),
        ];
      },
    );
  }

  static PopupMenuButton<int> popupMenuForPlaylists(
    BuildContext context,
    PlaylistModel playlist,
    TextEditingController controller,
  ) {
    return PopupMenuButton(
      onSelected: (value) {
        if (value == 1) {
          Constants.showBottomSheet(context, [
            Text(
              'Edit ${playlist.playlist}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20.0,
              ),
            ),
            const SizedBox(height: 16.0),
            TextField(
              controller: controller,
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
                try {
                  await OnAudioQuery()
                      .renamePlaylist(playlist.id, controller.text);

                  Navigator.pop(context);
                } catch (e) {
                  print(e.toString());
                }
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
        } else if (value == 2) {
          OnAudioQuery().removePlaylist(playlist.id);
        }
      },
      itemBuilder: (context) {
        return const [
          PopupMenuItem(
            value: 1,
            child: Text("Rename"),
          ),
          PopupMenuItem(
            value: 2,
            child: Text("Delete"),
          ),
        ];
      },
    );
  }
}
