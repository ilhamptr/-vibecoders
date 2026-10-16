import 'package:flutter/foundation.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../domain/domain.dart';
import 'fund_breakdown.dart';
import 'investor_monitoring_repository.dart';

/// Builds the investment detail from the real backend:
/// - `GET  /investment/get-investment-details/{id}`   -> project + creator + location
/// - `GET  /investment/investment-fund-details/{id}`  -> cost breakdown
///
/// Both requests are authenticated, so a valid Bearer token must be present in
/// token storage (see `main.dart`). The timeline is intentionally empty; the
/// detail page no longer renders it.
class ApiInvestorMonitoringRepository implements InvestorMonitoringRepository {
  ApiInvestorMonitoringRepository(this._api, {required this.investor});

  final ApiClient _api;
  final User investor;

  static const _ngrokHeaders = <String, String>{
    'ngrok-skip-browser-warning': 'true',
  };

  @override
  Future<InvestorMonitoring?> getMonitoring(String investmentId) async {
    final detail = await _fetchDetail(investmentId);
    if (detail == null) return null;

    final fund = await _fetchFund(investmentId);

    final images = _images(detail['images']);
    final investment = _mapInvestment(investmentId, detail, images);

    return InvestorMonitoring(
      investment: investment,
      timeline: const [],
      fundBreakdown: fund,
      images: images,
    );
  }

  Future<Map<String, dynamic>?> _fetchDetail(String id) async {
    try {
      final res = await _api.get(
        '/investment/get-investment-details/$id',
        authenticated: true,
        headers: _ngrokHeaders,
      );
      final data = res.data;
      if (data is Map<String, dynamic>) return data;
      debugPrint(
        'ApiInvestorMonitoringRepository: unexpected detail shape '
        '${data.runtimeType}',
      );
      return null;
    } on ApiException catch (error) {
      if (error.type == ApiFailureType.notFound) return null;
      rethrow;
    }
  }

  /// The fund breakdown is optional; a missing/404 response just hides the
  /// section rather than failing the whole page.
  Future<FundBreakdown?> _fetchFund(String id) async {
    try {
      final res = await _api.get(
        '/investment/investment-fund-details/$id',
        authenticated: true,
        headers: _ngrokHeaders,
      );
      final data = res.data;
      if (data is! Map<String, dynamic>) return null;
      return FundBreakdown(
        seedling: Money(amount: _nonNegativeInt(data['seedling'])),
        fertilizer: Money(amount: _nonNegativeInt(data['fertilizer'])),
        labour: Money(amount: _nonNegativeInt(data['labour'])),
        others: Money(amount: _nonNegativeInt(data['others'])),
        total: Money(amount: _nonNegativeInt(data['total'])),
        description: (data['description'] as String?)?.trim().isNotEmpty == true
            ? (data['description'] as String).trim()
            : null,
      );
    } on ApiException catch (error) {
      debugPrint(
        'ApiInvestorMonitoringRepository: fund-details unavailable '
        '(${error.type}); hiding the breakdown.',
      );
      return null;
    }
  }

  Investment _mapInvestment(
    String id,
    Map<String, dynamic> json,
    List<String> images,
  ) {
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
    final description = (json['description'] as String?)?.trim();
    final creatorName = (json['creator_name'] as String?)?.trim();
    final latitude = (json['latitude'] as num?)?.toDouble();
    final longitude = (json['longitude'] as num?)?.toDouble();

    final farmer = User(
      id: 'farmer-$id',
      name: (creatorName == null || creatorName.isEmpty) ? 'Petani' : creatorName,
      role: UserRole.farmer,
    );

    final project = AgricultureProject(
      id: id,
      title: (areaName == null || areaName.isEmpty)
          ? ((commodityLabel == null || commodityLabel.isEmpty)
                ? 'Proyek'
                : 'Proyek $commodityLabel')
          : areaName,
      farmer: farmer,
      commodity: _commodity(commodityLabel),
      location: ProjectLocation(
        province: '',
        city: '',
        latitude: latitude,
        longitude: longitude,
      ),
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
      description: (description == null || description.isEmpty)
          ? null
          : description,
      imageUrl: images.isEmpty ? null : images.first,
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

  static List<String> _images(Object? value) {
    if (value is! List) return const [];
    return value
        .whereType<String>()
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList(growable: false);
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
