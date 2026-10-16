import 'package:flutter/material.dart';

import '../../../common/farmer_design.dart';
import '../../../data/farmer_repository.dart';
import '../widgets/proposal_summary.dart';
import 'proposal_wizard_page.dart';

class ProposalEditPage extends StatefulWidget {
  const ProposalEditPage({
    super.key,
    required this.repository,
    required this.proposalId,
  });
  final FarmerRepository repository;
  final String proposalId;
  @override
  State<ProposalEditPage> createState() => _ProposalEditPageState();
}

class _ProposalEditPageState extends State<ProposalEditPage> {
  late FarmerProposalDetails details = widget.repository.details(
    widget.proposalId,
  );
  bool busy = false;
  String? error;
  Future<void> _edit(int step) async {
    final result = await Navigator.push<FarmerProposalDetails>(
      context,
      MaterialPageRoute(
        builder: (_) => ProposalWizardPage(
          repository: widget.repository,
          initial: details,
          initialStep: step,
          sectionOnly: true,
        ),
      ),
    );
    if (result != null && mounted) setState(() => details = result);
  }

  Future<void> _save() async {
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.repository.update(widget.proposalId, details);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Proposal berhasil diperbarui.')),
      );
      Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(
          () => error = 'Perubahan belum dapat disimpan. Silakan coba lagi.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => FarmerPage(
    title: 'Edit Proposal',
    bottom: FarmerActions(
      label: 'Simpan Perubahan',
      onPressed: busy ? null : _save,
      loading: busy,
    ),
    child: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (error != null)
          Text(error!, style: const TextStyle(color: FarmerDesign.red)),
        ProposalSummary(details: details, onEdit: _edit, editOnly: true),
      ],
    ),
  );
}
