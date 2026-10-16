import 'package:flutter/material.dart';

class AppStatTile extends StatelessWidget {
  const AppStatTile({
    super.key,
    required this.label,
    required this.value,
    this.backgroundColor,
    this.labelColor,
    this.valueColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    this.borderRadius = 8,
    this.alignment = TextAlign.center,
  });

  final String label;
  final String value;
  final Color? backgroundColor;
  final Color? labelColor;
  final Color? valueColor;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final TextAlign alignment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.dividerColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              textAlign: alignment,
              style: theme.textTheme.bodySmall?.copyWith(
                color:
                    labelColor ??
                    theme.colorScheme.onSurface.withValues(alpha: 0.48),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              textAlign: alignment,
              style: theme.textTheme.titleMedium?.copyWith(
                color:
                    valueColor ??
                    theme.colorScheme.onSurface.withValues(alpha: 0.55),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
