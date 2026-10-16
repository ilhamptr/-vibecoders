import 'package:flutter/foundation.dart';

import '../../../../../domain/domain.dart';
import '../../../common/status_view.dart';
import '../../data/project_detail_repository.dart';

class ProjectDetailController extends ChangeNotifier with SafeNotifier {
  ProjectDetailController(this._repository, this.projectId);

  final ProjectDetailRepository _repository;
  final String projectId;

  LoadStatus _status = LoadStatus.initial;
  AgricultureProject? _project;

  LoadStatus get status => _status;
  AgricultureProject? get project => _project;
  bool get canInvest => _project?.isOpenForInvestment ?? false;

  Future<void> load() async {
    _status = LoadStatus.loading;
    notifyListeners();
    try {
      _project = await _repository.getProjectById(projectId);
      _status = _project == null ? LoadStatus.empty : LoadStatus.success;
    } catch (_) {
      _status = LoadStatus.error;
    }
    notifyListeners();
  }
}
