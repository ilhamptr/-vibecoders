import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../../domain/user/user_role.dart';
import '../domain/registration.dart';
import '../domain/registration_repository.dart';

class ApiRegistrationRepository implements RegistrationRepository {
  ApiRegistrationRepository(this._api, this._tokenStorage);

  final ApiClient _api;
  final TokenStorage _tokenStorage;

  bool _identityProfileCreated = false;
  bool _identityCardUploaded = false;
  bool _identificationSelfieUploaded = false;

  static const _ngrokHeaders = <String, String>{
    'ngrok-skip-browser-warning': 'true',
  };

  @override
  Future<RegisteredAccount> registerAccount({
    required String email,
    required String phone,
    required String password,
  }) async {
    final response = await _api.post(
      '/user/register',
      authenticated: false,
      headers: _ngrokHeaders,
      body: {'email': email, 'phone': phone, 'password': password},
    );
    final data = _jsonObject(response.data, '/user/register');
    final id = _requiredString(data, 'id');
    final registeredEmail = _requiredString(data, 'email');
    final accessToken = _requiredString(data, 'access_token');
    final refreshToken = data['refresh_token'];

    // Persist before subsequent calls so BearerRequestAuth can attach it.
    await _tokenStorage.writeTokens(
      accessToken: accessToken,
      refreshToken: refreshToken is String && refreshToken.isNotEmpty
          ? refreshToken
          : null,
    );

    // A new account starts a fresh, resumable profile-creation sequence.
    _identityProfileCreated = false;
    _identityCardUploaded = false;
    _identificationSelfieUploaded = false;

    return RegisteredAccount(id: id, email: registeredEmail);
  }

  @override
  Future<void> createIdentity({
    required String fullName,
    required DateTime dateOfBirth,
    required String sex,
    required String nik,
    required RegistrationDocument identityCard,
    required RegistrationDocument identificationSelfie,
  }) async {
    if (!_identityProfileCreated) {
      await _api.post(
        '/user/profile-creation',
        headers: _ngrokHeaders,
        body: {
          'full_name': fullName,
          'date_of_birth': _isoDate(dateOfBirth),
          'sex': sex,
          'nik': nik,
        },
      );
      _identityProfileCreated = true;
    }

    if (!_identityCardUploaded) {
      await _uploadDocument('identity card', identityCard);
      _identityCardUploaded = true;
    }
    if (!_identificationSelfieUploaded) {
      await _uploadDocument('identification selfie', identificationSelfie);
      _identificationSelfieUploaded = true;
    }
  }

  Future<void> _uploadDocument(
    String documentType,
    RegistrationDocument document,
  ) async {
    await _api.postMultipart(
      '/user/upload-user-document',
      headers: _ngrokHeaders,
      fields: {'document_type': documentType},
      files: [
        ApiMultipartFile(
          field: 'file',
          bytes: document.bytes,
          filename: document.filename,
        ),
      ],
    );
  }

  @override
  Future<void> createFarmerProfile({
    required String experience,
    required String commodity,
  }) async {
    await _api.post(
      '/user/farmer-profile',
      headers: _ngrokHeaders,
      body: {'experience': experience, 'commodity': commodity},
    );
    // Cache the role so the next launch can auto-login to the right dashboard.
    await _tokenStorage.writeUserRole(UserRole.farmer.storageValue);
  }

  @override
  Future<void> createInvestorProfile({
    required String occupation,
    required String income,
  }) async {
    await _api.post(
      '/user/investor-profile',
      headers: _ngrokHeaders,
      body: {'occupation': occupation, 'income': income},
    );
    // Cache the role so the next launch can auto-login to the right dashboard.
    await _tokenStorage.writeUserRole(UserRole.investor.storageValue);
  }

  static Map<String, dynamic> _jsonObject(Object? data, String endpoint) {
    if (data is Map<String, dynamic>) return data;
    throw StateError('Unexpected response from $endpoint.');
  }

  static String _requiredString(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is String && value.isNotEmpty) return value;
    throw StateError('Response is missing "$key".');
  }

  static String _isoDate(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
