import 'package:flutter/foundation.dart';

import '../../../../core/network/api_client.dart';
import '../../../../domain/domain.dart';
import 'portfolio_repository.dart';

/// [PortfolioRepository] for the Portfolio tab, backed by
/// `GET /investment/get-user-investments?investment_status=<status>`.
///
/// The `investment_status` query parameter is required and uses the backend's
/// capitalized Indonesian values exactly: "Sedang Berjalan" or "Selesai". A
/// null/unsupported filter defaults to "Sedang Berjalan".
///
/// (The investor Home tab keeps using `ApiPortfolioRepository`, which reads
/// `/investment/get-active-investment`.)
class ApiUserInvestmentsRepository implements PortfolioRepository {
  ApiUserInvestmentsRepository(this._api, {required this.investor});

  final ApiClient _api;
  final User investor;

  static const _activeParam = 'Sedang Berjalan';
  static const _completedParam = 'Selesai';

  static const _unknownFarmer = User(
    id: 'farmer-unknown',
    name: 'Petani',
    role: UserRole.farmer,
  );

  static const _ngrokHeaders = <String, String>{
    'ngrok-skip-browser-warning': 'true',
  };

  static String _statusParam(InvestmentStatus? status) {
    switch (status) {
      case InvestmentStatus.completed:
        return _completedParam;
      case InvestmentStatus.active:
      default:
        return _activeParam;
    }
  }

  @override
  Future<List<Investment>> getInvestments({InvestmentStatus? status}) async {
    final res = await _api.get(
      '/investment/get-user-investments',
      authenticated: true,
      queryParameters: {'investment_status': _statusParam(status)},
      headers: _ngrokHeaders,
    );
    final list = _investmentList(res.data);
    if (list == null) {
      debugPrint(
        'ApiUserInvestmentsRepository: unexpected response shape '
        '${res.data.runtimeType} from user investments.',
      );
      throw StateError('Unexpected response shape from user investments.');
    }

    return list
        .whereType<Map<String, dynamic>>()
        .map(_mapInvestment)
        .toList(growable: false);
  }

  @override
  Future<Investment?> getInvestmentById(String investmentId) async {
    // The endpoint always needs a status; search both.
    for (final status in const [
      InvestmentStatus.active,
      InvestmentStatus.completed,
    ]) {
      final list = await getInvestments(status: status);
      for (final investment in list) {
        if (investment.id == investmentId) return investment;
      }
    }
    return null;
  }

  Investment _mapInvestment(Map<String, dynamic> json) {
    final id = '${json['id']}';
    final target = _nonNegativeInt(json['target_amount']);
    final collected = _nonNegativeInt(json['collected_amount']);
    final investors = _nonNegativeInt(json['number_of_investors']);
    final roi = (json['roi'] as num?)?.toDouble() ?? 0;
    final safeRoi = roi < 0 ? 0.0 : roi;
    final endDate = json['end_date'] is String
        ? DateTime.tryParse(json['end_date'] as String)
        : null;
    final commodityLabel = (json['commodity'] as String?)?.trim();
    final areaName = (json['area_name'] as String?)?.trim();
    final imageUrl = _firstImage(json['images']);

    final title = (areaName != null && areaName.isNotEmpty)
        ? areaName
        : (commodityLabel == null || commodityLabel.isEmpty)
        ? 'Proyek'
        : 'Proyek $commodityLabel';

    final project = AgricultureProject(
      id: id,
      title: title,
      farmer: _unknownFarmer,
      commodity: _commodity(commodityLabel),
      location: const ProjectLocation(province: '', city: ''),
      status: _projectStatus(json['status'] as String?),
      funding: Funding(
        target: Money(amount: target),
        collected: Money(amount: collected),
        investorCount: investors,
        deadline: endDate,
      ),
      roiMinPercent: safeRoi,
      roiMaxPercent: safeRoi,
      harvestCycleMonths: 4,
      imageUrl: imageUrl,
    );

    return Investment(
      id: id,
      investor: investor,
      project: project,
      principal: Money(amount: collected),
      status: _investmentStatus(json['status'] as String?),
      investedAt: DateTime.now(),
      estimatedReturn: Money(amount: (collected * safeRoi / 100).round()),
    );
  }

  static List<dynamic>? _investmentList(Object? data) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      final nested = data['investments'];
      if (nested is List) return nested;
    }
    return null;
  }

  static String? _firstImage(Object? value) {
    if (value is! List) return null;
    for (final item in value) {
      if (item is String && item.trim().isNotEmpty) return item.trim();
    }
    return null;
  }

  static int _nonNegativeInt(Object? value) {
    final parsed = (value as num?)?.toInt() ?? 0;
    return parsed < 0 ? 0 : parsed;
  }

  static Commodity _commodity(String? value) {
    switch (value?.toLowerCase()) {
      case 'padi':
        return Commodity.rice;
      case 'sayur':
      case 'sayuran':
        return Commodity.vegetables;
      case 'rempah':
      case 'rempah-rempah':
        return Commodity.spices;
      case 'buah':
      case 'buah-buahan':
        return Commodity.fruits;
      case 'palawija':
        return Commodity.secondaryCrops;
      case 'perkebunan':
        return Commodity.plantation;
      default:
        return Commodity.other;
    }
  }

  static ProjectStatus _projectStatus(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'terbuka':
      case 'pendanaan':
        return ProjectStatus.openForFunding;
      case 'terdanai':
        return ProjectStatus.fullyFunded;
      case 'selesai':
        return ProjectStatus.completed;
      case 'dibatalkan':
        return ProjectStatus.cancelled;
      case 'sedang berjalan':
      case 'berjalan':
      default:
        return ProjectStatus.growing;
    }
  }

  static InvestmentStatus _investmentStatus(String? value) {
    switch (value?.trim().toLowerCase()) {
      case 'selesai':
        return InvestmentStatus.completed;
      case 'dibatalkan':
        return InvestmentStatus.cancelled;
      default:
        return InvestmentStatus.active;
    }
  }
}
