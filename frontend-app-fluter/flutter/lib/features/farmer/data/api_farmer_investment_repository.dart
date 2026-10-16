import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../domain/money/money.dart';
import 'farmer_investment_repository.dart';

/// [FarmerInvestmentRepository] backed by
/// `GET /investment/get-farmers-investments?investment_status=<status>`.
///
/// Response: `{"investments": [{id, commodity, status, number_of_investors,
/// end_date, target_amount, collected_amount, roi, area_name, images}]}`.
class ApiFarmerInvestmentRepository implements FarmerInvestmentRepository {
  const ApiFarmerInvestmentRepository(this._api);

  final ApiClient _api;

  static const _ngrokHeaders = <String, String>{
    'ngrok-skip-browser-warning': 'true',
  };

  @override
  Future<List<FarmerInvestment>> getInvestments(
    FarmerInvestmentStatus status,
  ) async {
    final res = await _api.get(
      '/investment/get-farmers-investments',
      authenticated: true,
      queryParameters: {'investment_status': status.apiValue},
      headers: _ngrokHeaders,
    );
    final data = res.data;
    final list = data is Map<String, dynamic> ? data['investments'] : data;
    if (list is! List) {
      debugPrint(
        'ApiFarmerInvestmentRepository: unexpected response shape '
        '${data.runtimeType}',
      );
      throw StateError('Unexpected response shape from farmers investments.');
    }
    return list
        .whereType<Map<String, dynamic>>()
        .map(_map)
        .toList(growable: false);
  }

  static FarmerInvestment _map(Map<String, dynamic> j) => FarmerInvestment(
    id: (j['id'] ?? '').toString(),
    commodity: (j['commodity'] ?? '').toString(),
    status: (j['status'] ?? '').toString(),
    numberOfInvestors: _int(j['number_of_investors']),
    endDate: DateTime.tryParse((j['end_date'] ?? '').toString()),
    targetAmount: Money(amount: _int(j['target_amount'])),
    collectedAmount: Money(amount: _int(j['collected_amount'])),
    roi: (j['roi'] as num?)?.toDouble() ?? 0,
    areaName: (j['area_name'] ?? '').toString(),
    images:
        (j['images'] as List?)
            ?.map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList(growable: false) ??
        const [],
  );

  static int _int(Object? v) {
    final n = (v as num?)?.toInt() ?? 0;
    return n < 0 ? 0 : n;
  }
}
