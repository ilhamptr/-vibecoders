import '../../../domain/user/user.dart';
import '../../../domain/user/user_role.dart';

/// Outcome of attempting to restore a session at app startup.
sealed class SessionBootstrapResult {
  const SessionBootstrapResult();
}

/// A valid session was restored with a single, unambiguous role; route
/// straight to the matching dashboard.
class SessionRestored extends SessionBootstrapResult {
  const SessionRestored({required this.role, required this.user});

  final UserRole role;

  /// The user resolved from `/user/me`. Its [User.role] matches [role].
  final User user;
}

/// A valid session, but the backend reports the account is both a farmer and
/// an investor (`role: "both"`). The user must pick which dashboard to open.
class SessionRoleChoiceRequired extends SessionBootstrapResult {
  const SessionRoleChoiceRequired({required this.id, required this.fullName});

  final String id;
  final String fullName;
}

/// No usable session (no token, token rejected, or role unknown).
/// The caller should send the user to the onboarding/login flow.
class SessionAbsent extends SessionBootstrapResult {
  const SessionAbsent();
}
