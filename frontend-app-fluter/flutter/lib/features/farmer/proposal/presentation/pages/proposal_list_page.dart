import 'package:flutter/material.dart';

import '../../../../../domain/domain.dart';
import '../../../common/farmer_design.dart';
import '../../../data/farmer_repository.dart';
import 'proposal_detail_page.dart';

class ProposalListPage extends StatefulWidget {
  const ProposalListPage({super.key, required this.repository});
  final FarmerRepository repository;
  @override
  State<ProposalListPage> createState() => _ProposalListPageState();
}

class _ProposalListPageState extends State<ProposalListPage> {
  String filter = 'Semua';
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.repository,
    builder: (context, _) {
      final repo = widget.repository;
      final review = repo.proposals
          .where((p) => FarmerStates.review.contains(p.status))
          .toList();
      final correctionCount = review
          .where(
            (p) =>
                repo.needsCorrection(p.id) ||
                p.status == ProposalStatus.rejected,
          )
          .length;
      final pendingCount = review
          .where(
            (p) =>
                p.status != ProposalStatus.draft &&
                !repo.needsCorrection(p.id) &&
                p.status != ProposalStatus.rejected,
          )
          .length;
      final visible = review
          .where(
            (p) => switch (filter) {
              'Perlu Perbaikan' =>
                repo.needsCorrection(p.id) ||
                    p.status == ProposalStatus.rejected,
              'Menunggu Verifikasi' =>
                !repo.needsCorrection(p.id) &&
                    p.status != ProposalStatus.draft &&
                    p.status != ProposalStatus.rejected,
              'Draft' =>
                p.status == ProposalStatus.draft && !repo.needsCorrection(p.id),
              _ => true,
            },
          )
          .toList();
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          FarmerCard(
            child: Row(
              children: [
                _Count(
                  label: 'Dalam Peninjauan',
                  count: pendingCount,
                  color: FarmerDesign.cyan,
                  ink: FarmerDesign.blueInk,
                ),
                const SizedBox(width: 8),
                _Count(
                  label: 'Belum Selesai',
                  count: review
                      .where((p) => p.status == ProposalStatus.draft)
                      .length,
                  color: FarmerDesign.yellow,
                  ink: FarmerDesign.gold,
                ),
                const SizedBox(width: 8),
                _Count(
                  label: 'Bermasalah',
                  count: correctionCount,
                  color: FarmerDesign.pink,
                  ink: FarmerDesign.red,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: filter,
            decoration: const InputDecoration(),
            isExpanded: true,
            items: ['Semua', 'Menunggu Verifikasi', 'Perlu Perbaikan', 'Draft']
                .map(
                  (s) => DropdownMenuItem(
                    value: s,
                    child: Center(child: Text(s)),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => filter = value!),
          ),
          const SizedBox(height: 12),
          if (visible.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Belum ada proposal untuk filter ini.',
                textAlign: TextAlign.center,
              ),
            ),
          for (final p in visible)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: FarmerCard(
                key: ValueKey('proposal-card-${p.id}'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        ProposalDetailPage(repository: repo, proposalId: p.id),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FarmPhoto(
                      bytes: repo.details(p.id).farmPhoto,
                      asset: repo.details(p.id).farmPhotoAsset,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      p.projectName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    ProposalStatusLine(
                      label: 'Kondisi Proposal',
                      value: proposalStatusLabel(repo, p),
                      correction:
                          repo.needsCorrection(p.id) ||
                          p.status == ProposalStatus.rejected,
                    ),
                    const SizedBox(height: 12),
                    FarmerTint(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            repo.needsCorrection(p.id)
                                ? 'Keterangan'
                                : farmerDate(
                                    p.submittedAt ?? DateTime(2026, 10, 1),
                                  ),
                            style: const TextStyle(
                              color: FarmerDesign.blueInk,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            repo.needsCorrection(p.id)
                                ? 'Foto lahan kurang jelas. Mohon upload ulang'
                                : p.status == ProposalStatus.draft
                                ? 'Lengkapi proposal Anda'
                                : 'Pemeriksaan Dokumen',
                            style: const TextStyle(color: FarmerDesign.blueInk),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    },
  );
}

class _Count extends StatelessWidget {
  const _Count({
    required this.label,
    required this.count,
    required this.color,
    required this.ink,
  });
  final String label;
  final int count;
  final Color color;
  final Color ink;
  @override
  Widget build(BuildContext context) => Expanded(
    child: FarmerTint(
      color: color,
      child: Column(
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: ink),
          ),
          const SizedBox(height: 4),
          Text('$count', style: TextStyle(fontSize: 22, color: ink)),
        ],
      ),
    ),
  );
}

String proposalStatusLabel(FarmerRepository repo, Proposal p) =>
    repo.needsCorrection(p.id) || p.status == ProposalStatus.rejected
    ? 'Perlu Perbaikan'
    : p.status == ProposalStatus.draft
    ? 'Draft'
    : 'Menunggu Verifikasi';

/// Equal flexible alignment regions anchor both texts to the same 12 dp inset.
/// Labels can wrap independently without squeezing or clipping the value.
class ProposalStatusLine extends StatelessWidget {
  const ProposalStatusLine({
    super.key,
    required this.label,
    required this.value,
    this.correction = false,
  });
  final String label;
  final String value;
  final bool correction;
  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minHeight: 36),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: correction ? FarmerDesign.pink : FarmerDesign.yellow,
      borderRadius: BorderRadius.circular(13),
    ),
    child: DefaultTextStyle.merge(
      style: TextStyle(
        color: correction ? FarmerDesign.red : FarmerDesign.gold,
        fontSize: 13,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 8),
          Expanded(child: Text(value, textAlign: TextAlign.end)),
        ],
      ),
    ),
  );
}
