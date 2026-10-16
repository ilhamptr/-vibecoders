import 'package:flutter/material.dart';

import '../../../../../domain/domain.dart';
import '../../../common/farmer_design.dart';
import '../../../data/farmer_repository.dart';

class InvestorPreviewPage extends StatelessWidget {
  const InvestorPreviewPage({super.key, this.details, this.project})
    : assert(details != null || project != null);
  final FarmerProposalDetails? details;
  final AgricultureProject? project;
  @override
  Widget build(BuildContext context) {
    final d = details;
    final p = project;
    final target = d?.total ?? p!.funding.target.amount;
    final collected = p?.funding.collected.amount ?? 0;
    final progress = target > 0 ? (collected / target).clamp(0.0, 1.0) : 0.0;
    final title =
        p?.title ??
        (d!.landName.trim().isNotEmpty
            ? d.landName.trim()
            : 'Budidaya ${d.commodity == null ? 'Komoditas' : farmerCommodity(d.commodity!)}');
    return FarmerPage(
      title: d != null ? 'Preview Investor' : null,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        children: [
          FarmHero(
            title: title,
            location: d?.address ?? p!.location.displayName,
            bytes: d?.farmPhoto,
            asset: d == null ? 'chili.png' : d.farmPhotoAsset,
          ),
          const SizedBox(height: 16),
          if (d != null) ...[
            const Text(
              'Pratinjau proposal • Statistik investor menggunakan nilai contoh (0).',
              style: TextStyle(color: FarmerDesign.muted, fontSize: 12),
            ),
            const SizedBox(height: 16),
          ],
          const Text(
            'Dana Terkumpul',
            style: TextStyle(color: FarmerDesign.muted),
          ),
          const SizedBox(height: 8),
          Text(
            '${farmerRupiah(collected)} / ${farmerRupiah(target)}',
            style: const TextStyle(fontSize: 22),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              color: FarmerDesign.blue,
              backgroundColor: FarmerDesign.line,
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text('${p?.funding.investorCount ?? 0} Investor'),
              ),
              Text('${(progress * 100).round()}%'),
            ],
          ),
          const SizedBox(height: 16),
          FarmerTint(
            color: FarmerDesign.yellow,
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Sisa Waktu',
                    style: TextStyle(color: FarmerDesign.gold),
                  ),
                ),
                Text(
                  p == null
                      ? 'Belum tayang'
                      : '${p.funding.daysRemaining} Hari',
                  style: const TextStyle(color: FarmerDesign.gold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _stat(
                'Perkiraan ROI',
                p == null
                    ? 'Belum dinilai'
                    : '${p.roiMinPercent.round()}–${p.roiMaxPercent.round()}%',
                const Color(0xFFE4FCD8),
              ),
              _stat(
                'Risiko',
                p == null ? 'Belum dinilai' : 'Sedang',
                FarmerDesign.yellow,
              ),
              _stat('Panen Setiap', '4 Bulan', FarmerDesign.cyan),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Rincian Penggunaan Dana',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          for (final e
              in (d?.budget ??
                      {
                        'Bibit & Persemaian': target * 30 ~/ 100,
                        'Pupuk & Pestisida': target * 25 ~/ 100,
                        'Irigasi & Infrastruktur': target * 20 ~/ 100,
                        'Tenaga Kerja': target * 25 ~/ 100,
                      })
                  .entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: FarmerCard(
                radius: 14,
                child: Row(
                  children: [
                    Expanded(child: Text(e.key)),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        farmerRupiah(e.value),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (d != null) ...[
            const SizedBox(height: 16),
            FarmerInfo(
              label: 'Luas Lahan',
              value: '${farmerNumber(d.area)} Hektar',
            ),
            FarmerInfo(
              label: 'Estimasi Hasil Panen',
              value: '${farmerNumber(d.harvestTons)} Ton',
            ),
            FarmerInfo(
              label: 'Target Panen',
              value: farmerMonth(d.harvestMonth),
            ),
            FarmerInfo(label: 'Risiko Lahan', value: d.risks.join(', ')),
          ],
        ],
      ),
    );
  }

  Widget _stat(String label, String value, Color color) => ConstrainedBox(
    constraints: const BoxConstraints(minWidth: 140),
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          const SizedBox(height: 4),
          Text(value),
        ],
      ),
    ),
  );
}
