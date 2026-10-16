import '../../../../domain/domain.dart';
import '../../data/mock/mock_investor_store.dart';
import 'investment_repository.dart';

class FakeInvestmentRepository implements InvestmentRepository {
  const FakeInvestmentRepository(
    this._store, {
    this.latency = const Duration(milliseconds: 300),
  });

  final MockInvestorStore _store;
  final Duration latency;

  @override
  Future<Investment> createInvestment({
    required User investor,
    required String projectId,
    required Money amount,
  }) async {
    await Future<void>.delayed(latency);

    if (amount.amount <= 0) {
      throw ArgumentError.value(
        amount.amount,
        'amount',
        'Investment amount must be greater than zero.',
      );
    }

    final project = _store.findProjectById(projectId);

    if (project == null) {
      throw StateError('Project not found: $projectId');
    }

    if (project.status != ProjectStatus.openForFunding) {
      throw StateError('Project is not currently open for funding.');
    }

    final investment = Investment(
      id: 'investment-${DateTime.now().microsecondsSinceEpoch}',
      investor: investor,
      project: project,
      principal: amount,
      status: InvestmentStatus.active,
      investedAt: DateTime.now(),
    );

    _store.addInvestment(investment);

    return investment;
  }
}
