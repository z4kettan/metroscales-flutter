import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Light, dark or follow the phone, and whether to take colours from the
/// phone's wallpaper (Material You, Android 12 and newer).
class Appearance {
  const Appearance({this.mode = ThemeMode.system, this.wallpaperColours = false});
  final ThemeMode mode;
  final bool wallpaperColours;

  Appearance copyWith({ThemeMode? mode, bool? wallpaperColours}) =>
      Appearance(mode: mode ?? this.mode, wallpaperColours: wallpaperColours ?? this.wallpaperColours);
}

final appearanceProvider = NotifierProvider<AppearanceNotifier, Appearance>(AppearanceNotifier.new);

class AppearanceNotifier extends Notifier<Appearance> {
  static const _modeKey = 'ms_theme_mode';
  static const _wallpaperKey = 'ms_wallpaper_colours';

  @override
  Appearance build() {
    SharedPreferences.getInstance().then((p) {
      final mode = ThemeMode.values.where((m) => m.name == p.getString(_modeKey)).firstOrNull;
      state = Appearance(mode: mode ?? ThemeMode.system, wallpaperColours: p.getBool(_wallpaperKey) ?? false);
    });
    return const Appearance();
  }

  Future<void> setMode(ThemeMode mode) async {
    state = state.copyWith(mode: mode);
    (await SharedPreferences.getInstance()).setString(_modeKey, mode.name);
  }

  Future<void> setWallpaperColours(bool on) async {
    state = state.copyWith(wallpaperColours: on);
    (await SharedPreferences.getInstance()).setBool(_wallpaperKey, on);
  }
}
