import '../../common/project_timeline.dart';
import '../../data/mock/mock_investor_store.dart';
import 'investor_monitoring_repository.dart';

class FakeInvestorMonitoringRepository implements InvestorMonitoringRepository {
  const FakeInvestorMonitoringRepository(
    this._store, {
    this.latency = const Duration(milliseconds: 200),
  });

  final MockInvestorStore _store;
  final Duration latency;

  @override
  Future<InvestorMonitoring?> getMonitoring(String investmentId) async {
    await Future<void>.delayed(latency);
    final investment = _store.findInvestmentById(investmentId);
    if (investment == null) return null;
    return InvestorMonitoring(
      investment: investment,
      timeline: buildProjectTimeline(investment.project.status),
    );
  }
}
