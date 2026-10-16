import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framework/domain/domain.dart';
import 'package:framework/features/investor/data/mock/mock_investor_store.dart';
import 'package:framework/features/investor/marketplace/data/marketplace_repository.dart';
import 'package:framework/features/investor/marketplace/presentation/pages/marketplace_page.dart';
import 'package:framework/app/theme/app_theme.dart';
import 'package:framework/app/router/investor_routes.dart';

import 'investor_test_support.dart';

class _ThrowingMarketplaceRepository implements MarketplaceRepository {
  int calls = 0;

  @override
  Future<List<AgricultureProject>> getProjects({Commodity? commodity}) async {
    calls++;
    throw StateError('boom');
  }
}

Widget _page(MarketplaceRepository repository) => MaterialApp(
  theme: AppTheme.light,
  onGenerateRoute: InvestorRoutes.onGenerateRoute,
  home: Scaffold(body: MarketplacePage(repository: repository)),
);

void main() {
  testWidgets('renders projects from the fake repository', (tester) async {
    usePhoneSurface(tester);
    final deps = mockDependencies();
    await tester.pumpWidget(_page(deps.marketplace));
    await tester.pumpAndSettle();

    expect(find.text('Budidaya Cabai Merah'), findsOneWidget);
    expect(find.text('Budidaya Jahe'), findsOneWidget);
    // Only projects open for funding are listed in the marketplace.
    expect(find.text('Budidaya Padi'), findsNothing);
    expect(find.text('Sektor Pertanian'), findsOneWidget);
  });

  testWidgets('funding progress, ROI and duration render', (tester) async {
    usePhoneSurface(tester);
    final deps = mockDependencies();
    await tester.pumpWidget(_page(deps.marketplace));
    await tester.pumpAndSettle();

    // 6.5M of 10M from the canonical seed = 65%.
    expect(find.text('10.000.000 • 65%'), findsOneWidget);
    expect(find.text('12 Investor'), findsOneWidget);
    expect(find.text('15-20%'), findsOneWidget);
    expect(find.text('4 Bulan'), findsOneWidget);
  });

  testWidgets('sector filter narrows projects and clears again', (
    tester,
  ) async {
    usePhoneSurface(tester);
    final deps = mockDependencies();
    await tester.pumpWidget(_page(deps.marketplace));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Rempah'));
    await tester.pump();
    expect(find.text('Budidaya Jahe'), findsOneWidget);
    expect(find.text('Budidaya Cabai Merah'), findsNothing);

    await tester.tap(find.text('Padi'));
    await tester.pump();
    expect(find.text('Belum ada proyek di sektor ini.'), findsOneWidget);

    await tester.tap(find.text('Semua'));
    await tester.pump();
    expect(find.text('Budidaya Cabai Merah'), findsOneWidget);
    expect(find.text('Budidaya Jahe'), findsOneWidget);
  });

  testWidgets('empty state when no project is open for funding', (
    tester,
  ) async {
    usePhoneSurface(tester);
    final deps = mockDependencies(store: emptyStore());
    await tester.pumpWidget(_page(deps.marketplace));
    await tester.pumpAndSettle();

    expect(
      find.text('Belum ada proyek yang dibuka untuk pendanaan.'),
      findsOneWidget,
    );
  });

  testWidgets('error state offers retry', (tester) async {
    usePhoneSurface(tester);
    final repository = _ThrowingMarketplaceRepository();
    await tester.pumpWidget(_page(repository));
    await tester.pumpAndSettle();

    expect(find.text('Data belum dapat dimuat.'), findsOneWidget);
    expect(repository.calls, 1);

    await tester.tap(find.text('Coba lagi'));
    await tester.pumpAndSettle();
    expect(repository.calls, 2);
  });

  testWidgets('project card opens the detail page', (tester) async {
    usePhoneSurface(tester);
    final store = MockInvestorStore.seeded();
    InvestorRoutes.dependencies = mockDependencies(store: store);
    await tester.pumpWidget(_page(InvestorRoutes.dependencies.marketplace));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Budidaya Cabai Merah'));
    await tester.pumpAndSettle();

    expect(find.text('Dana Terkumpul'), findsOneWidget);
    expect(
      find.textContaining('6.500.000', findRichText: true),
      findsOneWidget,
    );
    expect(find.text('Jadwal Proyek'), findsOneWidget);
    expect(find.text('Investasi'), findsOneWidget);
  });
}
