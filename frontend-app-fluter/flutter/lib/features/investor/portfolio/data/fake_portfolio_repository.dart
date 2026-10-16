import '../../../../domain/domain.dart';
import '../../data/mock/mock_investor_store.dart';
import 'portfolio_repository.dart';

class FakePortfolioRepository implements PortfolioRepository {
  const FakePortfolioRepository(
    this._store, {
    this.latency = const Duration(milliseconds: 200),
  });

  final MockInvestorStore _store;
  final Duration latency;

  @override
  Future<List<Investment>> getInvestments({InvestmentStatus? status}) async {
    await Future<void>.delayed(latency);

    if (status == null) {
      return _store.investments;
    }

    return _store.investments
        .where((investment) => investment.status == status)
        .toList(growable: false);
  }

  @override
  Future<Investment?> getInvestmentById(String investmentId) async {
    await Future<void>.delayed(latency);
    return _store.findInvestmentById(investmentId);
  }
}
