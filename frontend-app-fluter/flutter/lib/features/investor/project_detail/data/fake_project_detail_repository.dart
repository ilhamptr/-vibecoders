import '../../../../domain/domain.dart';
import '../../data/mock/mock_investor_store.dart';
import 'project_detail_repository.dart';

class FakeProjectDetailRepository implements ProjectDetailRepository {
  const FakeProjectDetailRepository(
    this._store, {
    this.latency = const Duration(milliseconds: 200),
  });

  final MockInvestorStore _store;
  final Duration latency;

  @override
  Future<AgricultureProject?> getProjectById(String projectId) async {
    await Future<void>.delayed(latency);
    return _store.findProjectById(projectId);
  }
}
