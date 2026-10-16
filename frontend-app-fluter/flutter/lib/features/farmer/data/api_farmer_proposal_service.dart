import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../domain/domain.dart';
import '../common/farmer_design.dart';
import '../common/farmer_media_service.dart';
import 'farmer_repository.dart';

/// Result of the full proposal submission chain.
class FarmerProposalSubmission {
  const FarmerProposalSubmission({
    required this.landId,
    required this.investmentId,
    required this.fundTotal,
  });
  final String landId;
  final String investmentId;
  final int fundTotal;
}

/// Raised with a user-facing (Indonesian) message when a step fails.
class FarmerProposalException implements Exception {
  const FarmerProposalException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Creates a farmer proposal on the backend. The backend expects this exact
/// order, so each call waits for the previous one:
///
/// 1. `POST /area/create-land` (multipart) → land `id`
/// 2. `POST /area/upload-area-document/{area_id}` (multipart, PDF)
/// 3. `POST /investment/create-investment/{land_id}` → investment `id`
/// 4. `POST /investment/investment-fund-details/{investment_id}`
class ApiFarmerProposalService {
  const ApiFarmerProposalService(this._api);

  final ApiClient _api;

  /// Status sent with every new investment, per the backend contract.
  static const investmentStatus = 'Sedang Berjalan';

  static const _ngrokHeaders = <String, String>{
    'ngrok-skip-browser-warning': 'true',
  };

  Future<FarmerProposalSubmission> submit(FarmerProposalDetails d) async {
    // Check the required PDF before creating anything on the backend.
    _requirePdf(d);
    final landId = await createLand(d);
    await uploadLandDocument(landId, d);
    final investmentId = await createInvestment(landId, d);
    final total = await createFundDetails(investmentId, d);
    return FarmerProposalSubmission(
      landId: landId,
      investmentId: investmentId,
      fundTotal: total,
    );
  }

  /// Step 1: `POST /area/create-land` as multipart/form-data.
  Future<String> createLand(FarmerProposalDetails d) async {
    final photo = d.farmPhoto;
    if (photo == null || photo.isEmpty) {
      throw const FarmerProposalException('Unggah minimal satu foto lahan.');
    }
    final lat = d.location.latitude;
    final lng = d.location.longitude;
    if (lat == null || lng == null) {
      throw const FarmerProposalException(
        'Tentukan titik lokasi lahan di peta.',
      );
    }
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
      throw const FarmerProposalException(
        'Koordinat lokasi lahan tidak valid.',
      );
    }

    final data = await _run('membuat data lahan', () async {
      final res = await _api.postMultipart(
        '/area/create-land',
        headers: _ngrokHeaders,
        fields: {
          'name': d.landName.trim(),
          'description': d.landDescription.trim().isNotEmpty
              ? d.landDescription.trim()
              : 'Lahan seluas ${farmerNumber(d.area)} hektar di '
                    '${d.address.trim()}.',
          // Wizard collects hectares; the backend expects square meters.
          'width': _number(d.area * 10000),
          'address': d.address.trim(),
          'latitude': '$lat',
          'longitude': '$lng',
        },
        files: [
          ApiMultipartFile(
            field: 'images',
            bytes: photo,
            filename: _imageName(d.farmPhotoName),
          ),
        ],
      );
      return res.data;
    });
    return _id(data, 'lahan');
  }

  /// Step 2: `POST /area/upload-area-document/{area_id}` with the SPPT PDF in
  /// the `document` field. The backend keeps one document per land (upsert).
  /// Returns the stored `file_url`.
  Future<String> uploadLandDocument(
    String areaId,
    FarmerProposalDetails d,
  ) async {
    final pdf = _requirePdf(d);
    final data = await _run('mengunggah dokumen SPPT', () async {
      final res = await _api.postMultipart(
        '/area/upload-area-document/${Uri.encodeComponent(areaId)}',
        headers: _ngrokHeaders,
        files: [
          ApiMultipartFile(
            field: 'document',
            bytes: pdf,
            filename: _pdfName(d.spptName),
          ),
        ],
      );
      return res.data;
    });
    return (_map(data)?['file_url'] ?? '').toString();
  }

  static Uint8List _requirePdf(FarmerProposalDetails d) {
    final pdf = d.sppt;
    if (pdf == null || !FarmerMediaService.isPdf(pdf)) {
      throw const FarmerProposalException(
        'Unggah dokumen SPPT dalam format PDF.',
      );
    }
    return pdf;
  }

  static String _pdfName(String? name) {
    final n = name?.trim() ?? '';
    return n.toLowerCase().endsWith('.pdf') ? n : 'sppt.pdf';
  }

  /// Step 3: `POST /investment/create-investment/{land_id}`.
  Future<String> createInvestment(
    String landId,
    FarmerProposalDetails d,
  ) async {
    final data = await _run('membuat proposal investasi', () async {
      final res = await _api.post(
        '/investment/create-investment/${Uri.encodeComponent(landId)}',
        headers: _ngrokHeaders,
        body: {
          'description': d.description.trim().isNotEmpty
              ? d.description.trim()
              : 'Budidaya ${farmerCommodity(d.commodity!)} di '
                    '${d.address.trim()}. '
                    'Risiko: ${d.risks.join(', ')}.',
          'commodity': backendCommodity(d.commodity!),
          'plant_start': _date(d.plantingMonth),
          'plant_end': _date(d.harvestMonth),
          'harvest_estimation': _json(d.harvestTons),
          'estimated_selling_price': d.salePrice,
          'target_amount': d.total,
          'status': investmentStatus,
        },
      );
      return res.data;
    });
    return _id(data, 'investasi');
  }

  /// Step 4: `POST /investment/investment-fund-details/{investment_id}`.
  /// Returns the backend-computed `total`.
  Future<int> createFundDetails(
    String investmentId,
    FarmerProposalDetails d,
  ) async {
    final b = d.budget;
    final data = await _run('menyimpan rincian dana', () async {
      final res = await _api.post(
        '/investment/investment-fund-details/'
        '${Uri.encodeComponent(investmentId)}',
        headers: _ngrokHeaders,
        body: {
          'seedling': b['Bibit'] ?? 0,
          'fertilizer': b['Pupuk'] ?? 0,
          'labour': b['Tenaga Kerja'] ?? 0,
          'others': d.otherCostAmount,
          // Backend FundDetailsReq: description is required when others > 0
          // and must be absent (null) otherwise.
          'description': d.otherCostAmount > 0
              ? d.otherCostDescription.trim()
              : null,
        },
      );
      return res.data;
    });
    final map = _map(data);
    return (map?['total'] as num?)?.toInt() ?? d.total;
  }

  Future<Object?> _run(String step, Future<Object?> Function() call) async {
    try {
      return await call();
    } on ApiException catch (e) {
      debugPrint('ApiFarmerProposalService: gagal $step: $e');
      throw FarmerProposalException('Gagal $step: ${e.message}');
    }
  }

  static Map<String, dynamic>? _map(Object? data) {
    if (data is! Map<String, dynamic>) return null;
    // Accept both a bare object and a `{"data": {...}}` envelope.
    final inner = data['data'];
    return inner is Map<String, dynamic> ? inner : data;
  }

  static String _id(Object? data, String what) {
    final map = _map(data);
    final id = (map?['id'] ?? map?['land_id'] ?? map?['investment_id'] ?? '')
        .toString();
    if (id.isEmpty) {
      throw FarmerProposalException('Respons $what tidak berisi id.');
    }
    return id;
  }

  /// Values of the backend `Comodity` enum.
  static String backendCommodity(Commodity c) => switch (c) {
    Commodity.rice => 'Padi',
    Commodity.vegetables => 'Sayuran',
    Commodity.spices => 'Rempah',
    Commodity.fruits => 'Buah',
    Commodity.secondaryCrops => 'Palawija',
    Commodity.plantation => 'Perkebunan',
    Commodity.other => throw const FarmerProposalException(
      'Komoditas tidak didukung. Pilih komoditas lain.',
    ),
  };

  static String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  /// Sends whole numbers as ints so `7` is not encoded as `7.0`.
  static num _json(double v) => v == v.roundToDouble() ? v.toInt() : v;

  static String _number(double v) => '${_json(v)}';

  static String _imageName(String? name) {
    final n = name?.trim() ?? '';
    final ext = n.contains('.') ? n.split('.').last.toLowerCase() : '';
    return const {'jpg', 'jpeg', 'png', 'webp'}.contains(ext) ? n : 'lahan.jpg';
  }
}
