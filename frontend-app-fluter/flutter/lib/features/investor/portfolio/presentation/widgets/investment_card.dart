import 'package:flutter/material.dart';

import '../../../../../domain/domain.dart';
import '../../../../../shared/shared.dart';
import '../../../common/investor_design.dart';
import '../../../common/project_widgets.dart';

class InvestmentCard extends StatelessWidget {
  const InvestmentCard({
    super.key,
    required this.investment,
    required this.onTap,
    this.showFunding = false,
  });

  final Investment investment;
  final VoidCallback onTap;

  /// Pre-funding view: shows time left and funding progress instead of status.
  final bool showFunding;

  @override
  Widget build(BuildContext context) {
    final project = investment.project;
    return DesignCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProjectThumbnailHeader(project: project),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppStatTile(
                  label: 'Jumlah Investasi',
                  value: rupiah(investment.principal.amount),
                  backgroundColor: InvestorDesign.cyan,
                  labelColor: InvestorDesign.blue,
                  valueColor: InvestorDesign.blue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: AppStatTile(
                  label: showFunding ? 'Sisa Waktu' : 'Panen Dalam',
                  value: showFunding
                      ? daysLeftLabel(project)
                      : '~ ${project.harvestCycleMonths} Bulan',
                  backgroundColor: InvestorDesign.yellow,
                  labelColor: const Color(0xFFD9A521),
                  valueColor: const Color(0xFFD9A521),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (showFunding)
            FundingProgress(project: project)
          else
            AppBadge(
              label: investmentStatusLabel(investment.status),
              backgroundColor: InvestorDesign.green,
              foregroundColor: const Color(0xFF4AAB45),
            ),
        ],
      ),
    );
  }
}
