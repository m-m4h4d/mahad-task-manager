import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/shared_prefs_service.dart';

class ThemeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final prefsService = ref.watch(sharedPrefsServiceProvider);
    return prefsService.isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }

  void toggleTheme() {
    state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    ref.read(sharedPrefsServiceProvider).setDarkMode(state == ThemeMode.dark);
  }
}

final themeControllerProvider = NotifierProvider<ThemeController, ThemeMode>(ThemeController.new);
