import '../../../domain/domain.dart';
import '../../../shared/shared.dart';

const _stageTitles = [
  'Persiapan lahan',
  'Penanaman',
  'Pemupukan & Perawatan',
  'Panen dan distribusi hasil',
];

const _stageDescriptions = [
  'Lahan sedang disiapkan',
  'Bibit sedang ditanam',
  'Tanaman dalam perawatan',
  'Panen dan distribusi hasil berlangsung',
];

/// Projects the existing [ProjectStatus] onto the four-stage cycle used by the
/// design. This is a derived view of shared domain data, not a seeded record.
List<TimelineStep> buildProjectTimeline(ProjectStatus status) {
  final stage = switch (status) {
    ProjectStatus.draft ||
    ProjectStatus.openForFunding ||
    ProjectStatus.fullyFunded ||
    ProjectStatus.landPreparation => 0,
    ProjectStatus.planting => 1,
    ProjectStatus.growing => 2,
    ProjectStatus.harvesting || ProjectStatus.distribution => 3,
    ProjectStatus.completed => _stageTitles.length,
    ProjectStatus.cancelled => -1,
  };
  final awaitingFunding =
      status == ProjectStatus.draft ||
      status == ProjectStatus.openForFunding ||
      status == ProjectStatus.fullyFunded;

  return [
    for (var i = 0; i < _stageTitles.length; i++)
      TimelineStep(
        id: 'stage-$i',
        title: _stageTitles[i],
        status: i < stage
            ? TimelineStatus.completed
            : i == stage
            ? TimelineStatus.current
            : TimelineStatus.upcoming,
        description: i == stage
            ? (awaitingFunding && i == 0
                  ? 'Menunggu pendanaan terpenuhi'
                  : _stageDescriptions[i])
            : null,
      ),
  ];
}

List<AppTimelineItemData> timelineItems(List<TimelineStep> steps) => [
  for (final step in steps)
    AppTimelineItemData(
      title: step.title,
      subtitle: step.description == null
          ? null
          : '${step.description} • Simulasi',
      state: switch (step.status) {
        TimelineStatus.completed => AppTimelineItemState.completed,
        TimelineStatus.current => AppTimelineItemState.current,
        TimelineStatus.upcoming => AppTimelineItemState.upcoming,
      },
    ),
];
