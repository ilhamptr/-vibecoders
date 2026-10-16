import '../../../domain/domain.dart';

/// `investment_status` values accepted by `/investment/get-farmers-investments`.
enum FarmerInvestmentStatus {
  running('Sedang Berjalan'),
  completed('Selesai');

  const FarmerInvestmentStatus(this.apiValue);
  final String apiValue;
}

/// One item of `/investment/get-farmers-investments` → `investments[]`.
class FarmerInvestment {
  const FarmerInvestment({
    required this.id,
    required this.commodity,
    required this.status,
    required this.numberOfInvestors,
    required this.targetAmount,
    required this.collectedAmount,
    required this.roi,
    required this.areaName,
    this.endDate,
    this.images = const [],
  });

  final String id;

  /// Backend commodity label (Padi, Sayuran, Rempah, Buah, Palawija,
  /// Perkebunan), shown as-is.
  final String commodity;
  final String status;
  final int numberOfInvestors;
  final DateTime? endDate;
  final Money targetAmount;
  final Money collectedAmount;

  /// Percentage, may be negative (e.g. -90).
  final double roi;
  final String areaName;
  final List<String> images;

  double get progress {
    if (targetAmount.amount <= 0) return 0;
    return (collectedAmount.amount / targetAmount.amount).clamp(0.0, 1.0);
  }

  /// Days until [endDate]; 0 once passed, null when unknown.
  int? get daysRemaining {
    final end = endDate;
    if (end == null) return null;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = end.difference(today).inDays;
    return days < 0 ? 0 : days;
  }

  /// Minimal domain project so the existing update/report page can be reused.
  AgricultureProject toProject(User farmer) => AgricultureProject(
    id: id,
    title: areaName,
    farmer: farmer,
    commodity: _commodity(commodity),
    location: const ProjectLocation(province: '', city: ''),
    status: ProjectStatus.growing,
    funding: Funding(
      target: targetAmount,
      collected: collectedAmount,
      investorCount: numberOfInvestors,
      deadline: endDate,
    ),
    // Domain asserts non-negative ROI; the activity page does not show it.
    roiMinPercent: 0,
    roiMaxPercent: 0,
    harvestCycleMonths: 4,
    imageUrl: images.isEmpty ? null : images.first,
  );

  static Commodity _commodity(String label) => switch (label) {
    'Padi' => Commodity.rice,
    'Sayuran' => Commodity.vegetables,
    'Rempah' => Commodity.spices,
    'Buah' => Commodity.fruits,
    'Palawija' => Commodity.secondaryCrops,
    'Perkebunan' => Commodity.plantation,
    _ => Commodity.other,
  };
}

abstract interface class FarmerInvestmentRepository {
  Future<List<FarmerInvestment>> getInvestments(FarmerInvestmentStatus status);
}
