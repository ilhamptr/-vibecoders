import '../money/money.dart';
import '../project/commodity.dart';
import '../project/project_location.dart';
import '../user/user.dart';
import 'proposal_status.dart';

class Proposal {
  const Proposal({
    required this.id,
    required this.farmer,
    required this.projectName,
    required this.commodity,
    required this.location,
    required this.landAreaHectares,
    required this.status,
    this.submittedAt,
    this.estimatedHarvestKg,
    this.fundingTarget,
    this.estimatedApprovalAt,
  }) : assert(landAreaHectares > 0),
       assert(estimatedHarvestKg == null || estimatedHarvestKg >= 0);

  final String id;
  final User farmer;
  final String projectName;
  final Commodity commodity;
  final ProjectLocation location;

  final double landAreaHectares;
  final double? estimatedHarvestKg;
  final Money? fundingTarget;

  final ProposalStatus status;
  final DateTime? submittedAt;
  final DateTime? estimatedApprovalAt;

  bool get isEditable => status == ProposalStatus.draft;

  Proposal copyWith({
    String? id,
    User? farmer,
    String? projectName,
    Commodity? commodity,
    ProjectLocation? location,
    double? landAreaHectares,
    double? estimatedHarvestKg,
    Money? fundingTarget,
    ProposalStatus? status,
    DateTime? submittedAt,
    DateTime? estimatedApprovalAt,
  }) {
    return Proposal(
      id: id ?? this.id,
      farmer: farmer ?? this.farmer,
      projectName: projectName ?? this.projectName,
      commodity: commodity ?? this.commodity,
      location: location ?? this.location,
      landAreaHectares: landAreaHectares ?? this.landAreaHectares,
      estimatedHarvestKg: estimatedHarvestKg ?? this.estimatedHarvestKg,
      fundingTarget: fundingTarget ?? this.fundingTarget,
      status: status ?? this.status,
      submittedAt: submittedAt ?? this.submittedAt,
      estimatedApprovalAt: estimatedApprovalAt ?? this.estimatedApprovalAt,
    );
  }
}
