import 'package:flutter/foundation.dart';

import '../../../../core/network/api_client.dart';
import '../../../../domain/money/money.dart';
import 'investor_fund_repository.dart';

/// [InvestorFundRepository] backed by `GET /investment/investment-fund`.
///
/// The request is authenticated, so a valid Bearer token must be present in
/// token storage (see `main.dart`). Response shape:
/// `{"user_id": "...", "invested_fund": <int>, "wallet_balance": <int>}`.
class ApiInvestorFundRepository implements InvestorFundRepository {
  const ApiInvestorFundRepository(this._api);

  final ApiClient _api;

  @override
  Future<InvestorFund> getFund() async {
    final res = await _api.get(
      '/investment/investment-fund',
      authenticated: true,
      // Free-tier ngrok otherwise returns its browser-warning HTML page.
      headers: const {'ngrok-skip-browser-warning': 'true'},
    );
    final data = res.data;
    if (data is! Map<String, dynamic>) {
      debugPrint(
        'ApiInvestorFundRepository: expected a JSON object, '
        'got ${data.runtimeType}',
      );
      throw StateError('Unexpected response shape from investment-fund.');
    }

    return InvestorFund(
      userId: (data['user_id'] ?? '').toString(),
      investedFund: Money(amount: _nonNegativeInt(data['invested_fund'])),
      walletBalance: Money(amount: _nonNegativeInt(data['wallet_balance'])),
    );
  }

  static int _nonNegativeInt(Object? value) {
    final parsed = (value as num?)?.toInt() ?? 0;
    return parsed < 0 ? 0 : parsed;
  }
}
