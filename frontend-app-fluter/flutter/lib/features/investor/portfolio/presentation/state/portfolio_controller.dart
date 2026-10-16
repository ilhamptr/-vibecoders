import 'package:flutter/foundation.dart';

import '../../../../../domain/domain.dart';
import '../../../common/status_view.dart';
import '../../data/portfolio_repository.dart';

class PortfolioController extends ChangeNotifier with SafeNotifier {
  /// [initialFilter] seeds the status filter. The Home tab passes null (show
  /// everything the repository returns); the Portfolio tab passes
  /// [InvestmentStatus.active] since its backend requires a status.
  PortfolioController(this._repository, {InvestmentStatus? initialFilter})
    : _filter = initialFilter;

  final PortfolioRepository _repository;

  LoadStatus _status = LoadStatus.initial;
  List<Investment> _investments = const [];
  InvestmentStatus? _filter;

  LoadStatus get status => _status;
  InvestmentStatus? get filter => _filter;
  List<Investment> get investments => _investments;

  /// With server-side filtering the loaded list already matches the filter.
  List<Investment> get visibleInvestments => _investments;

  bool get isFilteredEmpty =>
      _status == LoadStatus.success && _investments.isEmpty;

  /// Sum of principals as integer money; formatting is a presentation concern.
  Money get totalInvested =>
      _investments.fold(Money.zero, (sum, i) => sum + i.principal);

  List<Investment> withStatuses(Set<InvestmentStatus> statuses) =>
      _investments.where((i) => statuses.contains(i.status)).toList();

  Future<void> load() async {
    _status = LoadStatus.loading;
    notifyListeners();
    try {
      // The backend requires a status; the repository defaults a null filter
      // to the active investments.
      _investments = await _repository.getInvestments(status: _filter);
      _status = _investments.isEmpty ? LoadStatus.empty : LoadStatus.success;
    } catch (_) {
      _status = LoadStatus.error;
    }
    notifyListeners();
  }

  /// Changes the status filter and reloads from the backend.
  void setFilter(InvestmentStatus? status) {
    if (_filter == status) return;
    _filter = status;
    load();
  }
}
