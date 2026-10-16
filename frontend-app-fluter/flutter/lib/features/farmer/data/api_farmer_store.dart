import '../../../core/network/api_client.dart';
import '../../../domain/domain.dart';
import 'api_farmer_proposal_service.dart';
import 'farmer_repository.dart';
import 'mock_farmer_store.dart';

/// Farmer repository whose proposal submission hits the real backend.
///
/// `submit` runs land → investment → fund details in order (see
/// [ApiFarmerProposalService]) and only records the proposal locally once all
/// three succeed. Other data (lists, activity, wallet history) is still served
/// by [MockFarmerStore] until those endpoints are wired.
class ApiFarmerStore extends MockFarmerStore {
  ApiFarmerStore(ApiClient api) : _service = ApiFarmerProposalService(api);

  ApiFarmerStore.withService(this._service);

  final ApiFarmerProposalService _service;

  @override
  Future<Proposal> submit(FarmerProposalDetails details) async {
    // Validate locally first so no partial data reaches the backend.
    validateDetails(details);
    await _service.submit(details);
    return super.submit(details);
  }
}
