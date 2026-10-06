import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_toast.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/brand_mark.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const BrandMark(size: 72),
            const SizedBox(height: 20),
            Text(AppConstants.appName, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 28),
            if (auth.hasError) ...[
              Text(
                AppToast.errorText(auth.error!),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              OutlinedButton(onPressed: () => ref.invalidate(authProvider), child: const Text('Try again')),
            ] else
              const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.4)),
          ]),
        ),
      ),
    );
  }
}
