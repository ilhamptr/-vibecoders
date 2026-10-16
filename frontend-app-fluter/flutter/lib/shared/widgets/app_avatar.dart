import 'package:flutter/material.dart';

class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    this.image,
    this.child,
    this.size = 40,
    this.borderRadius = 8,
    this.backgroundColor,
  }) : assert(
         image == null || child == null,
         'Use either image or child, not both.',
       );

  final ImageProvider<Object>? image;
  final Widget? child;
  final double size;
  final double borderRadius;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: size,
        height: size,
        color: backgroundColor ?? theme.dividerColor.withValues(alpha: 0.25),
        foregroundDecoration: image == null
            ? null
            : BoxDecoration(
                image: DecorationImage(image: image!, fit: BoxFit.cover),
              ),
        child: image == null
            ? Center(
                child:
                    child ??
                    Icon(
                      Icons.person_outline,
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.55,
                      ),
                    ),
              )
            : null,
      ),
    );
  }
}
