import '../../../../../core/network/api_client.dart';

class ProjectRepository {
  ProjectRepository(this._api);
  final ApiClient _api;

  Future<List<Map<String, dynamic>>> getActiveInvestments() async {
    final res = await _api.get('/investment/get-active-investment', authenticated: true);
    return (res.data as List).cast<Map<String, dynamic>>();
  }

  // Future<Map<String, dynamic>> getProject(int id) async {
  //   final res = await _api.get('/projects/$id');
  //   return res.data as Map<String, dynamic>;
  // }

  Future<void> invest(int projectId, int amount) async {
    await _api.post(
      '/investment/invest/$projectId',
      body: {'amount': amount},
    );
  }
}