import 'package:flutter/foundation.dart';

import '../../../../core/network/api_client.dart';
import 'investor_profile_repository.dart';

/// Reads the signed-in user's name from `GET /user/full-name`, which returns
/// `{"full_name": "..."}`. Requires a Bearer token (see `main.dart`).
class ApiInvestorProfileRepository implements InvestorProfileRepository {
  const ApiInvestorProfileRepository(this._api);

  final ApiClient _api;

  @override
  Future<String> getFullName() async {
    final res = await _api.get(
      '/user/full-name',
      authenticated: true,
      // Free-tier ngrok otherwise returns its browser-warning HTML page.
      headers: const {'ngrok-skip-browser-warning': 'true'},
    );
    final data = res.data;
    final fullName = data is Map<String, dynamic> ? data['full_name'] : null;
    if (fullName is! String || fullName.trim().isEmpty) {
      debugPrint(
        'ApiInvestorProfileRepository: unexpected response ${data.runtimeType}',
      );
      throw StateError('Unexpected response shape from /user/full-name.');
    }
    return fullName.trim();
  }
}
