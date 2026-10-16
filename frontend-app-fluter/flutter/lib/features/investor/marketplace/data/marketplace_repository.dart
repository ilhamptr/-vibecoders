import '../../../../domain/domain.dart';

abstract interface class MarketplaceRepository {
  Future<List<AgricultureProject>> getProjects({Commodity? commodity});
}
