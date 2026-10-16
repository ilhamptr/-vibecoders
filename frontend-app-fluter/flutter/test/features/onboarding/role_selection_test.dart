import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framework/app/app.dart';
import 'package:framework/app/router/investor_routes.dart';
import 'package:framework/domain/domain.dart';
import 'package:framework/features/onboarding/role_selection/role_selection.dart';

import '../investor/investor_test_support.dart';

void main() {
  Widget host(void Function(UserRole) onContinue) =>
      MaterialApp(home: RoleSelectionPage(onContinue: onContinue));

  testWidgets('renders Farmer and Investor, Selanjutnya disabled initially', (
    tester,
  ) async {
    usePhoneSurface(tester, height: 874);
    await tester.pumpWidget(host((_) {}));

    expect(find.text('Saya Ingin Bergabung Sebagai'), findsOneWidget);
    expect(find.text('Petani / Pemilik Lahan'), findsOneWidget);
    expect(find.text('Investor'), findsOneWidget);
    expect(find.text('Selanjutnya'), findsOneWidget);
  });

  testWidgets('does not continue until a role is selected', (tester) async {
    usePhoneSurface(tester, height: 874);
    final emitted = <UserRole>[];
    await tester.pumpWidget(host(emitted.add));

    await tester.tap(find.text('Selanjutnya'));
    await tester.pump();

    expect(emitted, isEmpty);
  });

  testWidgets('emits the selected UserRole through onContinue', (tester) async {
    usePhoneSurface(tester, height: 874);
    final emitted = <UserRole>[];
    await tester.pumpWidget(host(emitted.add));

    await tester.tap(find.text('Investor'));
    await tester.pump();
    await tester.tap(find.text('Selanjutnya'));
    await tester.pump();
    expect(emitted, [UserRole.investor]);

    await tester.tap(find.text('Petani / Pemilik Lahan'));
    await tester.pump();
    await tester.tap(find.text('Selanjutnya'));
    await tester.pump();
    expect(emitted, [UserRole.investor, UserRole.farmer]);
  });

  testWidgets('Investor selection navigates to the Investor home', (
    tester,
  ) async {
    usePhoneSurface(tester, height: 874);
    InvestorRoutes.dependencies = mockDependencies();
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Investor'));
    await tester.pump();
    await tester.tap(find.text('Selanjutnya'));
    await tester.pumpAndSettle();

    expect(find.text('Dana Diinvestasikan'), findsOneWidget);
    expect(find.text('Beranda'), findsOneWidget);
  });

  testWidgets('Farmer selection opens the Farmer dashboard', (tester) async {
    usePhoneSurface(tester, height: 874);
    InvestorRoutes.dependencies = mockDependencies();
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Petani / Pemilik Lahan'));
    await tester.pump();
    await tester.tap(find.text('Selanjutnya'));
    await tester.pumpAndSettle();

    expect(find.text('Dana Tertunda'), findsOneWidget);
    expect(find.text('Pendanaan'), findsOneWidget);
    expect(find.byTooltip('Buat Proposal'), findsOneWidget);
    expect(find.text('Dana Diinvestasikan'), findsNothing);
  });
}
