import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../domain/money/money.dart';
import 'farmer_fund_repository.dart';

/// [FarmerFundRepository] backed by `GET /investment/get-farmer-fund`.
///
/// The request is authenticated, so a valid Bearer token must be present in
/// token storage (see `main.dart`). Response shape:
/// `{"user_id": "...", "amount_to_withdraw": <int>, "wallet_balance": <int>}`.
class ApiFarmerFundRepository implements FarmerFundRepository {
  const ApiFarmerFundRepository(this._api);

  final ApiClient _api;

  @override
  Future<FarmerFund> getFund() async {
    final res = await _api.get(
      '/investment/get-farmer-fund',
      authenticated: true,
      // Free-tier ngrok otherwise returns its browser-warning HTML page.
      headers: const {'ngrok-skip-browser-warning': 'true'},
    );
    final data = res.data;
    if (data is! Map<String, dynamic>) {
      debugPrint(
        'ApiFarmerFundRepository: expected a JSON object, '
        'got ${data.runtimeType}',
      );
      throw StateError('Unexpected response shape from get-farmer-fund.');
    }

    return FarmerFund(
      userId: (data['user_id'] ?? '').toString(),
      amountToWithdraw: Money(
        amount: _nonNegativeInt(data['amount_to_withdraw']),
      ),
      walletBalance: Money(amount: _nonNegativeInt(data['wallet_balance'])),
    );
  }

  static int _nonNegativeInt(Object? value) {
    final parsed = (value as num?)?.toInt() ?? 0;
    return parsed < 0 ? 0 : parsed;
  }
}
