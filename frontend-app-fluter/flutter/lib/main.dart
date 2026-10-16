import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/router/app_router.dart';
import 'app/router/farmer_routes.dart';
import 'core/network/api_client.dart';
import 'core/network/request_auth.dart';
import 'core/storage/token_storage.dart';
import 'core/storage/secure_token_storage.dart';
import 'core/config/app_environment.dart';
import 'features/auth/data/api_login_repository.dart';
import 'features/auth/data/api_registration_repository.dart';
import 'features/auth/data/session_bootstrapper.dart';
import 'features/auth/data/session_role_data_source.dart';
import 'features/farmer/data/api_farmer_fund_repository.dart';
import 'features/farmer/data/api_farmer_store.dart';
import 'features/farmer/data/api_farmer_investment_repository.dart';
import 'features/investor/wallet/data/wallet_topup_repository.dart';

/// Shared token store. A successful login must call
/// [tokenStorage.writeTokens] so the Bearer header is attached to
/// authenticated requests. For local testing against a real backend you can
/// seed it directly, e.g. in [main]:

// tokenStorage.writeTokens(accessToken: '<paste-token>');

final TokenStorage tokenStorage = SecureTokenStorage();

/// Authenticated API client. [BearerRequestAuth] reads the access token from
/// [tokenStorage] on every request where `authenticated: true` (the default)
/// and sets `Authorization: Bearer <token>`.
final apiClient = ApiClient(
  baseUrl: AppEnvironment.apiBaseUrl,
  auth: BearerRequestAuth(tokenStorage),
);

/// Temporary access token for local testing until the login flow exists.
///
/// Pass it at run time so it never gets committed:
///   flutter run \
///     --dart-define=API_BASE_URL=<backend-url> \
///     --dart-define=DEV_ACCESS_TOKEN=<token>
///
/// TODO: remove once the real login writes the token to [tokenStorage].
const _devAccessToken = String.fromEnvironment('DEV_ACCESS_TOKEN');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppEnvironment.validate();

  if (_devAccessToken.isNotEmpty) {
    await tokenStorage.writeTokens(accessToken: _devAccessToken);
  }

  AppRouter.registrationRepository = ApiRegistrationRepository(
    apiClient,
    tokenStorage,
  );

  // New proposals go through /area/create-land → /investment/create-investment
  // → /investment/investment-fund-details, in that order.
  FarmerRoutes.repository = ApiFarmerStore(apiClient);

  // Farmer dashboard balance comes from GET /investment/get-farmer-fund.
  FarmerRoutes.fundRepository = ApiFarmerFundRepository(apiClient);

  // Farmer deposit goes through POST /payment/top-up-wallet.
  FarmerRoutes.walletTopUp = ApiWalletTopUpRepository(apiClient);

  // Farmer home project list comes from GET /investment/get-farmers-investments.
  FarmerRoutes.investmentRepository = ApiFarmerInvestmentRepository(apiClient);

  // Shared /user/me reader used by both auto-login and manual login.
  final meDataSource = ApiSessionMeDataSource(apiClient);

  // Enables auto-login: on launch the splash screen asks this to restore any
  // valid session (via GET /user/me) and route straight to the right dashboard.
  AppRouter.sessionBootstrapper = SessionBootstrapper(
    tokenStorage: tokenStorage,
    meDataSource: meDataSource,
  );

  // Real backend login for the manual sign-in screen.
  AppRouter.loginRepository = ApiLoginRepository(
    apiClient,
    tokenStorage,
    meDataSource,
  );

  runApp(const App());
}
