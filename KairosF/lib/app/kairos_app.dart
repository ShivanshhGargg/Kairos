import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/brand_config.dart';
import 'router.dart';
import 'theme.dart';

class KairosApp extends ConsumerWidget {
  const KairosApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: BrandConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: KairosTheme.light(),
      darkTheme: KairosTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
