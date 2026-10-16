import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framework/features/onboarding/presentation/pages/onboarding_page.dart';

void main() {
  testWidgets('renders the first onboarding card composition', (tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: OnboardingPage()));
    await tester.pumpAndSettle();

    expect(find.text('Rencana Komoditas'), findsOneWidget);
    expect(find.text('Identifikasi Risiko'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('Wujudkan Rencana Tanam'), findsOneWidget);
    expect(find.text('Jadi Investor/Petani'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('CTA opens role selection', (tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: OnboardingPage()));
    await tester.tap(find.text('Jadi Investor/Petani'));
    await tester.pumpAndSettle();

    expect(find.text('Saya Ingin Bergabung Sebagai'), findsOneWidget);
  });

  testWidgets('Login opens credentials screen first', (tester) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: OnboardingPage()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('onboarding-login')));
    await tester.pumpAndSettle();

    expect(find.text('Halo Sahabat!'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });

  testWidgets('third onboarding slide renders its monitoring cards', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaterialApp(home: OnboardingPage()));
    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await tester.pumpAndSettle();

    expect(find.text('Dana Terkumpul'), findsOneWidget);
    expect(
      find.text('Tanaman masuk minggu ke-7, pertumbuhan merata.'),
      findsOneWidget,
    );
    expect(find.text('Rincian Penggunaan Dana'), findsOneWidget);
    expect(find.text('Bibit & Persemaian'), findsOneWidget);
    expect(find.text('Ikuti Setiap Perkembangan'), findsOneWidget);
  });
}
