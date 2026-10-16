import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framework/app/router/app_router.dart';
import 'package:framework/app/router/farmer_routes.dart';
import 'package:framework/domain/domain.dart';
import 'package:framework/features/farmer/common/farmer_design.dart';
import 'package:framework/features/farmer/common/farmer_media_service.dart';
import 'package:framework/features/farmer/data/fake_farmer_fund_repository.dart';
import 'package:framework/features/farmer/data/fake_farmer_investment_repository.dart';
import 'package:framework/features/farmer/data/mock_farmer_store.dart';
import 'package:framework/features/investor/wallet/data/fake_wallet_topup_repository.dart';
import 'package:framework/features/farmer/proposal/presentation/pages/proposal_list_page.dart';
import 'package:framework/features/farmer/proposal/presentation/pages/proposal_wizard_page.dart';
import 'package:framework/features/farmer/proposal/presentation/pages/proposal_edit_page.dart';
import 'package:framework/features/farmer/proposal/presentation/state/proposal_wizard_controller.dart';
import 'package:framework/features/farmer/activity/farmer_activity_page.dart';
import 'package:framework/features/farmer/shell/farmer_shell.dart';

class TestMedia extends FarmerMediaService {
  TestMedia(this.bytes);
  final Uint8List bytes;
  @override
  Future<FarmerAttachment?> document() async =>
      FarmerAttachment('laporan.pdf', Uint8List.fromList([37, 80, 68, 70]));
  @override
  Future<FarmerAttachment?> photo({bool camera = true}) async =>
      FarmerAttachment('foto.png', bytes);
}

void phone(WidgetTester tester, {double width = 402, double height = 874}) {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget host(Widget page, {double scale = 1}) => MaterialApp(
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: child!,
  ),
  home: FarmerPresentation(child: page),
);
Future<void> screenshot(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('FARMER_SCREENSHOTS')) return;
  await tester.runAsync(() async {
    final context = tester.element(find.byKey(const ValueKey('capture')));
    for (final asset in ['chili.png', 'avatar.png', 'success.png']) {
      await precacheImage(AssetImage('${FarmerDesign.asset}$asset'), context);
    }
  });
  void repaint(RenderObject object) {
    object.visitChildren(repaint);
    object.markNeedsPaint();
  }

  repaint(tester.binding.renderViews.first);
  await tester.pump();
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('capture')),
    );
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory('artifacts/farmer').create(recursive: true);
    await File('artifacts/farmer/$name.png')
        .writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUpAll(() async {
    final font = FontLoader('Roboto')
      ..addFont(rootBundle.load('assets/fonts/Roboto-Regular.ttf'));
    await font.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  test(
    'wizard validates, preserves edits and prevents duplicate submissions',
    () async {
      final store = MockFarmerStore();
      final c = ProposalWizardController(repository: store);
      c.next();
      expect(c.step, 0);
      expect(c.error, isNotNull);
      c.draft.landName = 'Sawah Pak Budi';
      c.draft.address = 'Desa Sukamaju, Klaten, Jawa Tengah';
      c.draft.sppt = Uint8List.fromList('%PDF-1.4\n%%EOF\n'.codeUnits);
      c.draft.spptName = 'sppt.pdf';
      c.draft.location = MockFarmerStore.location;
      c.draft.area = 1.5;
      c.next();
      expect(c.step, 1);
      c.draft.commodity = Commodity.rice;
      c.draft.harvestTons = 7;
      c.draft.salePrice = 2500000;
      c.next();
      c.draft.budget['Bibit'] = 20000000;
      c.draft.budget['Pupuk'] = 10000000;
      c.next();
      c.draft.risks.add('Risiko Cuaca');
      c.next();
      expect(c.step, 4);
      expect(farmerMonth(c.draft.harvestMonth), 'Agustus 2026');
      c.edit(1);
      c.draft.harvestTons = 8;
      c.next();
      expect(c.step, 4);
      expect(c.draft.harvestTons, 8);
      final before = store.proposals.length;
      expect(await c.submit(), isTrue);
      expect(await c.submit(), isFalse);
      expect(store.proposals.length, before + 1);
      expect(store.proposals.first.estimatedHarvestKg, 8000);
      expect(store.proposals.first.fundingTarget!.amount, 30000000);
      c.dispose();
      store.dispose();
    },
  );
  test(
    'repository copies drafts and transitions accepted proposals to projects',
    () async {
      final store = MockFarmerStore();
      final d = store.details('proposal-0');
      d.area = 2;
      expect(store.details('proposal-0').area, 1.5);
      await store.update('proposal-0', d);
      expect(store.proposals.first.landAreaHectares, 2);
      store.transitionProposal('proposal-0', ProposalStatus.approved);
      expect(
        store.projects.where((p) => p.id == 'proposal-0').single.status,
        ProjectStatus.openForFunding,
      );
      store.transitionProposal('proposal-0', ProposalStatus.active);
      expect(store.projects.where((p) => p.id == 'proposal-0').length, 1);
      expect(
        store.projects.where((p) => p.id == 'proposal-0').single.status,
        ProjectStatus.growing,
      );
      await expectLater(store.update('proposal-0', d), throwsStateError);
      store.dispose();
    },
  );
  test('withdrawal cannot spend pending or unavailable funds', () async {
    final store = MockFarmerStore();
    await expectLater(
      store.transact(deposit: false, amount: const Money(amount: 140000000)),
      throwsStateError,
    );
    expect(store.balance.amount, 150000000);
    await store.transact(deposit: true, amount: const Money(amount: 500000));
    await store.transact(deposit: false, amount: const Money(amount: 250000));
    expect(store.balance.amount, 150250000);
    expect(store.transactions.length, 2);
    store.dispose();
  });
  testWidgets('status badge has equal insets and wraps long values safely', (
    tester,
  ) async {
    phone(tester, width: 320);
    await tester.pumpWidget(
      host(
        const Scaffold(
          body: Padding(
            padding: EdgeInsets.all(24),
            child: ProposalStatusLine(
              key: ValueKey('badge'),
              label: 'Kondisi Proposal',
              value: 'Menunggu Verifikasi',
            ),
          ),
        ),
      ),
    );
    final badge = tester.getRect(find.byKey(const ValueKey('badge')));
    final left = tester.getRect(find.text('Kondisi Proposal'));
    final right = tester.getRect(find.text('Menunggu Verifikasi'));
    expect(left.left - badge.left, 12);
    expect(badge.right - right.right, 12);
    await tester.pumpWidget(
      host(
        const Scaffold(
          body: Padding(
            padding: EdgeInsets.all(24),
            child: ProposalStatusLine(
              label: 'Kondisi Proposal',
              value: 'Menunggu Verifikasi Dokumen Kepemilikan Lahan',
            ),
          ),
        ),
        scale: 2,
      ),
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'shell shows funding, running actions and only two navigation tabs',
    (tester) async {
      phone(tester);
      final store = MockFarmerStore();
      await tester.pumpWidget(
        host(
          RepaintBoundary(
            key: const ValueKey('capture'),
            child: FarmerShell(
              repository: store,
              fundRepository: const FakeFarmerFundRepository(
                latency: Duration.zero,
              ),
              walletTopUp: const FakeWalletTopUpRepository(
                latency: Duration.zero,
              ),
              investmentRepository: FakeFarmerInvestmentRepository(
                latency: Duration.zero,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Investor Saat Ini'), findsOneWidget);
      expect(find.text('Proposal'), findsOneWidget);
      expect(find.text('Wallet'), findsNothing);
      await screenshot(tester, 'dashboard-running');
      expect(find.text('Kirim Update'), findsOneWidget);
      expect(find.text('Kirim Laporan'), findsOneWidget);
      await tester.ensureVisible(find.text('Kirim Laporan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kirim Laporan'));
      await tester.pumpAndSettle();
      expect(find.text('Judul Laporan'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'proposal filtering and accepted lifecycle refresh the same shell',
    (tester) async {
      phone(tester);
      final store = MockFarmerStore();
      await tester.pumpWidget(
        host(
          RepaintBoundary(
            key: const ValueKey('capture'),
            child: FarmerShell(
              repository: store,
              fundRepository: const FakeFarmerFundRepository(
                latency: Duration.zero,
              ),
              walletTopUp: const FakeWalletTopUpRepository(
                latency: Duration.zero,
              ),
              investmentRepository: FakeFarmerInvestmentRepository(
                latency: Duration.zero,
              ),
              initialIndex: 1,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await screenshot(tester, 'proposals');
      await tester.tap(find.text('Semua'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Perlu Perbaikan').last);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('proposal-card-proposal-0')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('proposal-card-proposal-1')),
        findsNothing,
      );
      store.transitionProposal('proposal-0', ProposalStatus.approved);
      await tester.pumpAndSettle();
      expect(find.text('Belum ada proposal untuk filter ini.'), findsOneWidget);
      await tester.tap(find.text('Beranda'));
      await tester.pumpAndSettle();
      // Dashboard projects come from the investments endpoint, not from local
      // proposal transitions.
      expect(find.text('Investor Saat Ini'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'review uses actual values, labeled missing SPPT, and section edit',
    (tester) async {
      phone(tester, height: 1800);
      final store = MockFarmerStore();
      final d = store.details('proposal-1')
        ..sppt = null
        ..spptName = null;
      await tester.pumpWidget(
        host(
          RepaintBoundary(
            key: const ValueKey('capture'),
            child: ProposalWizardPage(
              repository: store,
              initial: d,
              initialStep: 4,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Dokumen SPPT belum diunggah'), findsOneWidget);
      expect(find.text('Rp 2.500.000 / Ton'), findsOneWidget);
      expect(find.text('Agustus 2026 (4 Bulan)'), findsOneWidget);
      await screenshot(tester, 'review');
      await tester.tap(find.text('Edit').at(1));
      await tester.pumpAndSettle();
      expect(find.text('Komoditas dan Target Panen'), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('harvest')), '8');
      await tester.tap(find.text('Selanjutnya'));
      await tester.pumpAndSettle();
      expect(find.text('Review dan Kirim'), findsOneWidget);
      expect(find.text('8 Ton'), findsOneWidget);
    },
  );
  testWidgets(
    'edit saves values to shared repository without exposing capital',
    (tester) async {
      phone(tester, height: 1800);
      final store = MockFarmerStore();
      await tester.pumpWidget(
        host(ProposalEditPage(repository: store, proposalId: 'proposal-1')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Kebutuhan Modal'), findsNothing);
      await tester.tap(find.text('Edit').at(1));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const ValueKey('harvest')), '9');
      await tester.tap(find.text('Simpan Perubahan'));
      await tester.pumpAndSettle();
      expect(find.text('9 Ton'), findsOneWidget);
      await tester.tap(find.text('Simpan Perubahan'));
      await tester.pumpAndSettle();
      expect(store.details('proposal-1').harvestTons, 9);
      expect(
        store.proposals
            .where((p) => p.id == 'proposal-1')
            .single
            .estimatedHarvestKg,
        9000,
      );
    },
  );
  testWidgets(
    'report validates, removes attachments and saves to local activity store',
    (tester) async {
      phone(tester, height: 1400);
      final store = MockFarmerStore();
      final bytes = (await rootBundle.load('${FarmerDesign.asset}chili.png'))
          .buffer
          .asUint8List();
      await tester.pumpWidget(
        host(
          RepaintBoundary(
            key: const ValueKey('capture'),
            child: FarmerActivityPage(
              repository: store,
              project: store.projects.last,
              report: true,
              media: TestMedia(bytes),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Kirim'));
      await tester.pumpAndSettle();
      expect(find.text('Lengkapi judul dan dokumen laporan.'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('report-text')),
        'Laporan Penggunaan Dana',
      );
      await tester.tap(find.text('Tautkan Dokumen Laporan'));
      await tester.pumpAndSettle();
      expect(find.text('laporan.pdf'), findsOneWidget);
      await tester.tap(find.byTooltip('Hapus dokumen'));
      await tester.pumpAndSettle();
      expect(find.text('laporan.pdf'), findsNothing);
      await tester.tap(find.text('Tautkan Dokumen Laporan'));
      await tester.pumpAndSettle();
      await screenshot(tester, 'report');
      await tester.tap(find.text('Kirim'));
      await tester.pumpAndSettle();
      expect(store.activities.single.text, 'Laporan Penggunaan Dana');
      expect(store.activities.single.attachmentName, 'laporan.pdf');
      expect(find.text('Laporan tersimpan'), findsOneWidget);
    },
  );
  testWidgets(
    'confirm submits the review and returns to the updated proposal list',
    (tester) async {
      phone(tester, height: 1000);
      final store = MockFarmerStore();
      await tester.pumpWidget(
        host(
          Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: TextButton(
                  onPressed: () => Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProposalWizardPage(
                        repository: store,
                        initial: store.details('proposal-1'),
                        initialStep: 4,
                      ),
                    ),
                  ),
                  child: const Text('Open review'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open review'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Konfirmasi'));
      await tester.pumpAndSettle();
      expect(store.proposals.length, 4);
      expect(store.proposals.first.status, ProposalStatus.submitted);
      expect(find.text('Proposal Berhasil Dikirim!'), findsOneWidget);
      await tester.tap(find.text('Selesai'));
      await tester.pumpAndSettle();
      expect(find.text('Open review'), findsOneWidget);
    },
  );
  testWidgets('update retains its photo and text separately from report mode', (
    tester,
  ) async {
    phone(tester, height: 1800);
    final store = MockFarmerStore();
    final bytes = (await rootBundle.load('${FarmerDesign.asset}chili.png'))
        .buffer
        .asUint8List();
    await tester.pumpWidget(
      host(
        FarmerActivityPage(
          repository: store,
          project: store.projects.last,
          media: TestMedia(bytes),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('update-text')),
      'Bunga pertama mulai tumbuh',
    );
    await tester.tap(find.text('Ambil Foto'));
    await tester.pumpAndSettle();
    expect(find.text('Edit'), findsOneWidget);
    await tester.tap(find.text('Kirim'));
    await tester.pumpAndSettle();
    expect(store.activities.single.report, isFalse);
    expect(store.activities.single.text, 'Bunga pertama mulai tumbuh');
    expect(store.activities.single.attachmentName, 'foto.png');
    expect(find.text('Update tersimpan'), findsOneWidget);
  });
  testWidgets('Farmer route contracts open dashboard and wallet', (
    tester,
  ) async {
    phone(tester);
    FarmerRoutes.repository = MockFarmerStore();
    await tester.pumpWidget(
      MaterialApp(
        initialRoute: FarmerRoutes.home,
        onGenerateRoute: AppRouter.onGenerateRoute,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Dana Investor'), findsOneWidget);
    await tester.tap(find.text('Lihat Detail Keuangan'));
    await tester.pumpAndSettle();
    expect(find.text('Saldo Tersedia'), findsOneWidget);
    expect(find.text('Riwayat Transaksi'), findsOneWidget);
  });
  testWidgets('narrow dashboard and commodity forms support enlarged text', (
    tester,
  ) async {
    phone(tester, width: 320, height: 900);
    final store = MockFarmerStore();
    await tester.pumpWidget(
      host(
        FarmerShell(
          repository: store,
          fundRepository: const FakeFarmerFundRepository(
            latency: Duration.zero,
          ),
          walletTopUp: const FakeWalletTopUpRepository(latency: Duration.zero),
          investmentRepository: FakeFarmerInvestmentRepository(
            latency: Duration.zero,
          ),
        ),
        scale: 1.8,
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(
      host(
        ProposalWizardPage(
          repository: store,
          initial: store.details('proposal-1'),
          initialStep: 1,
        ),
        scale: 1.8,
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
