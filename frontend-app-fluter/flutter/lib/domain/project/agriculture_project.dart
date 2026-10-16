import '../funding/funding.dart';
import '../user/user.dart';
import 'commodity.dart';
import 'project_location.dart';
import 'project_status.dart';

enum ProjectRiskLevel { low, medium, high }

class AgricultureProject {
  const AgricultureProject({
    required this.id,
    required this.title,
    required this.farmer,
    required this.commodity,
    required this.location,
    required this.status,
    required this.funding,
    required this.roiMinPercent,
    required this.roiMaxPercent,
    required this.harvestCycleMonths,
    this.description,
    this.imageUrl,
    this.riskLevel,
    this.createdAt,
  }) : assert(roiMinPercent >= 0),
       assert(roiMaxPercent >= roiMinPercent),
       assert(harvestCycleMonths > 0);

  final String id;
  final String title;
  final User farmer;
  final Commodity commodity;
  final ProjectLocation location;
  final ProjectStatus status;
  final Funding funding;

  final double roiMinPercent;
  final double roiMaxPercent;
  final int harvestCycleMonths;

  final String? description;
  final String? imageUrl;
  final ProjectRiskLevel? riskLevel;
  final DateTime? createdAt;

  bool get isOpenForInvestment => status == ProjectStatus.openForFunding;

  AgricultureProject copyWith({
    String? id,
    String? title,
    User? farmer,
    Commodity? commodity,
    ProjectLocation? location,
    ProjectStatus? status,
    Funding? funding,
    double? roiMinPercent,
    double? roiMaxPercent,
    int? harvestCycleMonths,
    String? description,
    String? imageUrl,
    ProjectRiskLevel? riskLevel,
    DateTime? createdAt,
  }) {
    return AgricultureProject(
      id: id ?? this.id,
      title: title ?? this.title,
      farmer: farmer ?? this.farmer,
      commodity: commodity ?? this.commodity,
      location: location ?? this.location,
      status: status ?? this.status,
      funding: funding ?? this.funding,
      roiMinPercent: roiMinPercent ?? this.roiMinPercent,
      roiMaxPercent: roiMaxPercent ?? this.roiMaxPercent,
      harvestCycleMonths: harvestCycleMonths ?? this.harvestCycleMonths,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      riskLevel: riskLevel ?? this.riskLevel,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
