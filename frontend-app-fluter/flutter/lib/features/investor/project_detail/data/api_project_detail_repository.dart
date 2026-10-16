import 'package:flutter/foundation.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../domain/domain.dart';
import 'project_detail_repository.dart';

/// Loads a project/land for the invest flow from
/// `GET /investment/get-investment-details/{id}` (same shape used by the
/// investment detail page). Here `projectId` is the backend investment id.
class ApiProjectDetailRepository implements ProjectDetailRepository {
  const ApiProjectDetailRepository(this._api);

  final ApiClient _api;

  static const _ngrokHeaders = <String, String>{
    'ngrok-skip-browser-warning': 'true',
  };

  @override
  Future<AgricultureProject?> getProjectById(String projectId) async {
    try {
      final res = await _api.get(
        '/investment/get-investment-details/$projectId',
        authenticated: true,
        headers: _ngrokHeaders,
      );
      final json = res.data;
      if (json is! Map<String, dynamic>) {
        debugPrint(
          'ApiProjectDetailRepository: unexpected shape ${json.runtimeType}',
        );
        return null;
      }
      return _mapProject(projectId, json);
    } on ApiException catch (error) {
      if (error.type == ApiFailureType.notFound) return null;
      rethrow;
    }
  }

  AgricultureProject _mapProject(String id, Map<String, dynamic> json) {
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
    final images = _images(json['images']);

    return AgricultureProject(
      id: id,
      title: (areaName == null || areaName.isEmpty)
          ? ((commodityLabel == null || commodityLabel.isEmpty)
                ? 'Proyek'
                : 'Proyek $commodityLabel')
          : areaName,
      farmer: User(
        id: 'farmer-$id',
        name: (creatorName == null || creatorName.isEmpty)
            ? 'Petani'
            : creatorName,
        role: UserRole.farmer,
      ),
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
}
