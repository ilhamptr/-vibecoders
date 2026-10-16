import 'investor_profile_repository.dart';

class FakeInvestorProfileRepository implements InvestorProfileRepository {
  const FakeInvestorProfileRepository(this.fullName);

  final String fullName;

  @override
  Future<String> getFullName() => Future.value(fullName);
}
