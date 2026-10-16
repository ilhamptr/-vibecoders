import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framework/features/auth/data/mock_farmer_auth_data_source.dart';
import 'package:framework/features/auth/presentation/pages/login_page.dart';
import 'package:framework/domain/user/user_role.dart';
import 'package:framework/features/auth/presentation/pages/register_page.dart';

void main() {
  testWidgets('farmer registration advances through the designed steps', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(home: RegisterPage(role: UserRole.farmer)),
    );

    expect(find.text('Halo Sahabat Tani!'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(0), 'first@example.com');
    await tester.enterText(find.byType(TextField).at(2), 'password123');
    await tester.enterText(find.byType(TextField).at(3), 'password123');
    await tester.tap(find.text('Selanjutnya'));
    await tester.pump();
    expect(find.text('Lengkapi Data Diri'), findsOneWidget);
    await tester.enterText(find.byType(TextField).at(0), 'First Farmer');

    await tester.tap(find.text('Selanjutnya'));
    await tester.pump();
    expect(find.text('Pengalaman Bertani Anda'), findsOneWidget);
    expect(find.text('Komoditas yang Sering Ditanam'), findsOneWidget);
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('1-3 tahun'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('1-3 tahun'));
    await tester.scrollUntilVisible(
      find.text('Padi'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Padi'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('completed farmer registration can be used for login', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: RegisterPage(role: UserRole.farmer)),
    );

    await tester.enterText(
      find.byType(TextField).at(0),
      'new-farmer@example.com',
    );
    await tester.enterText(find.byType(TextField).at(2), 'secret123');
    await tester.enterText(find.byType(TextField).at(3), 'secret123');
    await tester.tap(find.text('Selanjutnya'));
    await tester.pump();

    await tester.enterText(find.byType(TextField).at(0), 'New Farmer');
    await tester.enterText(find.byType(TextField).at(1), '01/01/1990');
    await tester.tap(find.text('Selanjutnya'));
    await tester.pump();
    await tester.scrollUntilVisible(
      find.text('1-3 tahun'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('1-3 tahun'));
    await tester.scrollUntilVisible(
      find.text('Padi'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Padi'));
    await tester.pump();
    await tester.tap(find.text('Selesai'));
    await tester.pumpAndSettle();

    expect(
      await MockFarmerAuthDataSource.instance.rolesFor(
        email: 'new-farmer@example.com',
        password: 'secret123',
      ),
      contains(UserRole.farmer),
    );
  });
}
