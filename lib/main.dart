import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fvp/fvp.dart' as fvp;
import 'core/database/database_provider.dart';
import 'core/database/isar_service.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/services/app_settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // video_player НЕ имеет нативной реализации на Windows/Linux — без регистрации
  // плагина триммер и превью плашки падают с UnimplementedError. fvp подключает
  // MDK-бэкенд для desktop-платформ.
  if (Platform.isWindows || Platform.isLinux) {
    fvp.registerWith();
  }

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FLUTTER ERROR: ${details.exception}\n${details.stack}');
  };

  await AppSettingsService.instance.init();
  final isarService = IsarService();
  await isarService.init();

  runApp(
    ProviderScope(
      overrides: [
        isarServiceProvider.overrideWithValue(isarService),
      ],
      child: const TTVideoAutomatorApp(),
    ),
  );
}

class TTVideoAutomatorApp extends StatelessWidget {
  const TTVideoAutomatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: appRouter,
    );
  }
}
