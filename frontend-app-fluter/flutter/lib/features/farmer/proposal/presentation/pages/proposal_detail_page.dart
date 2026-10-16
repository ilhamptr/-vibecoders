import 'package:flutter/material.dart';

import '../../../common/farmer_design.dart';
import '../../../data/farmer_repository.dart';
import 'proposal_list_page.dart';
import 'proposal_edit_page.dart';

class ProposalDetailPage extends StatelessWidget {
  const ProposalDetailPage({
    super.key,
    required this.repository,
    required this.proposalId,
  });
  final FarmerRepository repository;
  final String proposalId;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: repository,
    builder: (context, _) {
      final matches = repository.proposals.where((p) => p.id == proposalId);
      if (matches.isEmpty) {
        return const FarmerPage(
          child: Center(child: Text('Proposal tidak ditemukan.')),
        );
      }
      final p = matches.first;
      if (!FarmerStates.review.contains(p.status)) {
        return const FarmerPage(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Proposal telah disetujui. Pantau proyek melalui Beranda.',
              ),
            ),
          ),
        );
      }
      final correction = repository.needsCorrection(p.id);
      return FarmerPage(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          children: [
            FarmHero(
              title: p.projectName,
              location: p.location.displayName,
              bytes: repository.details(p.id).farmPhoto,
              asset: repository.details(p.id).farmPhotoAsset,
            ),
            const SizedBox(height: 16),
            FarmerButton(
              label: 'Edit Proposal',
              icon: Icons.edit_outlined,
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => ProposalEditPage(
                    repository: repository,
                    proposalId: proposalId,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            FarmerCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Status Proposal',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  ProposalStatusLine(
                    label: 'Kondisi Proposal',
                    value: proposalStatusLabel(repository, p),
                    correction: correction,
                  ),
                  const SizedBox(height: 12),
                  if (correction)
                    const FarmerTint(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Keterangan',
                            style: TextStyle(
                              color: FarmerDesign.blueInk,
                              fontSize: 12,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Foto lahan kurang jelas. Mohon upload ulang',
                            style: TextStyle(color: FarmerDesign.blueInk),
                          ),
                        ],
                      ),
                    )
                  else
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: FarmerDesign.muted,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Proses dapat sewaktu-waktu selesai lebih cepat',
                            style: TextStyle(
                              color: FarmerDesign.muted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FarmerCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Jadwal Proposal',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  _timeline(
                    farmerDate(p.submittedAt ?? DateTime(2026, 10, 1)),
                    'Dokumen Diterima',
                    const Color(0xFFF2F2F2),
                    FarmerDesign.muted,
                  ),
                  const SizedBox(height: 8),
                  _timeline(
                    '${farmerDate(p.submittedAt ?? DateTime(2026, 10, 1))} • Sedang berjalan',
                    'Pemeriksaan Dokumen',
                    FarmerDesign.cyan,
                    FarmerDesign.blueInk,
                  ),
                  const SizedBox(height: 8),
                  _timeline(
                    farmerDate(p.estimatedApprovalAt ?? DateTime(2026, 10, 7)),
                    'Disetujui dan Tayang di Pasar',
                    Colors.white,
                    FarmerDesign.blueInk,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
  Widget _timeline(String date, String label, Color background, Color color) =>
      FarmerTint(
        color: background,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(date, style: TextStyle(color: color, fontSize: 12)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color)),
          ],
        ),
      );
}
