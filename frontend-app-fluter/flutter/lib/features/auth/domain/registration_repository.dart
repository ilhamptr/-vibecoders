import 'registration.dart';

abstract interface class RegistrationRepository {
  Future<RegisteredAccount> registerAccount({
    required String email,
    required String phone,
    required String password,
  });

  Future<void> createIdentity({
    required String fullName,
    required DateTime dateOfBirth,
    required String sex,
    required String nik,
    required RegistrationDocument identityCard,
    required RegistrationDocument identificationSelfie,
  });

  Future<void> createFarmerProfile({
    required String experience,
    required String commodity,
  });

  Future<void> createInvestorProfile({
    required String occupation,
    required String income,
  });
}
