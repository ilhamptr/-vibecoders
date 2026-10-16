import 'package:flutter/material.dart';

import '../../../../../app/router/investor_routes.dart';
import '../../../../../domain/domain.dart';
import '../../../common/status_view.dart';
import '../../data/marketplace_repository.dart';
import '../state/marketplace_controller.dart';
import '../widgets/project_summary_card.dart';
import '../widgets/sector_card.dart';

class MarketplacePage extends StatefulWidget {
  const MarketplacePage({super.key, required this.repository});

  final MarketplaceRepository repository;

  @override
  State<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends State<MarketplacePage> {
  late final MarketplaceController controller = MarketplaceController(
    widget.repository,
  )..load();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => ListView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      children: [
        const Text(
          'Sektor Pertanian',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, box) {
            final columns =
                box.maxWidth < 320 ||
                    MediaQuery.textScalerOf(context).scale(14) > 18
                ? 2
                : 3;
            final width = (box.maxWidth - 8.0 * (columns - 1)) / columns;
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in Commodity.values.where(
                  (c) => c != Commodity.other,
                ))
                  SizedBox(
                    width: width,
                    child: SectorCard(
                      commodity: c,
                      selected: controller.selectedCommodity == c,
                      onTap: () => controller.selectCommodity(c),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Sedang Ramai',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            if (controller.selectedCommodity != null)
              TextButton(
                onPressed: controller.clearCommodity,
                child: const Text('Semua'),
              ),
          ],
        ),
        const SizedBox(height: 14),
        StatusView(
          status: controller.status,
          onRetry: controller.load,
          emptyMessage: 'Belum ada proyek yang dibuka untuk pendanaan.',
          builder: (context) => Column(
            children: [
              for (final project in controller.visibleProjects)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ProjectSummaryCard(
                    project: project,
                    onTap: () => Navigator.pushNamed(
                      context,
                      InvestorRoutes.projectDetail(project.id),
                    ),
                  ),
                ),
              if (controller.isFilteredEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Text('Belum ada proyek di sektor ini.'),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}
