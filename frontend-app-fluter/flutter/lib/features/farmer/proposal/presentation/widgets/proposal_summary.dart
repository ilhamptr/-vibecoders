import 'package:flutter/material.dart';

import '../../../common/farmer_design.dart';
import '../../../data/farmer_repository.dart';

class ProposalSummary extends StatelessWidget {
  const ProposalSummary({
    super.key,
    required this.details,
    required this.onEdit,
    this.editOnly = false,
  });
  final FarmerProposalDetails details;
  final ValueChanged<int> onEdit;
  final bool editOnly;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      _section(context, 'Profil Lahan', 0, [
        FarmerInfo(
          label: 'Nama Lahan',
          value: details.landName.trim().isEmpty ? '-' : details.landName,
        ),
        FarmerInfo(
          label: 'Alamat Lengkap',
          value: details.address.trim().isEmpty ? '-' : details.address,
        ),
        if (details.landDescription.trim().isNotEmpty)
          FarmerInfo(label: 'Deskripsi Lahan', value: details.landDescription),
        FarmerInfo(
          label: 'Luas Lahan',
          value: '${farmerNumber(details.area)} Hektar',
        ),
        const Text('Foto Lahan', style: TextStyle(color: FarmerDesign.muted)),
        const SizedBox(height: 8),
        if (details.farmPhoto == null && details.farmPhotoAsset == null)
          const FarmerTint(
            color: Color(0xFFF4F8F9),
            child: Text('Foto lahan belum diunggah'),
          )
        else
          FarmPhoto(
            bytes: details.farmPhoto,
            asset: details.farmPhotoAsset ?? 'chili.png',
          ),
        const SizedBox(height: 16),
        const Text(
          'Surat Kepemilikan (SPPT)',
          style: TextStyle(color: FarmerDesign.muted),
        ),
        const SizedBox(height: 8),
        if (details.sppt == null)
          const FarmerTint(
            color: Color(0xFFF4F8F9),
            child: Text('Dokumen SPPT belum diunggah'),
          )
        else
          FarmerTint(
            color: const Color(0xFFF4F8F9),
            child: Row(
              children: [
                const Icon(Icons.description_outlined),
                const SizedBox(width: 8),
                Expanded(child: Text(details.spptName ?? 'Dokumen SPPT')),
              ],
            ),
          ),
      ]),
      _section(context, 'Rencana Komoditas', 1, [
        FarmerInfo(
          label: 'Komoditas',
          value: details.commodity == null
              ? 'Belum dipilih'
              : farmerCommodity(details.commodity!),
        ),
        FarmerInfo(
          label: 'Estimasi Hasil Panen',
          value: '${farmerNumber(details.harvestTons)} Ton',
        ),
        FarmerInfo(
          label: 'Estimasi Penjualan Panen',
          value: '${farmerRupiah(details.salePrice)} / Ton',
        ),
        FarmerInfo(
          label: 'Estimasi Waktu Panen',
          value: '${farmerMonth(details.harvestMonth)} (4 Bulan)',
        ),
        if (details.description.trim().isNotEmpty)
          FarmerInfo(label: 'Deskripsi Proposal', value: details.description),
      ]),
      if (!editOnly) ...[
        _section(context, 'Kebutuhan Modal', 2, [
          for (final entry in details.budget.entries)
            FarmerInfo(label: entry.key, value: farmerRupiah(entry.value)),
          if (details.otherCostAmount > 0)
            FarmerInfo(
              label: 'Deskripsi Biaya Lainnya',
              value: details.otherCostDescription,
            ),
          FarmerInfo(label: 'Total', value: farmerRupiah(details.total)),
        ]),
        _section(context, 'Identifikasi Risiko', 3, [
          FarmerInfo(label: 'Risiko Lahan', value: details.risks.join(', ')),
        ]),
      ],
    ],
  );
  Widget _section(
    BuildContext context,
    String title,
    int step,
    List<Widget> children,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: FarmerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          ...children,
          const SizedBox(height: 12),
          FarmerButton(
            label: 'Edit',
            icon: Icons.edit_outlined,
            onPressed: () => onEdit(step),
          ),
        ],
      ),
    ),
  );
}
