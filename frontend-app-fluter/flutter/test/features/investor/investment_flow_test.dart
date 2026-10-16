import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framework/app/app.dart';
import 'package:framework/app/router/investor_routes.dart';
import 'package:framework/domain/domain.dart';
import 'package:framework/features/investor/common/investment_math.dart';
import 'package:framework/features/investor/data/mock/mock_investor_data.dart';
import 'package:framework/features/investor/data/mock/mock_investor_store.dart';
import 'package:framework/features/investor/investment/presentation/state/investment_flow_controller.dart';
import 'package:framework/features/investor/investor_dependencies.dart';

import 'investor_test_support.dart';

void main() {
  group('amount validation', () {
    final project = MockInvestorStore.seeded().findProjectById(
      'project-cabai',
    )!;

    test('rejects empty, non-numeric and below-minimum amounts', () {
      for (final text in ['', 'abc', '0', '99999']) {
        expect(
          InvestmentAmountValidator.validate(text, project),
          'Masukkan nominal bulat minimal Rp100.000.',
          reason: 'input "$text"',
        );
      }
    });

    test('rejects amounts above the remaining funding', () {
      // Target 10M, collected 6.5M -> 3.5M remaining.
      expect(InvestmentAmountValidator.remaining(project), 3000000);
      expect(
        InvestmentAmountValidator.validate('3500001', project),
        'Nominal melebihi sisa pendanaan proyek.',
      );
    });

    test('accepts the minimum and the exact remaining amount', () {
      expect(InvestmentAmountValidator.validate('100000', project), isNull);
      expect(InvestmentAmountValidator.validate('3500000', project), isNull);
    });

    test('rejects a project that is not open for funding', () {
      final growing = MockInvestorStore.seeded().findProjectById(
        'project-padi',
      )!;
      expect(InvestmentAmountValidator.validate('100000', growing), isNotNull);
    });
  });

  group('InvestmentFlowController with one shared store', () {
    test('creates an Investment visible to Portfolio and Monitoring', () async {
      final store = MockInvestorStore.seeded();
      final deps = mockDependencies(store: store);
      final controller = InvestmentFlowController(
        projectRepository: deps.projectDetail,
        investmentRepository: deps.investment,
        investor: deps.investor,
        projectId: 'project-cabai',
      );
      addTearDown(controller.dispose);

      await controller.load();
      expect(controller.project?.id, 'project-cabai');

      controller.setAmountText('50');
      expect(controller.continueToReview(), isFalse);
      expect(controller.amountError, isNotNull);
      expect(controller.step, InvestmentStep.entry);

      controller.setAmountText('250000');
      expect(controller.amountError, isNull);
      expect(controller.continueToReview(), isTrue);
      expect(controller.step, InvestmentStep.review);

      final before = store.investments.length;
      await controller.confirm();

      expect(controller.step, InvestmentStep.success);
      final created = controller.createdInvestment!;
      expect(created.principal, const Money(amount: 250000));
      expect(created.project.id, 'project-cabai');
      expect(created.investor.id, MockInvestorData.investor.id);
      expect(store.investments.length, before + 1);

      // Same store instance: Portfolio and Monitoring see the same record.
      final portfolio = await deps.portfolio.getInvestments();
      expect(portfolio.map((i) => i.id), contains(created.id));
      final monitoring = await deps.monitoring.getMonitoring(created.id);
      expect(monitoring?.investment.id, created.id);
    });

    test('review can go back to entry', () async {
      final deps = mockDependencies();
      final controller = InvestmentFlowController(
        projectRepository: deps.projectDetail,
        investmentRepository: deps.investment,
        investor: deps.investor,
        projectId: 'project-cabai',
      );
      addTearDown(controller.dispose);
      await controller.load();
      controller.setAmountText('100000');
      controller.continueToReview();
      controller.backToEntry();
      expect(controller.step, InvestmentStep.entry);
    });

    test('unknown project is the empty state', () async {
      final deps = mockDependencies();
      final controller = InvestmentFlowController(
        projectRepository: deps.projectDetail,
        investmentRepository: deps.investment,
        investor: deps.investor,
        projectId: 'missing',
      );
      addTearDown(controller.dispose);
      await controller.load();
      expect(controller.project, isNull);
      expect(controller.continueToReview(), isFalse);
    });
  });

  testWidgets(
    'acceptance flow: role → marketplace → detail → invest → portfolio → monitoring',
    (tester) async {
      usePhoneSurface(tester);
      InvestorRoutes.dependencies = mockDependencies();
      await tester.pumpWidget(const App());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Investor'));
      await tester.pump();
      await tester.tap(find.text('Selanjutnya'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Pasar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Budidaya Cabai Merah'));
      await tester.pumpAndSettle();
      expect(find.text('Dana Terkumpul'), findsOneWidget);

      await tester.tap(find.text('Investasi'));
      await tester.pumpAndSettle();

      // Empty amount, then over capacity, then valid.
      await tester.tap(find.text('Investasi'));
      await tester.pump();
      expect(
        find.text('Masukkan nominal bulat minimal Rp100.000.'),
        findsOneWidget,
      );
      await tester.enterText(find.byType(TextField), '999999999');
      await tester.tap(find.text('Investasi'));
      await tester.pump();
      expect(
        find.text('Nominal melebihi sisa pendanaan proyek.'),
        findsOneWidget,
      );

      await tester.enterText(find.byType(TextField), '123000');
      await tester.tap(find.text('Investasi'));
      await tester.pumpAndSettle();
      expect(find.text('Detail Investasi'), findsOneWidget);

      await tester.tap(find.text('Konfirmasi'));
      await tester.pumpAndSettle();
      expect(find.text('Investasi Lahan Berhasil'), findsOneWidget);

      await tester.tap(find.text('Selesai'));
      await tester.pumpAndSettle();

      // Portfolio now lists the seeded investment AND the new one.
      expect(find.text('Rp1.000.000'), findsOneWidget);
      expect(find.text('Rp123.000'), findsOneWidget);

      await tester.tap(find.text('Rp123.000'));
      await tester.pumpAndSettle();
      expect(find.text('Informasi Investasi'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Jadwal Proyek'),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Persiapan lahan'), findsWidgets);
      expect(find.text('Penanaman'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  test('the shared store is one instance across the dependencies', () async {
    final store = MockInvestorStore.seeded();
    final InvestorDependencies deps = mockDependencies(store: store);
    final created = await deps.investment.createInvestment(
      investor: deps.investor,
      projectId: 'project-jahe',
      amount: const Money(amount: 200000),
    );
    expect(
      (await deps.portfolio.getInvestmentById(created.id))?.id,
      created.id,
    );
  });
}
