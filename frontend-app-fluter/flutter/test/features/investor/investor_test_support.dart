import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framework/app/router/app_router.dart';
import 'package:framework/app/router/investor_routes.dart';
import 'package:framework/app/theme/app_theme.dart';
import 'package:framework/features/investor/data/mock/mock_investor_store.dart';
import 'package:framework/features/investor/investor_dependencies.dart';

/// A phone-sized, tall surface so lists do not need scrolling in most tests.
void usePhoneSurface(WidgetTester tester, {double height = 1800}) {
  tester.view.physicalSize = Size(402, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

/// Mock dependencies with no artificial latency. Every fake repository shares
/// the one [store].
InvestorDependencies mockDependencies({MockInvestorStore? store}) =>
    InvestorDependencies.mock(store: store, latency: Duration.zero);

MockInvestorStore emptyStore() =>
    MockInvestorStore(projects: const [], investments: const []);

/// Installs [dependencies] into the Investor routes and returns an app that
/// starts at [initialRoute] through the real shared [AppRouter].
Widget routedApp(
  InvestorDependencies dependencies, {
  String initialRoute = InvestorRoutes.home,
}) {
  InvestorRoutes.dependencies = dependencies;
  return MaterialApp(
    theme: AppTheme.light,
    initialRoute: initialRoute,
    onGenerateRoute: AppRouter.onGenerateRoute,
  );
}
