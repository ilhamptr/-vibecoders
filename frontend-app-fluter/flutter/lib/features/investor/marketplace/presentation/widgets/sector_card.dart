import 'package:flutter/material.dart';

import '../../../../../domain/domain.dart';
import '../../../../../shared/shared.dart';
import '../../../common/investor_design.dart';

/// Sector discovery tile. Pure presentation: filtering lives in the controller.
class SectorCard extends StatelessWidget {
  const SectorCard({
    super.key,
    required this.commodity,
    required this.selected,
    required this.onTap,
  });

  final Commodity commodity;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    child: AppCard(
      onTap: onTap,
      borderRadius: 16,
      borderColor: selected ? InvestorDesign.blue : InvestorDesign.line,
      backgroundColor: selected
          ? InvestorDesign.cyan.withValues(alpha: .35)
          : Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Column(
        children: [
          Image.asset(
            '${InvestorDesign.asset}${commodity.name}.png',
            height: 24,
            width: 24,
          ),
          const SizedBox(height: 6),
          Text(
            commodityLabel(commodity),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    ),
  );
}
