import 'package:flutter/material.dart';

import '../../../shared/shared.dart';

/// Explicit async states used by every Investor controller.
enum LoadStatus { initial, loading, success, empty, error }

/// Prevents notifying listeners after an in-flight async call outlives the
/// widget that owned the controller.
mixin SafeNotifier on ChangeNotifier {
  bool _disposed = false;

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// Renders loading / error / empty / success for a [LoadStatus].
class StatusView extends StatelessWidget {
  const StatusView({
    super.key,
    required this.status,
    required this.onRetry,
    required this.emptyMessage,
    required this.builder,
    this.errorMessage = 'Data belum dapat dimuat.',
    this.emptyAction,
  });

  final LoadStatus status;
  final VoidCallback onRetry;
  final String emptyMessage;
  final String errorMessage;
  final Widget? emptyAction;
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case LoadStatus.initial:
      case LoadStatus.loading:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Center(child: CircularProgressIndicator()),
        );
      case LoadStatus.error:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(errorMessage, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              AppButton(label: 'Coba lagi', expand: false, onPressed: onRetry),
            ],
          ),
        );
      case LoadStatus.empty:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emptyMessage, textAlign: TextAlign.center),
              ?emptyAction,
            ],
          ),
        );
      case LoadStatus.success:
        return builder(context);
    }
  }
}
