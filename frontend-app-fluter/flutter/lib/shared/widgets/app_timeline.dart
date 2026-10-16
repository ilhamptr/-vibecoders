import 'package:flutter/material.dart';

enum AppTimelineItemState { completed, current, upcoming }

class AppTimelineItemData {
  const AppTimelineItemData({
    required this.title,
    required this.state,
    this.subtitle,
    this.trailing,
    this.detail,
  });

  final String title;
  final AppTimelineItemState state;
  final String? subtitle;
  final String? trailing;
  final String? detail;
}

class AppTimeline extends StatelessWidget {
  const AppTimeline({
    super.key,
    required this.items,
    this.activeColor,
    this.inactiveColor,
    this.itemSpacing = 14,
  });

  final List<AppTimelineItemData> items;
  final Color? activeColor;
  final Color? inactiveColor;
  final double itemSpacing;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final active = activeColor ?? theme.colorScheme.primary;
    final inactive =
        inactiveColor ?? theme.colorScheme.onSurface.withValues(alpha: 0.32);

    return Column(
      children: List.generate(items.length, (index) {
        final item = items[index];
        final isLast = index == items.length - 1;

        return Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : itemSpacing),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  child: Column(
                    children: [
                      _TimelineDot(
                        state: item.state,
                        activeColor: active,
                        inactiveColor: inactive,
                      ),
                      if (!isLast)
                        Expanded(
                          child: Container(
                            width: 1,
                            margin: const EdgeInsets.only(top: 4),
                            color: item.state == AppTimelineItemState.upcoming
                                ? inactive.withValues(alpha: 0.55)
                                : active.withValues(alpha: 0.3),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _TimelineContent(item: item, inactiveColor: inactive),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _TimelineDot extends StatelessWidget {
  const _TimelineDot({
    required this.state,
    required this.activeColor,
    required this.inactiveColor,
  });

  final AppTimelineItemState state;
  final Color activeColor;
  final Color inactiveColor;

  @override
  Widget build(BuildContext context) {
    switch (state) {
      case AppTimelineItemState.completed:
        return Container(
          width: 13,
          height: 13,
          decoration: BoxDecoration(color: activeColor, shape: BoxShape.circle),
        );
      case AppTimelineItemState.current:
        return Container(
          width: 15,
          height: 15,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            shape: BoxShape.circle,
            border: Border.all(color: activeColor, width: 1.5),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: activeColor,
              shape: BoxShape.circle,
            ),
          ),
        );
      case AppTimelineItemState.upcoming:
        return Container(
          width: 13,
          height: 13,
          decoration: BoxDecoration(
            color: inactiveColor,
            shape: BoxShape.circle,
          ),
        );
    }
  }
}

class _TimelineContent extends StatelessWidget {
  const _TimelineContent({required this.item, required this.inactiveColor});

  final AppTimelineItemData item;
  final Color inactiveColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final upcoming = item.state == AppTimelineItemState.upcoming;
    final textColor = upcoming ? inactiveColor : theme.colorScheme.onSurface;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (item.subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  item.subtitle!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: inactiveColor,
                  ),
                ),
              ],
              if (item.detail != null) ...[
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: theme.dividerColor.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    item.detail!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: inactiveColor,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (item.trailing != null) ...[
          const SizedBox(width: 12),
          Text(
            item.trailing!,
            textAlign: TextAlign.right,
            style: theme.textTheme.bodySmall?.copyWith(color: inactiveColor),
          ),
        ],
      ],
    );
  }
}
