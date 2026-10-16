import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framework/features/farmer/data/fake_farmer_fund_repository.dart';
import 'package:framework/features/farmer/data/fake_farmer_investment_repository.dart';
import 'package:framework/features/farmer/data/mock_farmer_store.dart';
import 'package:framework/features/farmer/shell/farmer_shell.dart';
import 'package:framework/features/investor/wallet/data/fake_wallet_topup_repository.dart';

void main() {
  testWidgets('renders farmer dashboard funding and running states', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(393, 852));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: FarmerShell(
          repository: MockFarmerStore(),
          fundRepository: const FakeFarmerFundRepository(
            latency: Duration.zero,
          ),
          walletTopUp: const FakeWalletTopUpRepository(latency: Duration.zero),
          investmentRepository: FakeFarmerInvestmentRepository(
            latency: Duration.zero,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Halo!'), findsOneWidget);
    expect(find.text('Wowok Sutoyok'), findsOneWidget);
    expect(find.text('Dana Investor'), findsOneWidget);
    expect(find.text('Saldo Wallet'), findsOneWidget);
    expect(find.text('Sedang Berjalan'), findsOneWidget);
    expect(find.text('Selesai'), findsOneWidget);
    expect(find.text('Perkebunan Cabai Alam Sutera'), findsOneWidget);
    expect(find.text('Investor Saat Ini'), findsOneWidget);
    expect(find.text('Tanggal Selesai'), findsOneWidget);
    expect(find.text('Kirim Update'), findsOneWidget);
    expect(find.text('Kirim Laporan'), findsOneWidget);

    await tester.tap(find.text('Selesai'));
    await tester.pumpAndSettle();

    expect(find.text('Sawah Pak Wowok'), findsOneWidget);
    expect(find.text('Kirim Update'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
