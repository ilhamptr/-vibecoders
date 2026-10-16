import '../../core/network/api_client.dart';
import '../../domain/domain.dart';
import 'data/mock/mock_investor_data.dart';
import 'data/mock/mock_investor_store.dart';
import 'marketplace/data/marketplace_repository.dart';
import 'marketplace/data/fake_marketplace_repository.dart';
import 'project_detail/data/project_detail_repository.dart';
import 'project_detail/data/fake_project_detail_repository.dart';
import 'project_detail/data/api_project_detail_repository.dart';
import 'investment/data/investment_repository.dart';
import 'investment/data/fake_investment_repository.dart';
import 'investment/data/api_investment_repository.dart';
import 'home/data/investor_fund_repository.dart';
import 'home/data/fake_investor_fund_repository.dart';
import 'home/data/api_investor_fund_repository.dart';
import 'wallet/data/wallet_topup_repository.dart';
import 'wallet/data/fake_wallet_topup_repository.dart';
import 'portfolio/data/portfolio_repository.dart';
import 'portfolio/data/fake_portfolio_repository.dart';
import 'portfolio/data/api_portfolio_repository.dart';
import 'portfolio/data/api_user_investments_repository.dart';
import 'profile/data/investor_profile_repository.dart';
import 'profile/data/fake_investor_profile_repository.dart';
import 'profile/data/api_investor_profile_repository.dart';
import 'monitoring/data/investor_monitoring_repository.dart';
import 'monitoring/data/fake_investor_monitoring_repository.dart';
import 'monitoring/data/api_investor_monitoring_repository.dart';

/// Restores the dependency contract already used by Investor screens/tests.
class InvestorDependencies {
  const InvestorDependencies({
    required this.investor,
    required this.marketplace,
    required this.projectDetail,
    required this.investment,
    required this.portfolio,
    required this.userInvestments,
    required this.monitoring,
    required this.profile,
    required this.fund,
    required this.walletTopUp,
    this.isApiBacked = false,
  });
  final User investor;
  final MarketplaceRepository marketplace;
  final ProjectDetailRepository projectDetail;
  final InvestmentRepository investment;

  /// Home tab: active investments (`/investment/get-active-investment`).
  final PortfolioRepository portfolio;

  /// Portfolio tab: user investments filtered by status
  /// (`/investment/get-user-investments`).
  final PortfolioRepository userInvestments;

  final InvestorMonitoringRepository monitoring;
  final InvestorProfileRepository profile;
  final InvestorFundRepository fund;
  final WalletTopUpRepository walletTopUp;

  /// True when wired to the real backend. The invest flow uses this to apply
  /// backend rules (Rp10.000 minimum, server-side eligibility).
  final bool isApiBacked;

  factory InvestorDependencies.mock({
    MockInvestorStore? store,
    Duration latency = const Duration(milliseconds: 200),
  }) {
    final shared = store ?? MockInvestorStore.seeded();
    return InvestorDependencies(
      investor: MockInvestorData.investor,
      marketplace: FakeMarketplaceRepository(shared, latency: latency),
      projectDetail: FakeProjectDetailRepository(shared, latency: latency),
      investment: FakeInvestmentRepository(shared, latency: latency),
      portfolio: FakePortfolioRepository(shared, latency: latency),
      userInvestments: FakePortfolioRepository(shared, latency: latency),
      monitoring: FakeInvestorMonitoringRepository(shared, latency: latency),
      profile: FakeInvestorProfileRepository(MockInvestorData.investor.name),
      fund: FakeInvestorFundRepository(latency: latency),
      walletTopUp: FakeWalletTopUpRepository(latency: latency),
    );
  }

  /// Uses the real backend for the portfolio (active investments) and the
  /// investor's full name; keeps mocks for repositories not wired yet.
  factory InvestorDependencies.api(
    ApiClient api, {
    MockInvestorStore? store,
    Duration latency = const Duration(milliseconds: 200),
  }) {
    final shared = store ?? MockInvestorStore.seeded();
    final investor = MockInvestorData.investor;
    return InvestorDependencies(
      investor: investor,
      marketplace: FakeMarketplaceRepository(shared, latency: latency),
      projectDetail: ApiProjectDetailRepository(api),
      investment: ApiInvestmentRepository(api),
      portfolio: ApiPortfolioRepository(api, investor: investor),
      userInvestments: ApiUserInvestmentsRepository(api, investor: investor),
      monitoring: ApiInvestorMonitoringRepository(api, investor: investor),
      profile: ApiInvestorProfileRepository(api),
      fund: ApiInvestorFundRepository(api),
      walletTopUp: ApiWalletTopUpRepository(api),
      isApiBacked: true,
    );
  }
}
