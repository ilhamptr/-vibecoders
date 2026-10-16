import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../../../../app/router/farmer_routes.dart';
import '../../../../app/router/investor_routes.dart';
import '../../../../domain/user/auth_session.dart';
import '../../../../domain/user/user.dart';
import '../../../../domain/user/user_role.dart';
import '../../auth_session_manager.dart';
import '../../data/session_bootstrapper.dart';
import '../../domain/session_bootstrap.dart';
import 'login_page.dart';

/// First screen shown on launch. It resolves any stored session and then
/// replaces itself with the correct destination:
/// - a valid session with one role -> the farmer or investor dashboard;
/// - a valid session with role `both` -> a role chooser, then the dashboard;
/// - no session -> onboarding.
///
/// Keeping this decision in a dedicated route (instead of in `main`) means the
/// UI can show feedback while the backend round-trip runs, and navigation uses
/// the normal router.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key, required this.bootstrapper});

  final SessionBootstrapper bootstrapper;

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  static const _primaryBlue = Color(0xFF319AC9);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolve());
  }

  Future<void> _resolve() async {
    SessionBootstrapResult result;
    try {
      result = await widget.bootstrapper.bootstrap();
    } catch (_) {
      result = const SessionAbsent();
    }
    if (!mounted) return;

    switch (result) {
      case SessionRestored(:final role, :final user):
        _enterDashboard(role, user);
      case SessionRoleChoiceRequired(:final id, :final fullName):
        _askRole(id, fullName);
      case SessionAbsent():
        Navigator.of(context).pushReplacementNamed(AppRouter.onboarding);
    }
  }

  /// Account holds both profiles: let the user pick, then open that dashboard.
  void _askRole(String id, String fullName) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/auth/select-active-role'),
        builder: (_) => LoginRolePage(
          onContinue: (role) {
            _enterDashboard(
              role,
              User(id: id, name: fullName, role: role, isVerified: true),
            );
          },
        ),
      ),
    );
  }

  void _enterDashboard(UserRole role, User user) {
    AuthSessionManager.instance.setSession(
      AuthSession(user: user, authenticatedAt: DateTime.now()),
    );
    Navigator.of(context).pushReplacementNamed(_dashboardRouteFor(role));
  }

  String _dashboardRouteFor(UserRole role) =>
      role == UserRole.farmer ? FarmerRoutes.home : InvestorRoutes.home;

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: _primaryBlue,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'TaniFund',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 24),
            SizedBox(
              height: 28,
              width: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
