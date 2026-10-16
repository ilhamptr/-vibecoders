import 'package:flutter/foundation.dart';

import '../../../domain/domain.dart';
import '../common/farmer_media_service.dart';
import 'farmer_repository.dart';

class MockFarmerStore extends ChangeNotifier implements FarmerRepository {
  MockFarmerStore() {
    for (var i = 0; i < 3; i++) {
      final id = 'proposal-$i';
      final d = FarmerProposalDetails(
        landName: 'Kebun Cabai Pak Wowok',
        address: location.displayName,
        location: location,
        area: 1.5,
        commodity: Commodity.vegetables,
        harvestTons: 7,
        salePrice: 2500000,
        budget: {
          'Bibit': 45000000,
          'Pupuk': 37500000,
          'Tenaga Kerja': 37500000,
          FarmerProposalDetails.otherCost: 30000000,
        },
        otherCostDescription: 'Sewa pompa dan perbaikan saluran irigasi',
        sppt: _samplePdf,
        spptName: 'sppt-lahan.pdf',
        farmPhotoAsset: 'chili.png',
        risks: {'Risiko Cuaca'},
      );
      _details[id] = d;
      _proposals.add(
        _proposal(
          id,
          d,
          i == 0 ? ProposalStatus.draft : ProposalStatus.documentReview,
        ),
      );
    }
    _corrections.add('proposal-0');
    for (final running in [false, true]) {
      _projects.add(
        AgricultureProject(
          id: running ? 'project-running' : 'project-funding',
          title: 'Perkebunan Cabai Alam Sutera',
          farmer: farmer,
          commodity: Commodity.vegetables,
          location: location,
          status: running
              ? ProjectStatus.growing
              : ProjectStatus.openForFunding,
          funding: Funding(
            target: const Money(amount: 150000000),
            collected: Money(amount: running ? 150000000 : 111000000),
            investorCount: 53,
            deadline: DateTime.now().add(const Duration(days: 13)),
          ),
          roiMinPercent: 15,
          roiMaxPercent: 20,
          harvestCycleMonths: 4,
          riskLevel: ProjectRiskLevel.medium,
          createdAt: DateTime(2025, 12, 1),
        ),
      );
    }
  }

  /// Minimal `%PDF-1.4 … %%EOF` bytes for seeded proposals.
  static final _samplePdf = Uint8List.fromList('%PDF-1.4\n%%EOF\n'.codeUnits);
  static const location = ProjectLocation(
    province: 'Jawa Tengah',
    city: 'Klaten',
    village: 'Desa Sukamaju',
    latitude: -7.705,
    longitude: 110.601,
  );
  @override
  final farmer = const User(
    id: 'farmer-wowok',
    name: 'Wowok Sutoyok',
    role: UserRole.farmer,
    isVerified: true,
  );
  final _proposals = <Proposal>[];
  final _projects = <AgricultureProject>[];
  final _details = <String, FarmerProposalDetails>{};
  final _corrections = <String>{};
  final _activities = <FarmerActivity>[];
  final _transactions = <FarmerTransaction>[];
  Money _balance = const Money(amount: 150000000);
  int _sequence = 3;
  @override
  List<Proposal> get proposals => List.unmodifiable(_proposals);
  @override
  List<AgricultureProject> get projects => List.unmodifiable(_projects);
  @override
  FarmerProjectProgress progress(String projectId) {
    if (projectId == 'project-running') {
      return FarmerProjectProgress(
        stage: 'Pemupukan & Perawatan',
        week: 7,
        currentMonth: DateTime(2025, 12),
        harvestMonth: DateTime(2026, 2),
      );
    }
    final d = _details[projectId];
    return FarmerProjectProgress(
      stage: 'Persiapan Lahan',
      week: 1,
      currentMonth: d?.plantingMonth ?? DateTime.now(),
      harvestMonth: d?.harvestMonth ?? DateTime.now(),
    );
  }

  @override
  List<FarmerActivity> get activities => List.unmodifiable(_activities);
  @override
  List<FarmerTransaction> get transactions => List.unmodifiable(_transactions);
  @override
  Money get balance => _balance;
  @override
  Money get pendingBalance => const Money(amount: 20000000);
  @override
  FarmerProposalDetails details(String id) => _details[id]!.copy();
  @override
  bool needsCorrection(String id) => _corrections.contains(id);
  Proposal _proposal(
    String id,
    FarmerProposalDetails d,
    ProposalStatus status,
  ) => Proposal(
    id: id,
    farmer: farmer,
    projectName:
        id.startsWith('proposal-') &&
            int.tryParse(id.substring(9)) != null &&
            int.parse(id.substring(9)) < 3
        ? 'Perkebunan Cabai Alam Sutera'
        : d.landName.trim().isNotEmpty
        ? d.landName.trim()
        : 'Budidaya ${d.commodity == Commodity.rice
              ? 'Padi'
              : d.commodity == Commodity.vegetables
              ? 'Sayuran'
              : 'Komoditas'}',
    commodity: d.commodity!,
    location: _addressLocation(d),
    landAreaHectares: d.area,
    status: status,
    estimatedHarvestKg: d.harvestTons * 1000,
    fundingTarget: Money(amount: d.total),
    submittedAt: DateTime(2026, 10, 1),
    estimatedApprovalAt: DateTime(2026, 10, 7),
  );

  /// Shared domain [ProjectLocation] for local lists: the single free-text
  /// address is shown as-is, coordinates come from the map pin.
  static ProjectLocation _addressLocation(FarmerProposalDetails d) =>
      ProjectLocation(
        province: '',
        city: d.address.trim(),
        latitude: d.location.latitude,
        longitude: d.location.longitude,
      );

  /// Local validation shared with API-backed subclasses before any request.
  @protected
  void validateDetails(FarmerProposalDetails d) {
    if (d.landName.trim().isEmpty ||
        d.sppt == null ||
        !FarmerMediaService.isPdf(d.sppt!) ||
        d.address.trim().isEmpty ||
        d.area <= 0 ||
        !d.area.isFinite ||
        d.commodity == null ||
        d.harvestTons <= 0 ||
        !d.harvestTons.isFinite ||
        d.salePrice <= 0 ||
        d.total <= 0 ||
        d.budget.values.any((v) => v < 0) ||
        d.otherCostError != null ||
        d.risks.isEmpty) {
      throw ArgumentError('Lengkapi semua detail proposal.');
    }
  }

  @override
  Future<Proposal> submit(FarmerProposalDetails details) async {
    validateDetails(details);
    final id = 'proposal-${_sequence++}';
    final p = _proposal(id, details, ProposalStatus.submitted).copyWith(
      submittedAt: DateTime.now(),
      estimatedApprovalAt: DateTime.now().add(const Duration(days: 6)),
    );
    _details[id] = details.copy();
    _proposals.insert(0, p);
    notifyListeners();
    return p;
  }

  @override
  Future<void> update(String id, FarmerProposalDetails details) async {
    validateDetails(details);
    final index = _proposals.indexWhere((p) => p.id == id);
    if (index < 0) throw StateError('Proposal tidak ditemukan.');
    final old = _proposals[index];
    if (!FarmerStates.review.contains(old.status)) {
      throw StateError('Proposal tidak lagi dalam peninjauan.');
    }
    _details[id] = details.copy();
    _proposals[index] = old.copyWith(
      location: _addressLocation(details),
      landAreaHectares: details.area,
      commodity: details.commodity,
      estimatedHarvestKg: details.harvestTons * 1000,
    );
    notifyListeners();
  }

  @override
  Future<void> sendActivity(FarmerActivity activity) async {
    // Dashboard projects now come from the backend, so ids may be unknown
    // locally. Only reject projects known here that are not running.
    final local = _projects.where((p) => p.id == activity.projectId);
    if (local.isNotEmpty &&
        !FarmerStates.running.contains(local.first.status)) {
      throw StateError('Proyek tidak sedang berjalan.');
    }
    if (activity.text.trim().isEmpty || activity.attachment.isEmpty) {
      throw ArgumentError('Lengkapi isi dan lampiran.');
    }
    _activities.insert(0, activity);
    notifyListeners();
  }

  @override
  Future<void> transact({required bool deposit, required Money amount}) async {
    if (amount.amount <= 0) {
      throw ArgumentError('Nominal harus lebih dari nol.');
    }
    if (!deposit && amount.amount > _balance.amount - pendingBalance.amount) {
      throw StateError('Saldo tersedia tidak mencukupi.');
    }
    _balance = deposit ? _balance + amount : _balance - amount;
    _transactions.insert(
      0,
      FarmerTransaction(
        deposit: deposit,
        amount: amount,
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
  }

  /// Simulates a backend review decision for local lifecycle verification.
  void transitionProposal(String id, ProposalStatus status) {
    final index = _proposals.indexWhere((p) => p.id == id);
    if (index < 0) throw StateError('Proposal tidak ditemukan.');
    final p = _proposals[index].copyWith(status: status);
    _proposals[index] = p;
    if ({
      ProposalStatus.approved,
      ProposalStatus.funding,
      ProposalStatus.active,
    }.contains(status)) {
      final projectIndex = _projects.indexWhere((project) => project.id == id);
      final running = status == ProposalStatus.active;
      final project = AgricultureProject(
        id: id,
        title: p.projectName,
        farmer: p.farmer,
        commodity: p.commodity,
        location: p.location,
        status: running ? ProjectStatus.growing : ProjectStatus.openForFunding,
        funding: Funding(
          target: p.fundingTarget!,
          collected: running ? p.fundingTarget! : Money.zero,
          investorCount: 0,
        ),
        roiMinPercent: 0,
        roiMaxPercent: 0,
        harvestCycleMonths: 4,
        createdAt: _details[id]!.plantingMonth,
      );
      if (projectIndex < 0) {
        _projects.add(project);
      } else {
        _projects[projectIndex] = project;
      }
    }
    if (status == ProposalStatus.completed) {
      final projectIndex = _projects.indexWhere((project) => project.id == id);
      if (projectIndex >= 0) {
        _projects[projectIndex] = _projects[projectIndex].copyWith(
          status: ProjectStatus.completed,
        );
      }
    } else if (FarmerStates.review.contains(status)) {
      _projects.removeWhere((project) => project.id == id);
    }
    notifyListeners();
  }
}
