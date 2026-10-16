import '../../../../domain/domain.dart';
import 'fund_breakdown.dart';

/// An investment together with the data shown on its detail page.
class InvestorMonitoring {
  const InvestorMonitoring({
    required this.investment,
    required this.timeline,
    this.fundBreakdown,
    this.images = const [],
  });

  final Investment investment;
  final List<TimelineStep> timeline;

  /// Cost breakdown from the fund-details endpoint; null until loaded or when
  /// the backend has none.
  final FundBreakdown? fundBreakdown;

  /// Area image URLs (ordered). Empty when the area has no photos.
  final List<String> images;

  TimelineStep? get currentStep {
    for (final step in timeline) {
      if (step.isCurrent) return step;
    }
    return null;
  }
}

abstract interface class InvestorMonitoringRepository {
  Future<InvestorMonitoring?> getMonitoring(String investmentId);
}
