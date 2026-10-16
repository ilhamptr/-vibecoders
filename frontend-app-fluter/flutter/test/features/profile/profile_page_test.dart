import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framework/domain/user/auth_session.dart';
import 'package:framework/domain/user/user_role.dart';
import 'package:framework/domain/user/user.dart';
import 'package:framework/features/auth/auth_session_manager.dart';
import 'package:framework/features/profile/presentation/pages/profile_page.dart';

void main() {
  testWidgets('profile screen renders role selection and account actions', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: ProfilePage(
          role: UserRole.investor,
          name: 'Wowok Sutoyok',
          avatar: const AssetImage('assets/farmer/design/avatar.png'),
          onLogout: () {},
        ),
      ),
    );

    expect(find.text('Profil'), findsOneWidget);
    expect(find.text('Wowok Sutoyok'), findsOneWidget);
    expect(find.text('KYC Terverifikasi'), findsOneWidget);
    expect(find.text('Peran Saya'), findsOneWidget);
    expect(find.text('Akun'), findsOneWidget);
    expect(find.text('Edit Profil'), findsOneWidget);
    expect(find.text('Ubah Password'), findsOneWidget);
    expect(find.text('Notifikasi'), findsOneWidget);
    expect(find.text('Keluar'), findsOneWidget);

    await tester.tap(find.text('Petani / Pemilik Lahan'));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('logout callback can clear the active farmer session', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    AuthSessionManager.instance.setSession(
      AuthSession(
        user: const User(
          id: 'farmer@example.com',
          name: 'Budi Santoso',
          role: UserRole.farmer,
        ),
        authenticatedAt: DateTime.now(),
      ),
    );

    var loggedOut = false;
    await tester.pumpWidget(
      MaterialApp(
        home: ProfilePage(
          role: UserRole.farmer,
          name: 'Budi Santoso',
          avatar: const AssetImage('assets/farmer/design/avatar.png'),
          onLogout: () {
            AuthSessionManager.instance.clear();
            loggedOut = true;
          },
        ),
      ),
    );

    await tester.scrollUntilVisible(
      find.text('Keluar'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Keluar'));
    await tester.pump();

    expect(loggedOut, isTrue);
    expect(AuthSessionManager.instance.isAuthenticated, isFalse);
  });
}
