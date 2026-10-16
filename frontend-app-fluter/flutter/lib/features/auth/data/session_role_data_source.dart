import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../domain/user/user_role.dart';

/// Resolves the signed-in user's identity + role from the backend using the
/// stored Bearer token. Never throws for an auth failure; instead it reports
/// one of the [SessionMeStatus] cases the bootstrapper cares about.
abstract interface class SessionMeDataSource {
  Future<SessionMeResult> fetchMe();
}

enum SessionMeStatus {
  /// Token is valid and the identity (incl. role) was read.
  resolved,

  /// Token was rejected by the backend (401/403). It should be discarded.
  invalid,

  /// Could not reach the backend (network/timeout), the endpoint is missing,
  /// or the response was unexpected. The token may still be good; the caller
  /// may fall back to a cached role.
  indeterminate,
}

/// Role as reported by `GET /user/me`. `both` means the account holds farmer
/// and investor profiles and the user must choose a dashboard.
enum MeRole { farmer, investor, both }

/// Parsed `/user/me` payload.
class MeIdentity {
  const MeIdentity({
    required this.id,
    required this.fullName,
    required this.role,
    required this.isVerified,
  });

  final String id;
  final String fullName;
  final MeRole role;
  final bool isVerified;
}

class SessionMeResult {
  const SessionMeResult(this.status, [this.identity]);

  final SessionMeStatus status;
  final MeIdentity? identity;

  static const invalid = SessionMeResult(SessionMeStatus.invalid);
  static const indeterminate = SessionMeResult(SessionMeStatus.indeterminate);
  static SessionMeResult resolved(MeIdentity identity) =>
      SessionMeResult(SessionMeStatus.resolved, identity);
}

/// Calls `GET /user/me`, which returns:
/// `{"id": "...", "full_name": "...", "role": "farmer"|"investor"|"both",
///   "is_verified": true}`
class ApiSessionMeDataSource implements SessionMeDataSource {
  const ApiSessionMeDataSource(this._api, {this.endpoint = '/user/me'});

  final ApiClient _api;
  final String endpoint;

  // Free-tier ngrok otherwise returns its browser-warning HTML page.
  static const _ngrokHeaders = <String, String>{
    'ngrok-skip-browser-warning': 'true',
  };

  @override
  Future<SessionMeResult> fetchMe() async {
    try {
      final res = await _api.get(
        endpoint,
        authenticated: true,
        headers: _ngrokHeaders,
      );
      final data = res.data;
      if (data is! Map<String, dynamic>) {
        debugPrint(
          'ApiSessionMeDataSource: unexpected response ${data.runtimeType} '
          'from $endpoint',
        );
        return SessionMeResult.indeterminate;
      }

      final role = _parseRole(data['role']?.toString());
      if (role == null) {
        debugPrint(
          'ApiSessionMeDataSource: unknown "role" in $endpoint response '
          '(got: ${data['role']})',
        );
        return SessionMeResult.indeterminate;
      }

      final identity = MeIdentity(
        id: (data['id'] ?? '').toString(),
        fullName: (data['full_name'] ?? '').toString().trim(),
        role: role,
        isVerified: data['is_verified'] == true,
      );
      return SessionMeResult.resolved(identity);
    } on ApiException catch (error) {
      switch (error.type) {
        case ApiFailureType.unauthenticated:
        case ApiFailureType.forbidden:
          return SessionMeResult.invalid;
        case ApiFailureType.notFound:
          debugPrint(
            'ApiSessionMeDataSource: $endpoint returned 404; '
            'is /user/me deployed?',
          );
          return SessionMeResult.indeterminate;
        case ApiFailureType.network:
        case ApiFailureType.timeout:
        case ApiFailureType.validation:
        case ApiFailureType.server:
        case ApiFailureType.unknown:
          return SessionMeResult.indeterminate;
      }
    }
  }

  static MeRole? _parseRole(String? value) {
    final normalized = value?.trim().toLowerCase();
    switch (normalized) {
      case 'both':
        return MeRole.both;
      case 'farmer':
      case 'petani':
        return MeRole.farmer;
      case 'investor':
      case 'pemodal':
        return MeRole.investor;
      default:
        return null;
    }
  }
}

extension MeRoleX on MeRole {
  /// The concrete [UserRole] for an unambiguous role, or null for [MeRole.both].
  UserRole? get asUserRole => switch (this) {
    MeRole.farmer => UserRole.farmer,
    MeRole.investor => UserRole.investor,
    MeRole.both => null,
  };
}
