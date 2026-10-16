import '../../../../domain/domain.dart';
import 'mock_investor_data.dart';

class MockInvestorStore {
  MockInvestorStore({
    required List<AgricultureProject> projects,
    required List<Investment> investments,
  }) : _projects = List.of(projects),
       _investments = List.of(investments);

  factory MockInvestorStore.seeded() {
    final projects = MockInvestorData.createProjects();

    return MockInvestorStore(
      projects: projects,
      investments: MockInvestorData.createInvestments(projects),
    );
  }

  final List<AgricultureProject> _projects;
  final List<Investment> _investments;

  List<AgricultureProject> get projects => List.unmodifiable(_projects);

  List<Investment> get investments => List.unmodifiable(_investments);

  AgricultureProject? findProjectById(String projectId) {
    for (final project in _projects) {
      if (project.id == projectId) return project;
    }
    return null;
  }

  Investment? findInvestmentById(String investmentId) {
    for (final investment in _investments) {
      if (investment.id == investmentId) return investment;
    }
    return null;
  }

  void addInvestment(Investment investment) {
    _investments.insert(0, investment);
  }
}
