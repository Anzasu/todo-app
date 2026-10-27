import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_themes.dart';
import '../services/storage_service.dart';
import 'storage_provider.dart';

final themeProvider =
    StateNotifierProvider<ThemeNotifier, AppColorTheme>((ref) {
  return ThemeNotifier(ref.read(storageServiceProvider));
});

class ThemeNotifier extends StateNotifier<AppColorTheme> {
  final StorageService _storage;

  ThemeNotifier(this._storage) : super(AppColorTheme.values[0]) {
    final idx = _storage.loadThemeIndex();
    if (idx >= 0 && idx < AppColorTheme.values.length) {
      state = AppColorTheme.values[idx];
    }
  }

  Future<void> setTheme(AppColorTheme theme) async {
    state = theme;
    await _storage.saveThemeIndex(theme.index);
  }
}
