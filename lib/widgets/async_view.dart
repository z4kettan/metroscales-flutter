import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/app_toast.dart';
import 'empty_state.dart';

/// Shows a spinner while loading, a friendly error with a retry button on
/// failure, and [builder] once the data is in.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({super.key, required this.value, required this.builder, this.onRetry});

  final AsyncValue<T> value;
  final Widget Function(T data) builder;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return value.when(
      skipLoadingOnRefresh: true,
      skipLoadingOnReload: true,
      data: builder,
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => EmptyState(
        icon: Icons.cloud_off_rounded,
        error: true,
        title: 'Could not load',
        message: AppToast.errorText(e),
        action: onRetry == null
            ? null
            : FilledButton.tonalIcon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try again'),
              ),
      ),
    );
  }
}

/// The same as [AsyncView] for use inside a [CustomScrollView].
class SliverAsyncView<T> extends StatelessWidget {
  const SliverAsyncView({super.key, required this.value, required this.builder, this.onRetry});

  final AsyncValue<T> value;
  final Widget Function(T data) builder;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (value.hasValue) return builder(value.requireValue);
    return SliverFillRemaining(
      hasScrollBody: false,
      child: AsyncView<T>(value: value, builder: (_) => const SizedBox.shrink(), onRetry: onRetry),
    );
  }
}
