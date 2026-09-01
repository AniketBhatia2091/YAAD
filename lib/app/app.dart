import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';
import 'router.dart';
import 'theme/app_theme.dart';

class YaadApp extends ConsumerWidget {
  const YaadApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'YAAD',
      debugShowCheckedModeBanner: false,
      theme: YaadTheme.lightTheme,
      darkTheme: YaadTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
