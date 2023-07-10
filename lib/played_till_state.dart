import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlayedTillProvider with ChangeNotifier {
  List<int> songsId = [];
  List<int> songsDuration = [];
  final String k = "played_till_list";

  init() async {
    SharedPreferences _preferences = await SharedPreferences.getInstance();
    List<String> data = _preferences.getStringList(k) ?? [];

    if (data.isNotEmpty) {
      songsId = [];
      songsDuration = [];
      for (var e in data) {
        if (e.isEmpty) {
          break;
        }
        var splited = e.split("_");
        songsId.add(int.parse(splited[0]));
        songsDuration.add(int.parse(splited[1]));
      }
    }
    notifyListeners();
  }

  addOrEdit(int id, int duration) async {
    SharedPreferences _preferences = await SharedPreferences.getInstance();
    List<String> data = _preferences.getStringList(k) ?? [];
    var index =
        data.indexWhere((element) => element.split("_")[0] == id.toString());
    if (index == -1) {
      data.add(id.toString() + "_" + duration.toString());
    } else {
      data[index] = id.toString() + "_" + duration.toString();
    }
    _preferences.setStringList(k, data);
    init();
  }

  remove(int id) async {
    SharedPreferences _preferences = await SharedPreferences.getInstance();
    List<String> data = _preferences.getStringList(k) ?? [];
    int index =
        data.indexWhere((element) => element.split("_")[0] == id.toString());
    data.removeAt(index);
    _preferences.setStringList(k, data);
    init();
  }

  int exists(int id) {
    return songsId.indexWhere((element) => element == id);
  }

  Duration getDuration(int index) {
    return Duration(seconds: songsDuration[index]);
  }
}
