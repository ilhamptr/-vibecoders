import 'package:flutter/material.dart';

import '../../../shared/shared.dart';
import '../../../domain/domain.dart';

/// Colors sampled from the supplied PDF, scoped to Frontend B presentation.
abstract final class InvestorDesign {
  static const background = Color(0xFFFBFFFF);
  static const ink = Color(0xFF1C1D21);
  static const muted = Color(0xFF959698);
  static const blue = Color(0xFF3FA7D6);
  static const cyan = Color(0xFFC8F7FF);
  static const green = Color(0xFFE4FCD8);
  static const yellow = Color(0xFFFFF7D0);
  static const line = Color(0xFFF0F0F0);
  static const asset = 'assets/investor/design/';
  static ThemeData theme(BuildContext context) {
    final base = Theme.of(context);
    return base.copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: base.colorScheme.copyWith(
        primary: blue,
        onPrimary: Colors.white,
        surface: Colors.white,
        onSurface: ink,
      ),
      dividerColor: line,
      textTheme: base.textTheme
          .copyWith(
            headlineSmall: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: ink,
            ),
            titleLarge: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: ink,
            ),
            titleMedium: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: ink,
            ),
            bodyLarge: const TextStyle(fontSize: 15, color: ink),
            bodyMedium: const TextStyle(fontSize: 13, color: ink),
            bodySmall: const TextStyle(fontSize: 10, color: muted),
            labelLarge: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          )
          .apply(fontFamily: 'Roboto'),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        hintStyle: const TextStyle(color: muted, fontSize: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: blue),
        ),
      ),
    );
  }
}

class InvestorPresentation extends StatelessWidget {
  const InvestorPresentation({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) =>
      Theme(data: InvestorDesign.theme(context), child: child);
}

class DesignButton extends StatelessWidget {
  const DesignButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: onPressed == null
            ? [
                InvestorDesign.blue.withValues(alpha: .4),
                InvestorDesign.blue.withValues(alpha: .4),
              ]
            : [const Color(0xFF43ADD6), const Color(0xFF2E87BC)],
      ),
    ),
    child: AppButton(
      label: label,
      onPressed: onPressed,
      isLoading: loading,
      height: 44,
      borderRadius: 10,
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
    ),
  );
}

class DesignCard extends StatelessWidget {
  const DesignCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.onTap,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(22),
      boxShadow: const [
        BoxShadow(
          color: Color(0x05000000),
          blurRadius: 3,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: AppCard(
      borderRadius: 22,
      borderColor: InvestorDesign.line,
      padding: padding,
      onTap: onTap,
      child: child,
    ),
  );
}

String commodityLabel(Commodity c) => switch (c) {
  Commodity.rice => 'Padi',
  Commodity.vegetables => 'Sayuran',
  Commodity.spices => 'Rempah',
  Commodity.fruits => 'Buah',
  Commodity.secondaryCrops => 'Palawija',
  Commodity.plantation => 'Perkebunan',
  Commodity.other => 'Lainnya',
};
String investmentStatusLabel(InvestmentStatus s) => switch (s) {
  InvestmentStatus.active => 'Berjalan',
  InvestmentStatus.pending => 'Tertunda',
  InvestmentStatus.completed => 'Selesai',
  InvestmentStatus.confirmed => 'Dikonfirmasi',
  InvestmentStatus.returnPending => 'Menunggu hasil',
  InvestmentStatus.cancelled => 'Dibatalkan',
};
String riskLabel(ProjectRiskLevel? r) => switch (r) {
  ProjectRiskLevel.low => 'Rendah',
  ProjectRiskLevel.medium => 'Sedang',
  ProjectRiskLevel.high => 'Tinggi',
  null => 'Belum dinilai',
};
String rupiah(int amount, {bool prefix = true}) =>
    '${prefix ? 'Rp' : ''}${amount.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
String daysLeftLabel(AgricultureProject project) {
  final days = project.funding.daysRemaining;
  return days == null ? '-' : '$days Hari';
}

class ProjectHero extends StatelessWidget {
  const ProjectHero({super.key, required this.project, this.height = 256});
  final AgricultureProject project;
  final double height;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(22),
    child: SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (project.imageUrl != null && project.imageUrl!.trim().isNotEmpty)
            Image.network(
              project.imageUrl!.trim(),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Image.asset('${InvestorDesign.asset}chili.png',
                      fit: BoxFit.cover),
            )
          else
            Image.asset('${InvestorDesign.asset}chili.png', fit: BoxFit.cover),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.center,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xDD000000)],
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 16,
            bottom: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  project.location.displayName,
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class ProjectStats extends StatelessWidget {
  const ProjectStats({super.key, required this.project, this.showRisk = true});
  final AgricultureProject project;
  final bool showRisk;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: AppStatTile(
          label: 'Perkiraan ROI',
          value:
              '${project.roiMinPercent.round()}-${project.roiMaxPercent.round()}%',
          backgroundColor: InvestorDesign.green,
          labelColor: const Color(0xFF4AAB45),
          valueColor: const Color(0xFF4AAB45),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: AppStatTile(
          label: showRisk ? 'Risiko' : 'Panen Setiap',
          value: showRisk
              ? riskLabel(project.riskLevel)
              : '${project.harvestCycleMonths} Bulan',
          backgroundColor: showRisk
              ? InvestorDesign.yellow
              : InvestorDesign.cyan,
          labelColor: showRisk ? const Color(0xFFD9A521) : InvestorDesign.blue,
          valueColor: showRisk ? const Color(0xFFD9A521) : InvestorDesign.blue,
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: AppStatTile(
          label: showRisk ? 'Panen Setiap' : 'Sisa Waktu',
          value: showRisk
              ? '${project.harvestCycleMonths} Bulan'
              : daysLeftLabel(project),
          backgroundColor: showRisk
              ? InvestorDesign.cyan
              : InvestorDesign.yellow,
          labelColor: showRisk ? InvestorDesign.blue : const Color(0xFFD9A521),
          valueColor: showRisk ? InvestorDesign.blue : const Color(0xFFD9A521),
        ),
      ),
    ],
  );
}

class FundingProgress extends StatelessWidget {
  const FundingProgress({super.key, required this.project});
  final AgricultureProject project;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      AppProgressBar(
        value: project.funding.progress,
        height: 4,
        foregroundColor: InvestorDesign.blue,
        backgroundColor: InvestorDesign.line,
      ),
      const SizedBox(height: 8),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              '${project.funding.investorCount} Investor',
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '${rupiah(project.funding.target.amount, prefix: false)} • ${project.funding.percentage.round()}%',
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    ],
  );
}
