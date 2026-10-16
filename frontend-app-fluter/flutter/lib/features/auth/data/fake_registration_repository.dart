import '../domain/registration.dart';
import '../domain/registration_repository.dart';

/// Local/test adapter that preserves the registration UI without network I/O.
class FakeRegistrationRepository implements RegistrationRepository {
  const FakeRegistrationRepository();

  @override
  Future<RegisteredAccount> registerAccount({
    required String email,
    required String phone,
    required String password,
  }) async => RegisteredAccount(id: email, email: email);

  @override
  Future<void> createIdentity({
    required String fullName,
    required DateTime dateOfBirth,
    required String sex,
    required String nik,
    required RegistrationDocument identityCard,
    required RegistrationDocument identificationSelfie,
  }) async {}

  @override
  Future<void> createFarmerProfile({
    required String experience,
    required String commodity,
  }) async {}

  @override
  Future<void> createInvestorProfile({
    required String occupation,
    required String income,
  }) async {}
}
