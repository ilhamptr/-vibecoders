import '../../../../domain/domain.dart';

abstract interface class ProjectDetailRepository {
  Future<AgricultureProject?> getProjectById(String projectId);
}
