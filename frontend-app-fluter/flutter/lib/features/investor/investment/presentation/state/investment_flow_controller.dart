import 'package:flutter/foundation.dart';

import '../../../../../domain/domain.dart';
import '../../../common/investment_math.dart';
import '../../../common/status_view.dart';
import '../../../project_detail/data/project_detail_repository.dart';
import '../../data/investment_repository.dart';

enum InvestmentStep { entry, review, success }

class InvestmentFlowController extends ChangeNotifier with SafeNotifier {
  InvestmentFlowController({
    required this.projectRepository,
    required this.investmentRepository,
    required this.investor,
    required this.projectId,
    this.minimumAmount = InvestmentAmountValidator.minimum,
    this.requireOpenFunding = true,
  });

  final ProjectDetailRepository projectRepository;
  final InvestmentRepository investmentRepository;
  final User investor;
  final String projectId;

  /// Smallest allowed amount; backend invest uses Rp10.000.
  final int minimumAmount;

  /// When false, skip the client-side open-funding/remaining checks and let
  /// the backend decide eligibility (used by the real invest flow).
  final bool requireOpenFunding;

  LoadStatus _projectStatus = LoadStatus.initial;
  AgricultureProject? _project;
  InvestmentStep _step = InvestmentStep.entry;
  String _amountText = '';
  String? _amountError;
  String? _submitError;
  bool _submitting = false;
  Investment? _created;

  LoadStatus get projectStatus => _projectStatus;
  AgricultureProject? get project => _project;
  InvestmentStep get step => _step;
  String get amountText => _amountText;
  String? get amountError => _amountError;
  String? get submitError => _submitError;
  bool get isSubmitting => _submitting;
  Investment? get createdInvestment => _created;

  /// Null until the text is a parseable integer.
  Money? get amount {
    final value = int.tryParse(_amountText.trim());
    return value == null ? null : Money(amount: value);
  }

  Future<void> load() async {
    _projectStatus = LoadStatus.loading;
    notifyListeners();
    try {
      _project = await projectRepository.getProjectById(projectId);
      _projectStatus = _project == null ? LoadStatus.empty : LoadStatus.success;
    } catch (_) {
      _projectStatus = LoadStatus.error;
    }
    notifyListeners();
  }

  void setAmountText(String value) {
    _amountText = value;
    _amountError = null;
    _submitError = null;
    notifyListeners();
  }

  /// Validates and, when valid, advances to the review step.
  bool continueToReview() {
    final project = _project;
    if (project == null) return false;
    final error = InvestmentAmountValidator.validate(
      _amountText,
      project,
      minimum: minimumAmount,
      requireOpenFunding: requireOpenFunding,
    );
    if (error != null) {
      _amountError = error;
      notifyListeners();
      return false;
    }
    _step = InvestmentStep.review;
    notifyListeners();
    return true;
  }

  void backToEntry() {
    if (_step != InvestmentStep.review || _submitting) return;
    _step = InvestmentStep.entry;
    notifyListeners();
  }

  /// Persists the investment through the repository contract.
  Future<void> confirm() async {
    final value = amount;
    if (_step != InvestmentStep.review || _submitting || value == null) return;
    _submitting = true;
    _submitError = null;
    notifyListeners();
    try {
      _created = await investmentRepository.createInvestment(
        investor: investor,
        projectId: projectId,
        amount: value,
      );
      _step = InvestmentStep.success;
    } catch (_) {
      _submitError = 'Investasi gagal. Periksa nominal dan coba lagi.';
      _step = InvestmentStep.entry;
    }
    _submitting = false;
    notifyListeners();
  }
}
