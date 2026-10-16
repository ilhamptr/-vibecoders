import 'package:flutter/material.dart';

import '../../../../app/router/farmer_routes.dart';
import '../../../../app/router/investor_routes.dart';
import '../../../../domain/user/user.dart';
import '../../../../domain/user/user_role.dart';
import '../../../../domain/user/auth_session.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../auth_session_manager.dart';
import '../../data/mock_farmer_auth_data_source.dart';
import '../../data/session_role_data_source.dart';
import '../../domain/login_repository.dart';
import '../../../onboarding/role_selection/presentation/widgets/role_selection_card.dart';

typedef LoginRoleResolver = Future<List<UserRole>> Function(
  String email,
  String password,
);

Future<List<UserRole>> _defaultRoleResolver(
  String email,
  String password,
) async {
  return MockFarmerAuthDataSource.instance.rolesFor(
    email: email,
    password: password,
  );
}

class LoginRolePage extends StatefulWidget {
  const LoginRolePage({
    super.key,
    required this.onContinue,
    this.availableRoles = UserRole.values,
  });

  final ValueChanged<UserRole> onContinue;
  final List<UserRole> availableRoles;

  @override
  State<LoginRolePage> createState() => _LoginRolePageState();
}

class _LoginRolePageState extends State<LoginRolePage> {
  UserRole? _role;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFBFFFF),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.sizeOf(context).height - 40,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Saya Ingin Masuk Sebagai',
                style: TextStyle(
                  color: Color(0xFF20252B),
                  fontSize: 23,
                  height: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),
              for (final role in widget.availableRoles) ...[
                RoleSelectionCard(
                  label: role == UserRole.farmer
                      ? 'Petani / Pemilik Lahan'
                      : 'Investor',
                  image: role == UserRole.farmer
                      ? 'assets/onboarding/role_selection/farmer.png'
                      : 'assets/onboarding/role_selection/investor.png',
                  selected: _role == role,
                  onTap: () => setState(() => _role = role),
                ),
                if (role != widget.availableRoles.last)
                  const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    ),
    bottomNavigationBar: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
        child: AppButton(
          label: 'Selanjutnya',
          backgroundColor: const Color(0xFF319AC9),
          height: 44,
          borderRadius: 12,
          onPressed: _role == null ? null : () => widget.onContinue(_role!),
        ),
      ),
    ),
  );
}

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
    this.role,
    this.resolveRoles = _defaultRoleResolver,
    this.repository,
  });

  final UserRole? role;
  final LoginRoleResolver resolveRoles;

  /// Real backend login. When provided (production), the Next button calls
  /// `POST /user/login` + `GET /user/me`. When null (widget tests), the legacy
  /// [resolveRoles] mock path is used instead.
  final LoginRepository? repository;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_email.text.trim().isEmpty || _password.text.isEmpty) {
      _showError('Email dan password wajib diisi.');
      return;
    }

    if (widget.repository != null) {
      await _loginWithBackend(widget.repository!);
      return;
    }

    final roles = widget.role == null
        ? await widget.resolveRoles(_email.text.trim(), _password.text)
        : [widget.role!];
    if (!mounted) return;

    if (roles.isEmpty) {
      _showError('Email atau password salah.');
      return;
    }
    if (roles.length > 1) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          settings: const RouteSettings(name: '/auth/login-role'),
          builder: (_) =>
              LoginRolePage(availableRoles: roles, onContinue: _openMockHome),
        ),
      );
      return;
    }
    _openMockHome(roles.single);
  }

  Future<void> _loginWithBackend(LoginRepository repository) async {
    setState(() => _busy = true);
    try {
      final outcome = await repository.login(
        email: _email.text.trim(),
        password: _password.text,
      );
      if (!mounted) return;

      final identity = outcome.identity;
      if (identity.role == MeRole.both) {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            settings: const RouteSettings(name: '/auth/login-role'),
            builder: (_) => LoginRolePage(
              onContinue: (role) => _enterDashboard(
                role,
                User(
                  id: identity.id,
                  name: identity.fullName,
                  role: role,
                  isVerified: identity.isVerified,
                ),
              ),
            ),
          ),
        );
        return;
      }

      final role = identity.role.asUserRole!;
      _enterDashboard(
        role,
        User(
          id: identity.id,
          name: identity.fullName,
          role: role,
          isVerified: identity.isVerified,
        ),
      );
    } on InvalidCredentialsException catch (e) {
      if (mounted) _showError(e.message);
    } on RoleUnresolvedException catch (e) {
      if (mounted) _showError(e.message);
    } catch (_) {
      if (mounted) _showError('Tidak dapat terhubung ke server.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _enterDashboard(UserRole role, User user) {
    AuthSessionManager.instance.setSession(
      AuthSession(user: user, authenticatedAt: DateTime.now()),
    );
    final destination = role == UserRole.farmer
        ? FarmerRoutes.home
        : InvestorRoutes.home;
    Navigator.of(context).pushReplacementNamed(destination);
  }

  /// Legacy mock path used by widget tests (no backend repository).
  void _openMockHome(UserRole role) {
    if (role == UserRole.farmer) {
      final user = MockFarmerAuthDataSource.instance.userFor(_email.text);
      AuthSessionManager.instance.setSession(
        AuthSession(user: user, authenticatedAt: DateTime.now()),
      );
    }
    final destination = role == UserRole.farmer
        ? FarmerRoutes.home
        : InvestorRoutes.home;
    Navigator.of(context).pushReplacementNamed(destination);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFFBFFFF),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Halo Sahabat!',
              style: TextStyle(
                color: Color(0xFF20252B),
                fontSize: 23,
                height: 1.2,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Kami senang melihatmu kembali silahkan\nmasukan data dirimu terlebih dahulu',
              style: TextStyle(
                color: Color(0xFF999999),
                fontSize: 16,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 24),
            _LoginField(
              label: 'Email',
              hint: 'Masukkan nama lengkap',
              controller: _email,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            _LoginField(
              label: 'Password',
              hint: 'Buat password anda',
              controller: _password,
              obscureText: true,
            ),
          ],
        ),
      ),
    ),
    bottomNavigationBar: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
        child: AppButton(
          label: 'Selanjutnya',
          backgroundColor: const Color(0xFF319AC9),
          height: 44,
          borderRadius: 12,
          isLoading: _busy,
          onPressed: _busy ? null : _continue,
        ),
      ),
    ),
  );
}

class _LoginField extends StatelessWidget {
  const _LoginField({
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType,
    this.obscureText = false,
  });

  final String label;
  final String hint;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final bool obscureText;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 8),
      TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
          ),
        ),
      ),
    ],
  );
}
