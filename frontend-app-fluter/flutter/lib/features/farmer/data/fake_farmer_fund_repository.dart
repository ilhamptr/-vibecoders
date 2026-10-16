import '../../../domain/money/money.dart';
import 'farmer_fund_repository.dart';

/// In-memory [FarmerFundRepository] for mock mode and widget tests.
class FakeFarmerFundRepository implements FarmerFundRepository {
  const FakeFarmerFundRepository({
    this.fund = const FarmerFund(
      userId: 'mock-farmer',
      amountToWithdraw: Money.zero,
      walletBalance: Money(amount: 7400000),
    ),
    this.latency = const Duration(milliseconds: 200),
  });

  final FarmerFund fund;
  final Duration latency;

  @override
  Future<FarmerFund> getFund() async {
    await Future<void>.delayed(latency);
    return fund;
  }
}
