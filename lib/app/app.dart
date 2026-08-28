import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'theme/app_theme.dart';

class YaadApp extends ConsumerWidget {
  const YaadApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'YAAD',
      debugShowCheckedModeBanner: false,
      theme: YaadTheme.lightTheme,
      darkTheme: YaadTheme.darkTheme,
      themeMode: ThemeMode.light, // Modern light theme by default for Indian market utility
      routerConfig: router,
    );
  }
}
