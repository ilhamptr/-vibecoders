import 'package:flutter/material.dart';

import '../../features/farmer/data/farmer_repository.dart';
import '../../features/farmer/data/farmer_fund_repository.dart';
import '../../features/farmer/data/fake_farmer_fund_repository.dart';
import '../../features/farmer/data/farmer_investment_repository.dart';
import '../../features/farmer/data/fake_farmer_investment_repository.dart';
import '../../features/farmer/data/mock_farmer_store.dart';
import '../../features/farmer/shell/farmer_shell.dart';
import '../../features/investor/wallet/data/wallet_topup_repository.dart';
import '../../features/investor/wallet/data/fake_wallet_topup_repository.dart';
import '../../features/farmer/proposal/presentation/pages/proposal_wizard_page.dart';
import '../../features/farmer/proposal/presentation/pages/proposal_detail_page.dart';
import '../../features/farmer/wallet/farmer_wallet_page.dart';

abstract final class FarmerRoutes {
  static const home = '/farmer/home';
  static const proposals = '/farmer/proposals';
  static const createProposal = '/farmer/proposals/create';
  static const wallet = '/farmer/wallet';
  static FarmerRepository repository = MockFarmerStore();

  /// Wallet/withdrawable totals shown on the farmer dashboard.
  ///
  /// Defaults to an in-memory fake so widget tests and mock runs still render.
  /// `main` overrides this with [ApiFarmerFundRepository] so the balance comes
  /// from `GET /investment/get-farmer-fund`.
  static FarmerFundRepository fundRepository = const FakeFarmerFundRepository();

  /// Wallet deposit via `POST /payment/top-up-wallet`.
  ///
  /// Defaults to an in-memory fake so widget tests and mock runs don't open a
  /// real payment page. `main` overrides this with [ApiWalletTopUpRepository].
  static WalletTopUpRepository walletTopUp = const FakeWalletTopUpRepository();

  /// Dashboard project list via `GET /investment/get-farmers-investments`.
  /// `main` overrides this with [ApiFarmerInvestmentRepository].
  static FarmerInvestmentRepository investmentRepository =
      FakeFarmerInvestmentRepository();
  static String proposalDetail(String id) => '/farmer/proposals/$id';
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final name = settings.name ?? '';
    final Widget page;
    if (name == home || name == proposals) {
      page = FarmerShell(
        repository: repository,
        fundRepository: fundRepository,
        walletTopUp: walletTopUp,
        investmentRepository: investmentRepository,
        initialIndex: name == proposals ? 1 : 0,
      );
    } else if (name == createProposal) {
      page = ProposalWizardPage(repository: repository);
    } else if (name == wallet) {
      page = FarmerWalletPage(repository: repository);
    } else if (name.startsWith('$proposals/')) {
      page = ProposalDetailPage(
        repository: repository,
        proposalId: name.substring(proposals.length + 1),
      );
    } else {
      return null;
    }
    return MaterialPageRoute<dynamic>(settings: settings, builder: (_) => page);
  }
}
