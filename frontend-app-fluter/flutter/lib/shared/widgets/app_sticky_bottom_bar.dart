import 'package:flutter/material.dart';

class AppStickyBottomBar extends StatelessWidget {
  const AppStickyBottomBar({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(24, 12, 24, 12),
    this.backgroundColor,
    this.showTopBorder = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final bool showTopBorder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: backgroundColor ?? theme.colorScheme.surface,
      child: Container(
        decoration: BoxDecoration(
          border: showTopBorder
              ? Border(
                  top: BorderSide(
                    color: theme.dividerColor.withValues(alpha: 0.45),
                  ),
                )
              : null,
        ),
        child: SafeArea(
          top: false,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
