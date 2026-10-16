// import 'package:flutter/material.dart';

// import '../../domain/user/user_role.dart';
// import '../../features/onboarding/role_selection/role_selection.dart';
// import 'farmer_routes.dart';
// import 'investor_routes.dart';

// abstract final class AppRouter {
//   static const roleSelection = '/onboarding/select-role';

//   static Route<dynamic> onGenerateRoute(RouteSettings settings) {
//     final farmerRoute = FarmerRoutes.onGenerateRoute(settings);
//     if (farmerRoute != null) return farmerRoute;
//     final investorRoute = InvestorRoutes.onGenerateRoute(settings);
//     if (investorRoute != null) return investorRoute;
//     switch (settings.name) {
//       case '/':
//       case roleSelection:
//         return MaterialPageRoute<void>(
//           settings: settings,
//           builder: (context) => RoleSelectionPage(
//             onContinue: (role) {
//               final route = role == UserRole.farmer
//                   ? FarmerRoutes.home
//                   : InvestorRoutes.home;
//               Navigator.of(context).pushReplacementNamed(route);
//             },
//           ),
//         );

//       default:
//         return MaterialPageRoute<void>(
//           settings: settings,
//           builder: (_) => Scaffold(
//             body: Center(
//               child: Text('Route tidak ditemukan: ${settings.name}'),
//             ),
//           ),
//         );
//     }
//   }
// }

import 'package:flutter/material.dart';

import '../../domain/user/user_role.dart';
import '../../features/auth/data/fake_registration_repository.dart';
import '../../features/auth/data/session_bootstrapper.dart';
import '../../features/auth/domain/login_repository.dart';
import '../../features/auth/domain/registration_repository.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/onboarding/role_selection/role_selection.dart';
import 'farmer_routes.dart';
import 'investor_routes.dart';

// import '../../features/onboarding/initial/initial_page.dart'; // sesuaikan path

abstract final class AppRouter {
  static RegistrationRepository registrationRepository =
      const FakeRegistrationRepository();

  /// Injected in `main` so the splash screen can restore an existing session.
  static SessionBootstrapper? sessionBootstrapper;

  /// Injected in `main` so the login screen can call the real backend.
  /// Null in tests, where [LoginPage] falls back to its mock resolver.
  static LoginRepository? loginRepository;

  static const splash = '/';
  static const onboarding = '/onboarding';
  static const roleSelection = '/onboarding/select-role';
  static const register = '/auth/register';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final farmerRoute = FarmerRoutes.onGenerateRoute(settings);
    if (farmerRoute != null) return farmerRoute;
    final investorRoute = InvestorRoutes.onGenerateRoute(settings);
    if (investorRoute != null) return investorRoute;
    switch (settings.name) {
      case splash:
        final bootstrapper = sessionBootstrapper;
        if (bootstrapper == null) {
          // No bootstrapper wired (e.g. a widget test): skip auto-login.
          return MaterialPageRoute<void>(
            settings: settings,
            builder: (_) => const OnboardingPage(),
          );
        }
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => SplashPage(bootstrapper: bootstrapper),
        );
      case onboarding:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => const OnboardingPage(),
        );
      case roleSelection:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (context) => RoleSelectionPage(
            onContinue: (role) {
              Navigator.of(context).pushNamed(register, arguments: role);
            },
          ),
        );
      case register:
        final role = settings.arguments;
        if (role is! UserRole) {
          return MaterialPageRoute<void>(
            builder: (_) => const Scaffold(
              body: Center(child: Text('Peran pengguna tidak ditemukan')),
            ),
          );
        }
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) =>
              RegisterPage(role: role, repository: registrationRepository),
        );

      default:
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Route tidak ditemukan: ${settings.name}'),
            ),
          ),
        );
    }
  }
}
