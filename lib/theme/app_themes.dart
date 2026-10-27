import 'package:flutter/material.dart';

enum AppColorTheme {
  rosa,
  purpleRosa,
  hellblau,
  pastellRegenbogen,
  mitternachtsblau,
  weinrot,
  dunkelgruen,
}

class AppThemeConfig {
  final String name;
  final Color seed;

  const AppThemeConfig({required this.name, required this.seed});
}

const appThemeConfigs = [
  AppThemeConfig(name: 'Rosa', seed: Color(0xFFE91E8C)),
  AppThemeConfig(name: 'Lila & Rosa', seed: Color(0xFF8B3DBF)),
  AppThemeConfig(name: 'Hellblau', seed: Color(0xFF0288D1)),
  AppThemeConfig(name: 'Pastell-Regenbogen', seed: Color(0xFF9575CD)),
  AppThemeConfig(name: 'Mitternachtsblau', seed: Color(0xFF1A237E)),
  AppThemeConfig(name: 'Weinrot', seed: Color(0xFF880E4F)),
  AppThemeConfig(name: 'Dunkelgrün', seed: Color(0xFF1B5E20)),
];

ThemeData buildTheme(AppColorTheme theme, Brightness brightness) {
  final config = appThemeConfigs[theme.index];
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: config.seed,
      brightness: brightness,
    ),
    useMaterial3: true,
    cardTheme: CardThemeData(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
