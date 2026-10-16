import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_response.dart';

/// Result of starting a wallet top-up via `POST /payment/top-up-wallet`.
/// Response: `{"reference_id", "payment_link_url", "status"}`.
class TopUpResult {
  const TopUpResult({
    required this.referenceId,
    required this.paymentLinkUrl,
    required this.status,
  });

  final String referenceId;

  /// Hosted payment page the user must open to complete the top-up.
  final String paymentLinkUrl;
  final String status;
}

/// Raised when the amount is below the backend minimum or rejected.
class TopUpException implements Exception {
  const TopUpException(this.message);
  final String message;

  @override
  String toString() => message;
}

abstract interface class WalletTopUpRepository {
  Future<TopUpResult> topUp(int amount);
}

class ApiWalletTopUpRepository implements WalletTopUpRepository {
  const ApiWalletTopUpRepository(this._api);

  final ApiClient _api;

  /// Backend minimum per the top-up contract.
  static const minimumAmount = 10000;

  static const _ngrokHeaders = <String, String>{
    'ngrok-skip-browser-warning': 'true',
  };

  @override
  Future<TopUpResult> topUp(int amount) async {
    if (amount < minimumAmount) {
      throw const TopUpException('Minimum deposit Rp10.000.');
    }

    final ApiResponse res;
    try {
      res = await _api.post(
        '/payment/top-up-wallet',
        authenticated: true,
        headers: _ngrokHeaders,
        body: {'amount': amount},
      );
    } on ApiException catch (error) {
      throw TopUpException(error.message);
    }

    final data = res.data;
    if (data is! Map<String, dynamic>) {
      throw const TopUpException('Respons top-up tidak dikenali.');
    }
    final link = (data['payment_link_url'] ?? '').toString();
    if (link.isEmpty) {
      throw const TopUpException('Tautan pembayaran tidak tersedia.');
    }
    return TopUpResult(
      referenceId: (data['reference_id'] ?? '').toString(),
      paymentLinkUrl: link,
      status: (data['status'] ?? '').toString(),
    );
  }
}
