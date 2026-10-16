import 'package:flutter/foundation.dart';

import '../../../../../domain/domain.dart';
import '../../../common/status_view.dart';
import '../../data/marketplace_repository.dart';

class MarketplaceController extends ChangeNotifier with SafeNotifier {
  MarketplaceController(this._repository);

  final MarketplaceRepository _repository;

  LoadStatus _status = LoadStatus.initial;
  List<AgricultureProject> _projects = const [];
  Commodity? _selectedCommodity;

  LoadStatus get status => _status;
  Commodity? get selectedCommodity => _selectedCommodity;

  /// Projects after the sector filter has been applied.
  List<AgricultureProject> get visibleProjects => _selectedCommodity == null
      ? _projects
      : _projects.where((p) => p.commodity == _selectedCommodity).toList();

  /// Data loaded, but the active sector filter matches nothing.
  bool get isFilteredEmpty =>
      _status == LoadStatus.success && visibleProjects.isEmpty;

  Future<void> load() async {
    _status = LoadStatus.loading;
    notifyListeners();
    try {
      _projects = await _repository.getProjects();
      _status = _projects.isEmpty ? LoadStatus.empty : LoadStatus.success;
    } catch (_) {
      _status = LoadStatus.error;
    }
    notifyListeners();
  }

  /// Selecting the active sector again clears the filter.
  void selectCommodity(Commodity commodity) {
    _selectedCommodity = _selectedCommodity == commodity ? null : commodity;
    notifyListeners();
  }

  void clearCommodity() {
    if (_selectedCommodity == null) return;
    _selectedCommodity = null;
    notifyListeners();
  }
}
