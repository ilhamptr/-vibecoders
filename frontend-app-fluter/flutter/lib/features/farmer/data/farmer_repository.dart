import 'package:flutter/foundation.dart';

import '../../../domain/domain.dart';

/// Wizard inputs and attachments supplement the shared Proposal domain model.
class FarmerProposalDetails {
  FarmerProposalDetails({
    this.landName = '',
    this.landDescription = '',
    this.description = '',
    this.otherCostDescription = '',
    this.address = '',
    this.location = const ProjectLocation(province: '', city: ''),
    this.area = 0,
    this.commodity,
    this.harvestTons = 0,
    this.salePrice = 0,
    DateTime? plantingMonth,
    Map<String, int>? budget,
    Set<String>? risks,
    this.farmPhoto,
    this.farmPhotoName,
    this.farmPhotoAsset,
    this.sppt,
    this.spptName,
  }) : plantingMonth = plantingMonth ?? DateTime(2026, 4),
       budget = budget ?? {for (final c in budgetCategories) c: 0},
       risks = risks ?? {};
  static const otherCost = 'Biaya Lainnya';
  static const budgetCategories = ['Bibit', 'Pupuk', 'Tenaga Kerja', otherCost];

  /// Purpose of [otherCost]. Required when that cost is > 0, and must be
  /// empty when it is 0.
  String otherCostDescription;

  int get otherCostAmount => budget[otherCost] ?? 0;

  /// Null when valid, otherwise a user-facing error.
  String? get otherCostError {
    final hasNote = otherCostDescription.trim().isNotEmpty;
    if (otherCostAmount > 0 && !hasNote) {
      return 'Jelaskan peruntukan biaya lainnya.';
    }
    if (otherCostAmount <= 0 && hasNote) {
      return 'Deskripsi hanya diisi jika ada biaya lainnya.';
    }
    return null;
  }

  /// Land name sent to `/area/create-land` (e.g. "Sawah Pak Budi").
  String landName;

  /// Land condition / soil type, sent to `/area/create-land`.
  String landDescription;

  /// Proposal description, sent to `/investment/create-investment`.
  String description;

  /// Full land address ("Alamat Lengkap"), sent as `address` to
  /// `/area/create-land`.
  String address;

  /// Map pin. Only [ProjectLocation.latitude]/[ProjectLocation.longitude]
  /// are collected by the wizard; the address lives in [address].
  ProjectLocation location;
  double area;
  Commodity? commodity;
  double harvestTons;
  int salePrice;
  DateTime plantingMonth;
  Map<String, int> budget;
  Set<String> risks;
  Uint8List? farmPhoto;
  String? farmPhotoName;
  String? farmPhotoAsset;
  Uint8List? sppt;
  String? spptName;
  int get total => budget.values.fold(0, (a, b) => a + b);
  DateTime get harvestMonth =>
      DateTime(plantingMonth.year, plantingMonth.month + 4);
  FarmerProposalDetails copy() => FarmerProposalDetails(
    landName: landName,
    landDescription: landDescription,
    description: description,
    otherCostDescription: otherCostDescription,
    address: address,
    location: location,
    area: area,
    commodity: commodity,
    harvestTons: harvestTons,
    salePrice: salePrice,
    plantingMonth: plantingMonth,
    budget: Map.of(budget),
    risks: Set.of(risks),
    farmPhoto: farmPhoto,
    farmPhotoName: farmPhotoName,
    farmPhotoAsset: farmPhotoAsset,
    sppt: sppt,
    spptName: spptName,
  );
}

class FarmerActivity {
  const FarmerActivity({
    required this.projectId,
    required this.report,
    required this.text,
    required this.stage,
    required this.attachment,
    required this.attachmentName,
    required this.createdAt,
  });
  final String projectId;
  final bool report;
  final String text;
  final String stage;
  final Uint8List attachment;
  final String attachmentName;
  final DateTime createdAt;
}

class FarmerTransaction {
  const FarmerTransaction({
    required this.deposit,
    required this.amount,
    required this.createdAt,
  });
  final bool deposit;
  final Money amount;
  final DateTime createdAt;
}

abstract class FarmerRepository implements Listenable {
  User get farmer;
  List<Proposal> get proposals;
  List<AgricultureProject> get projects;
  FarmerProjectProgress progress(String projectId);
  List<FarmerActivity> get activities;
  List<FarmerTransaction> get transactions;
  Money get balance;
  Money get pendingBalance;
  FarmerProposalDetails details(String id);
  bool needsCorrection(String id);
  Future<Proposal> submit(FarmerProposalDetails details);
  Future<void> update(String id, FarmerProposalDetails details);
  Future<void> sendActivity(FarmerActivity activity);
  Future<void> transact({required bool deposit, required Money amount});
}

abstract final class FarmerStates {
  static const review = {
    ProposalStatus.draft,
    ProposalStatus.submitted,
    ProposalStatus.documentReview,
    ProposalStatus.fieldVisit,
    ProposalStatus.rejected,
  };
  static const running = {
    ProjectStatus.landPreparation,
    ProjectStatus.planting,
    ProjectStatus.growing,
    ProjectStatus.harvesting,
    ProjectStatus.distribution,
  };
}

class FarmerProjectProgress {
  const FarmerProjectProgress({
    required this.stage,
    required this.week,
    required this.currentMonth,
    required this.harvestMonth,
  });
  final String stage;
  final int week;
  final DateTime currentMonth;
  final DateTime harvestMonth;
}
