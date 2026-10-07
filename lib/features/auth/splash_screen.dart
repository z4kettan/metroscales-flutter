import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_toast.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/brand_mark.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const BrandMark(size: 84),
            const SizedBox(height: 24),
            Text(AppConstants.appName, style: context.tt.headlineMedium),
            const SizedBox(height: 32),
            if (auth.hasError) ...[
              Text(
                AppToast.errorText(auth.error!),
                textAlign: TextAlign.center,
                style: TextStyle(color: context.cs.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(onPressed: () => ref.invalidate(authProvider), child: const Text('Try again')),
            ] else
              const SizedBox(width: 120, child: LinearProgressIndicator()),
          ]),
        ),
      ),
    );
  }
}
