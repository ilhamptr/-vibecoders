import 'package:flutter/foundation.dart';

import '../../../../core/network/api_client.dart';
import '../../../../domain/domain.dart';
import 'portfolio_repository.dart';

/// [PortfolioRepository] backed by the real backend.
///
/// Wired to `GET /investment/get-active-investment`, which returns the
/// investor's active investments. The request is authenticated, so a valid
/// Bearer token must be present in token storage (see `main.dart`).
class ApiPortfolioRepository implements PortfolioRepository {
  ApiPortfolioRepository(this._api, {required this.investor});

  final ApiClient _api;
  final User investor;

  /// The endpoint does not return farmer details yet.
  static const _unknownFarmer = User(
    id: 'farmer-unknown',
    name: 'Petani',
    role: UserRole.farmer,
  );

  @override
  Future<List<Investment>> getInvestments({InvestmentStatus? status}) async {
    final res = await _api.get(
      '/investment/get-active-investment',
      authenticated: true,
      // Free-tier ngrok otherwise returns its browser-warning HTML page.
      headers: const {'ngrok-skip-browser-warning': 'true'},
    );
    final list = _investmentList(res.data);
    if (list == null) {
      debugPrint(
        'ApiPortfolioRepository: unexpected response shape '
        '${res.data.runtimeType} from active investments.',
      );
      throw StateError('Unexpected response shape from active investments.');
    }

    final investments = list
        .whereType<Map<String, dynamic>>()
        .map(_mapInvestment)
        .toList(growable: false);

    if (status == null) return investments;
    return investments.where((i) => i.status == status).toList();
  }

  @override
  Future<Investment?> getInvestmentById(String investmentId) async {
    final all = await getInvestments();
    for (final investment in all) {
      if (investment.id == investmentId) return investment;
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

    // Prefer the real area name; fall back to a commodity label, then a
    // generic word so the card always has a title.
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
      // TODO: the endpoint does not return the investor's own principal or
      // invested-at date yet. collected_amount is a temporary stand-in.
      principal: Money(amount: collected),
      status: _investmentStatus(json['status'] as String?),
      investedAt: DateTime.now(),
      estimatedReturn: Money(amount: (collected * safeRoi / 100).round()),
    );
  }

  static int _nonNegativeInt(Object? value) {
    final parsed = (value as num?)?.toInt() ?? 0;
    return parsed < 0 ? 0 : parsed;
  }

  /// Extracts the investments array from the response, tolerating both the
  /// current `{"investments": [...]}` envelope and a bare `[...]` list.
  static List<dynamic>? _investmentList(Object? data) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      final nested = data['investments'];
      if (nested is List) return nested;
    }
    return null;
  }

  /// First non-empty URL from the `images` list, or null when absent.
  static String? _firstImage(Object? value) {
    if (value is! List) return null;
    for (final item in value) {
      if (item is String && item.trim().isNotEmpty) return item.trim();
    }
    return null;
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
      case 'persiapan lahan':
        return ProjectStatus.landPreparation;
      case 'penanaman':
        return ProjectStatus.planting;
      case 'panen':
        return ProjectStatus.harvesting;
      case 'distribusi':
        return ProjectStatus.distribution;
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
