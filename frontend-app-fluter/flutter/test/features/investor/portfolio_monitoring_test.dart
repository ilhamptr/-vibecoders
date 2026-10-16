import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framework/domain/domain.dart';
import 'package:framework/features/investor/common/project_timeline.dart';

import 'package:framework/features/investor/data/mock/mock_investor_store.dart';
import 'package:framework/app/router/investor_routes.dart';

import 'investor_test_support.dart';

void main() {
  testWidgets('Portfolio lists seeded investments and opens Monitoring', (
    tester,
  ) async {
    usePhoneSurface(tester);
    await tester.pumpWidget(
      routedApp(mockDependencies(), initialRoute: InvestorRoutes.portfolio),
    );
    await tester.pumpAndSettle();

    expect(find.text('Portofolio Investasi'), findsOneWidget);
    expect(find.text('Budidaya Padi'), findsOneWidget);
    expect(find.text('Rp1.000.000'), findsOneWidget);

    await tester.tap(find.text('Budidaya Padi'));
    await tester.pumpAndSettle();

    expect(find.text('Informasi Investasi'), findsOneWidget);
    // The timeline and simulated updates were removed; the farmer-update
    // section is now a placeholder pending its endpoint.
    await tester.scrollUntilVisible(
      find.text('Update dari Sari Wulandari'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(
      find.text('Belum ada pembaruan dari petani.'),
      findsOneWidget,
    );
    expect(find.text('Jadwal Proyek'), findsNothing);
  });

  testWidgets('Portfolio status filter and its empty result', (tester) async {
    usePhoneSurface(tester);
    await tester.pumpWidget(
      routedApp(mockDependencies(), initialRoute: InvestorRoutes.portfolio),
    );
    await tester.pumpAndSettle();

    // Default filter is "Berjalan": the seeded active investment is listed.
    expect(find.text('Budidaya Padi'), findsOneWidget);

    // "Selesai" has no seeded investment -> empty state.
    await tester.tap(find.widgetWithText(ChoiceChip, 'Selesai'));
    await tester.pumpAndSettle();
    expect(find.text('Budidaya Padi'), findsNothing);
    expect(find.text('Tidak ada investasi dengan status ini.'), findsOneWidget);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Berjalan'));
    await tester.pumpAndSettle();
    expect(find.text('Budidaya Padi'), findsOneWidget);
  });

  testWidgets('Portfolio empty state when there are no investments', (
    tester,
  ) async {
    usePhoneSurface(tester);
    await tester.pumpWidget(
      routedApp(
        mockDependencies(store: emptyStore()),
        initialRoute: InvestorRoutes.portfolio,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Belum ada investasi. Mulai dari Pasar.'), findsOneWidget);
  });

  testWidgets('Monitoring for an unknown investment shows the empty state', (
    tester,
  ) async {
    usePhoneSurface(tester);
    await tester.pumpWidget(
      routedApp(
        mockDependencies(),
        initialRoute: InvestorRoutes.portfolioProject('does-not-exist'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Investasi tidak ditemukan.'), findsOneWidget);
  });

  group('project timeline projection', () {
    test('open-for-funding project waits for funding at the first stage', () {
      final steps = buildProjectTimeline(ProjectStatus.openForFunding);
      expect(steps.first.isCurrent, isTrue);
      expect(steps.first.description, 'Menunggu pendanaan terpenuhi');
      expect(
        steps.skip(1).every((s) => s.status == TimelineStatus.upcoming),
        isTrue,
      );
    });

    test('growing marks earlier stages complete', () {
      final steps = buildProjectTimeline(ProjectStatus.growing);
      expect(steps.map((s) => s.status), [
        TimelineStatus.completed,
        TimelineStatus.completed,
        TimelineStatus.current,
        TimelineStatus.upcoming,
      ]);
    });

    test('completed marks every stage complete', () {
      final steps = buildProjectTimeline(ProjectStatus.completed);
      expect(steps.every((s) => s.isCompleted), isTrue);
    });
  });

  test('seeded store keeps the canonical investment on a growing project', () {
    final store = MockInvestorStore.seeded();
    expect(store.investments.single.project.status, ProjectStatus.growing);
  });
}
