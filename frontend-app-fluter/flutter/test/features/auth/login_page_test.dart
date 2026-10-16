import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framework/features/auth/auth_session_manager.dart';
import 'package:framework/domain/user/user_role.dart';
import 'package:framework/features/auth/presentation/pages/login_page.dart';

void main() {
  testWidgets('login flow selects a role then opens credentials', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    UserRole? selected;
    await tester.pumpWidget(
      MaterialApp(home: LoginRolePage(onContinue: (role) => selected = role)),
    );

    expect(find.text('Saya Ingin Masuk Sebagai'), findsOneWidget);
    expect(find.text('Selanjutnya'), findsOneWidget);

    await tester.tap(find.text('Investor'));
    await tester.pump();
    await tester.tap(find.text('Selanjutnya'));
    await tester.pump();

    expect(selected, UserRole.investor);
  });

  testWidgets('login credentials screen renders both fields', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: LoginPage(role: UserRole.farmer)),
    );

    expect(find.text('Halo Sahabat!'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Selanjutnya'), findsOneWidget);
  });

  testWidgets('single-role login skips role selection', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        routes: {
          '/farmer/home': (_) => const Scaffold(body: Text('Farmer home')),
        },
        home: LoginPage(
          resolveRoles: (email, password) async => const [UserRole.farmer],
        ),
      ),
    );

    await tester.enterText(find.byType(TextField).at(0), 'farmer@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'password');
    await tester.tap(find.text('Selanjutnya'));
    await tester.pumpAndSettle();

    expect(find.text('Saya Ingin Masuk Sebagai'), findsNothing);
    expect(find.text('Farmer home'), findsOneWidget);
    expect(AuthSessionManager.instance.current?.user.isFarmer, isTrue);
    AuthSessionManager.instance.clear();
  });

  testWidgets('multiple-role login shows role selection after credentials', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: LoginPage(
          resolveRoles: (email, password) async => const [
            UserRole.farmer,
            UserRole.investor,
          ],
        ),
      ),
    );

    expect(find.text('Saya Ingin Masuk Sebagai'), findsNothing);
    await tester.enterText(find.byType(TextField).at(0), 'both@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'password');
    await tester.tap(find.text('Selanjutnya'));
    await tester.pumpAndSettle();

    expect(find.text('Saya Ingin Masuk Sebagai'), findsOneWidget);
    expect(find.text('Investor'), findsOneWidget);
  });
}
