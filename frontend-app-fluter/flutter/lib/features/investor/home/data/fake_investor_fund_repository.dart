import '../../../../domain/money/money.dart';
import 'investor_fund_repository.dart';

/// In-memory [InvestorFundRepository] for mock mode and widget tests.
class FakeInvestorFundRepository implements InvestorFundRepository {
  const FakeInvestorFundRepository({
    this.fund = const InvestorFund(
      userId: 'mock-investor',
      investedFund: Money(amount: 12500000),
      walletBalance: Money(amount: 3000000),
    ),
    this.latency = const Duration(milliseconds: 200),
  });

  final InvestorFund fund;
  final Duration latency;

  @override
  Future<InvestorFund> getFund() async {
    await Future<void>.delayed(latency);
    return fund;
  }
}
