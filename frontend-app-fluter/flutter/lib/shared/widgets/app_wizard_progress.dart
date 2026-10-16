import 'package:flutter/material.dart';

class AppWizardProgress extends StatelessWidget {
  const AppWizardProgress({
    super.key,
    required this.totalSteps,
    required this.completedSteps,
    this.gap = 5,
    this.height = 4,
    this.activeColor,
    this.inactiveColor,
  }) : assert(totalSteps > 0),
       assert(completedSteps >= 0),
       assert(completedSteps <= totalSteps);

  final int totalSteps;
  final int completedSteps;
  final double gap;
  final double height;
  final Color? activeColor;
  final Color? inactiveColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: List.generate(totalSteps, (index) {
        final completed = index < completedSteps;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == totalSteps - 1 ? 0 : gap),
            child: Container(
              height: height,
              decoration: BoxDecoration(
                color: completed
                    ? activeColor ?? theme.colorScheme.primary
                    : inactiveColor ??
                          theme.colorScheme.onSurface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        );
      }),
    );
  }
}
