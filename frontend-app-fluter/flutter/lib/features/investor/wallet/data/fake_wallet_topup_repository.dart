import 'wallet_topup_repository.dart';

/// Mock top-up for tests/mock mode. Does not open any real payment page.
class FakeWalletTopUpRepository implements WalletTopUpRepository {
  const FakeWalletTopUpRepository({
    this.latency = const Duration(milliseconds: 200),
  });

  final Duration latency;

  @override
  Future<TopUpResult> topUp(int amount) async {
    await Future<void>.delayed(latency);
    if (amount < ApiWalletTopUpRepository.minimumAmount) {
      throw const TopUpException('Minimum deposit Rp10.000.');
    }
    return const TopUpResult(
      referenceId: 'mock-ref',
      paymentLinkUrl: 'https://example.com/pay/mock',
      status: 'PENDING',
    );
  }
}
