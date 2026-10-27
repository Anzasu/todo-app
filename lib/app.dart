import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/theme_provider.dart';
import 'theme/app_themes.dart';
import 'screens/home_screen.dart';

class IchBinBereitApp extends ConsumerWidget {
  const IchBinBereitApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    return MaterialApp(
      title: 'Ich bin bereit',
      theme: buildTheme(theme, Brightness.light),
      darkTheme: buildTheme(theme, Brightness.dark),
      themeMode: ThemeMode.system,
      locale: const Locale('de', 'DE'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('de', 'DE'), Locale('en', 'US')],
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
