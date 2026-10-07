import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_router.dart';
import 'providers/appearance_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('en_IN');
  runApp(const ProviderScope(child: MetroScalesApp()));
}

class MetroScalesApp extends ConsumerWidget {
  const MetroScalesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appearance = ref.watch(appearanceProvider);
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        final useWallpaper = appearance.wallpaperColours && lightDynamic != null && darkDynamic != null;
        return MaterialApp.router(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          themeMode: appearance.mode,
          theme: AppTheme.light(useWallpaper ? lightDynamic.harmonized() : null),
          darkTheme: AppTheme.dark(useWallpaper ? darkDynamic.harmonized() : null),
          routerConfig: ref.watch(routerProvider),
        );
      },
    );
  }
}
