import '../../../domain/user/user.dart';
import '../../../domain/user/user_role.dart';

/// Local farmer auth adapter used until the remote auth contract is connected.
///
/// Registration and login share this store so the farmer flow behaves like one
/// cohesive feature instead of using unrelated screen-only mocks.
class MockFarmerAuthDataSource {
  MockFarmerAuthDataSource._();

  static final instance = MockFarmerAuthDataSource._();

  final Map<String, _FarmerAccount> _accounts = {
    'farmer@example.com': const _FarmerAccount(
      name: 'Budi Santoso',
      password: 'password',
    ),
  };

  Future<List<UserRole>> rolesFor({
    required String email,
    required String password,
  }) async {
    final account = _accounts[email.trim().toLowerCase()];
    if (account == null || account.password != password) {
      return const [];
    }
    return const [UserRole.farmer];
  }

  Future<User> registerFarmer({
    required String name,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty || password.isEmpty) {
      throw const FormatException('Email dan password wajib diisi.');
    }
    if (_accounts.containsKey(normalizedEmail)) {
      throw StateError('Email sudah terdaftar.');
    }

    _accounts[normalizedEmail] = _FarmerAccount(
      name: name.trim().isEmpty ? 'Petani' : name.trim(),
      password: password,
    );
    return _userFor(normalizedEmail, _accounts[normalizedEmail]!);
  }

  User userFor(String email) {
    final normalizedEmail = email.trim().toLowerCase();
    final account = _accounts[normalizedEmail];
    if (account == null) {
      throw StateError('Akun petani tidak ditemukan.');
    }
    return _userFor(normalizedEmail, account);
  }

  User _userFor(String email, _FarmerAccount account) {
    return User(
      id: email,
      name: account.name,
      role: UserRole.farmer,
      isVerified: false,
    );
  }
}

class _FarmerAccount {
  const _FarmerAccount({required this.name, required this.password});

  final String name;
  final String password;
}
