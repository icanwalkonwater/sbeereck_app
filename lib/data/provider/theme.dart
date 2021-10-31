import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const themeKey = 'theme';

class ThemeModel extends ChangeNotifier {
  Future init() async {
    _storage = await SharedPreferences.getInstance();
    if (_storage.containsKey(themeKey)) {
      _mode = Brightness.values[_storage.getInt(themeKey)!];
    }
  }

  late SharedPreferences _storage;

  Brightness _mode = Brightness.light;

  Brightness get theme => _mode;

  Future switchTheme() async {
    if (_mode == Brightness.light) {
      _mode = Brightness.dark;
    } else {
      _mode = Brightness.light;
    }

    await _storage.setInt('theme', _mode.index);
    notifyListeners();
  }
}
