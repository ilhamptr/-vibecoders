import '../../../../domain/money/money.dart';

/// Wallet and invested-fund totals shown on the investor dashboard.
///
/// Mirrors `GET /investment/investment-fund`:
/// `{"user_id": "...", "invested_fund": 0, "wallet_balance": 0}`.
class InvestorFund {
  const InvestorFund({
    required this.userId,
    required this.investedFund,
    required this.walletBalance,
  });

  final String userId;
  final Money investedFund;
  final Money walletBalance;

  static const empty = InvestorFund(
    userId: '',
    investedFund: Money.zero,
    walletBalance: Money.zero,
  );
}

abstract interface class InvestorFundRepository {
  Future<InvestorFund> getFund();
}
