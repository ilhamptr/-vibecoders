import 'package:flutter/material.dart';

import '../../../../../app/router/investor_routes.dart';
import '../../../../../domain/domain.dart';
import '../../../common/investor_design.dart';
import '../../../common/status_view.dart';
import '../../data/portfolio_repository.dart';
import '../state/portfolio_controller.dart';
import '../widgets/investment_card.dart';

class PortfolioPage extends StatefulWidget {
  const PortfolioPage({super.key, required this.repository});

  final PortfolioRepository repository;

  @override
  State<PortfolioPage> createState() => _PortfolioPageState();
}

class _PortfolioPageState extends State<PortfolioPage> {
  late final PortfolioController controller = PortfolioController(
    widget.repository,
    initialFilter: InvestmentStatus.active,
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
          'Portofolio Investasi',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        DesignCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Dana Diinvestasikan',
                style: TextStyle(color: InvestorDesign.muted, fontSize: 12),
              ),
              const SizedBox(height: 6),
              Text(
                rupiah(controller.totalInvested.amount, prefix: false),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // Backend supports only these two statuses.
              for (final s in const <InvestmentStatus>[
                InvestmentStatus.active,
                InvestmentStatus.completed,
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(investmentStatusLabel(s)),
                    selected: controller.filter == s,
                    onSelected: (_) => controller.setFilter(s),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        StatusView(
          status: controller.status,
          onRetry: controller.load,
          emptyMessage: 'Belum ada investasi. Mulai dari Pasar.',
          builder: (context) => Column(
            children: [
              for (final investment in controller.visibleInvestments)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: InvestmentCard(
                    investment: investment,
                    onTap: () => Navigator.pushNamed(
                      context,
                      InvestorRoutes.portfolioProject(investment.id),
                    ),
                  ),
                ),
              if (controller.isFilteredEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Text('Tidak ada investasi dengan status ini.'),
                ),
            ],
          ),
        ),
      ],
    ),
  );
}
