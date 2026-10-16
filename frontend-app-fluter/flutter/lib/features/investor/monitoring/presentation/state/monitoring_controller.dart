import 'package:flutter/foundation.dart';

import '../../../common/status_view.dart';
import '../../data/investor_monitoring_repository.dart';

class MonitoringController extends ChangeNotifier with SafeNotifier {
  MonitoringController(this._repository, this.investmentId);

  final InvestorMonitoringRepository _repository;
  final String investmentId;

  LoadStatus _status = LoadStatus.initial;
  InvestorMonitoring? _data;

  LoadStatus get status => _status;
  InvestorMonitoring? get data => _data;

  Future<void> load() async {
    _status = LoadStatus.loading;
    notifyListeners();
    try {
      _data = await _repository.getMonitoring(investmentId);
      _status = _data == null ? LoadStatus.empty : LoadStatus.success;
    } catch (_) {
      _status = LoadStatus.error;
    }
    notifyListeners();
  }
}
