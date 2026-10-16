import '../../../../domain/domain.dart';
import '../../data/mock/mock_investor_store.dart';
import 'marketplace_repository.dart';

class FakeMarketplaceRepository implements MarketplaceRepository {
  const FakeMarketplaceRepository(
    this._store, {
    this.latency = const Duration(milliseconds: 250),
  });

  final MockInvestorStore _store;
  final Duration latency;

  @override
  Future<List<AgricultureProject>> getProjects({Commodity? commodity}) async {
    await Future<void>.delayed(latency);

    final projects = _store.projects.where(
      (project) => project.status == ProjectStatus.openForFunding,
    );

    if (commodity == null) {
      return projects.toList(growable: false);
    }

    return projects
        .where((project) => project.commodity == commodity)
        .toList(growable: false);
  }
}
