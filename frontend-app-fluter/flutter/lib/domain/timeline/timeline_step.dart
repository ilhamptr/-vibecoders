import 'timeline_status.dart';

class TimelineStep {
  const TimelineStep({
    required this.id,
    required this.title,
    required this.status,
    this.description,
    this.occurredAt,
  });

  final String id;
  final String title;
  final String? description;
  final TimelineStatus status;
  final DateTime? occurredAt;

  bool get isCompleted => status == TimelineStatus.completed;
  bool get isCurrent => status == TimelineStatus.current;
}
