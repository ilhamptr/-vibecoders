import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framework/domain/user/user_role.dart';
import 'package:framework/features/auth/presentation/pages/register_page.dart';

void main() {
  testWidgets('investor registration follows the designed three-step flow', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const MaterialApp(home: RegisterPage(role: UserRole.investor)),
    );

    expect(find.text('Halo Sahabat Tani!'), findsOneWidget);
    expect(find.text('Selanjutnya'), findsOneWidget);

    await tester.tap(find.text('Selanjutnya'));
    await tester.pump();
    expect(find.text('Lengkapi Data Diri'), findsOneWidget);
    expect(find.text('Upload Foto'), findsNWidgets(2));

    await tester.tap(find.text('Selanjutnya'));
    await tester.pump();
    expect(find.text('Profil Investasi Anda'), findsOneWidget);
    expect(find.text('Pekerjaan'), findsOneWidget);
    expect(find.text('Penghasilan per Bulan'), findsOneWidget);
    expect(find.text('Selesai'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
