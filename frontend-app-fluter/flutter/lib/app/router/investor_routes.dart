import 'package:flutter/material.dart';

import '../../core/config/app_environment.dart';
import '../../main.dart' show apiClient;
import '../../features/investor/common/investment_math.dart';
import '../../features/investor/investor_dependencies.dart';
import '../../features/investor/shell/investor_shell.dart';
import '../../features/investor/project_detail/presentation/pages/project_detail_page.dart';
import '../../features/investor/investment/presentation/pages/investment_flow_page.dart';
import '../../features/investor/monitoring/presentation/pages/investor_monitoring_page.dart';

abstract final class InvestorRoutes {
  static const home = '/investor/home';
  static const marketplace = '/investor/marketplace';
  static const portfolio = '/investor/portfolio';
  /// Real backend when API_BASE_URL is set; mocks otherwise (e.g. in tests).
  static InvestorDependencies dependencies = AppEnvironment.apiBaseUrl.isEmpty
      ? InvestorDependencies.mock()
      : InvestorDependencies.api(apiClient);
  static String projectDetail(String projectId) =>
      '/investor/marketplace/projects/$projectId';
  static String invest(String projectId) => '/investor/invest/$projectId';
  static String portfolioProject(String projectId) =>
      '/investor/portfolio/projects/$projectId';
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final name = settings.name ?? '';
    final d = dependencies;
    final Widget page;
    if (name == home || name == marketplace || name == portfolio) {
      page = InvestorShell(
        dependencies: d,
        initialIndex: name == marketplace
            ? 1
            : name == portfolio
            ? 2
            : 0,
      );
    } else if (name.startsWith('/investor/marketplace/projects/')) {
      page = ProjectDetailPage(
        repository: d.projectDetail,
        projectId: name.substring('/investor/marketplace/projects/'.length),
      );
    } else if (name.startsWith('/investor/invest/')) {
      page = InvestmentFlowPage(
        projectRepository: d.projectDetail,
        investmentRepository: d.investment,
        investor: d.investor,
        projectId: name.substring('/investor/invest/'.length),
        minimumAmount: d.isApiBacked ? 10000 : InvestmentAmountValidator.minimum,
        requireOpenFunding: !d.isApiBacked,
      );
    } else if (name.startsWith('/investor/portfolio/projects/')) {
      page = InvestorMonitoringPage(
        repository: d.monitoring,
        investmentId: name.substring('/investor/portfolio/projects/'.length),
      );
    } else {
      return null;
    }
    return MaterialPageRoute<dynamic>(settings: settings, builder: (_) => page);
  }
}
