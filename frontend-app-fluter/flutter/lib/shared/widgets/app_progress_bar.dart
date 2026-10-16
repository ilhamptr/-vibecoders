import 'package:flutter/material.dart';

class AppProgressBar extends StatelessWidget {
  const AppProgressBar({
    super.key,
    required this.value,
    this.height = 6,
    this.foregroundColor,
    this.backgroundColor,
    this.borderRadius = 999,
  }) : assert(value >= 0 && value <= 1);

  final double value;
  final double height;
  final Color? foregroundColor;
  final Color? backgroundColor;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        height: height,
        child: LinearProgressIndicator(
          value: value,
          color: foregroundColor ?? theme.colorScheme.primary,
          backgroundColor:
              backgroundColor ?? theme.dividerColor.withValues(alpha: 0.35),
        ),
      ),
    );
  }
}
