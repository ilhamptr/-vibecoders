import '../../../domain/money/money.dart';

/// Wallet totals shown on the farmer dashboard.
///
/// Mirrors `GET /investment/get-farmer-fund`:
/// `{"user_id": "...", "amount_to_withdraw": 0, "wallet_balance": 7400000}`.
class FarmerFund {
  const FarmerFund({
    required this.userId,
    required this.amountToWithdraw,
    required this.walletBalance,
  });

  final String userId;

  /// Amount currently queued for withdrawal.
  final Money amountToWithdraw;

  /// Balance the farmer can withdraw.
  final Money walletBalance;

  static const empty = FarmerFund(
    userId: '',
    amountToWithdraw: Money.zero,
    walletBalance: Money.zero,
  );
}

abstract interface class FarmerFundRepository {
  Future<FarmerFund> getFund();
}
