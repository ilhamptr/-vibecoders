import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../domain/domain.dart';
import '../common/farmer_design.dart';
import '../common/farmer_media_service.dart';
import '../data/farmer_repository.dart';

class FarmerActivityPage extends StatefulWidget {
  const FarmerActivityPage({
    super.key,
    required this.repository,
    required this.project,
    this.report = false,
    this.media,
  });
  final FarmerRepository repository;
  final AgricultureProject project;
  final bool report;
  final FarmerMediaService? media;
  @override
  State<FarmerActivityPage> createState() => _FarmerActivityPageState();
}

class _FarmerActivityPageState extends State<FarmerActivityPage> {
  late bool report = widget.report;
  final updateText = TextEditingController();
  final reportText = TextEditingController();
  late String stage = widget.repository.progress(widget.project.id).stage;
  FarmerAttachment? photo;
  FarmerAttachment? document;
  bool busy = false;
  bool picking = false;
  String? error;
  late final media = widget.media ?? FarmerMediaService();
  @override
  void dispose() {
    updateText.dispose();
    reportText.dispose();
    super.dispose();
  }

  Future<void> _attach() async {
    if (picking) return;
    final isReport = report;
    setState(() {
      picking = true;
      error = null;
    });
    try {
      final picked = isReport ? await media.document() : await media.photo();
      if (picked != null && mounted) {
        setState(() {
          if (isReport) {
            document = picked;
          } else {
            photo = picked;
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => error =
              'Lampiran tidak dapat dibuka. Periksa izin dan coba lagi.',
        );
      }
    } finally {
      if (mounted) setState(() => picking = false);
    }
  }

  Future<void> _send() async {
    final attachment = report ? document : photo;
    final text = report ? reportText.text : updateText.text;
    if (text.trim().isEmpty || attachment == null) {
      setState(
        () => error =
            'Lengkapi ${report ? 'judul dan dokumen laporan' : 'cerita perkembangan dan foto'}.',
      );
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.repository.sendActivity(
        FarmerActivity(
          projectId: widget.project.id,
          report: report,
          text: text.trim(),
          stage: stage,
          attachment: Uint8List.fromList(attachment.bytes),
          attachmentName: attachment.name,
          createdAt: DateTime.now(),
        ),
      );
      if (!mounted) return;
      setState(() => busy = false);
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(report ? 'Laporan tersimpan' : 'Update tersimpan'),
          content: const Text('Aktivitas tersimpan dalam sesi demo ini.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Selesai'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(
          () => error = 'Aktivitas belum dapat disimpan. Silakan coba lagi.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => FarmerPage(
    bottom: FarmerActions(
      label: 'Kirim',
      onPressed: busy || picking ? null : _send,
      loading: busy,
    ),
    child: ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        FarmHero(
          title: widget.project.title,
          location: widget.project.location.displayName,
          bytes:
              widget.repository.proposals.any((p) => p.id == widget.project.id)
              ? widget.repository.details(widget.project.id).farmPhoto
              : null,
          asset:
              widget.repository.proposals.any((p) => p.id == widget.project.id)
              ? widget.repository.details(widget.project.id).farmPhotoAsset
              : 'chili.png',
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<bool>(
          initialValue: report,
          isExpanded: true,
          items: const [
            DropdownMenuItem(
              value: false,
              child: Center(child: Text('Kirim Update')),
            ),
            DropdownMenuItem(
              value: true,
              child: Center(child: Text('Kirim Laporan')),
            ),
          ],
          onChanged: busy || picking
              ? null
              : (v) => setState(() {
                  report = v!;
                  error = null;
                }),
        ),
        const SizedBox(height: 16),
        Text(
          report ? 'Judul Laporan' : 'Ceritakan Perkembangan',
          style: const TextStyle(fontSize: 17),
        ),
        const SizedBox(height: 12),
        TextField(
          key: ValueKey(report ? 'report-text' : 'update-text'),
          controller: report ? reportText : updateText,
          maxLines: report ? 2 : 4,
          decoration: InputDecoration(
            hintText: report
                ? 'Masukkan judul laporan anda'
                : 'Ceritakan perkembangan dari lahan Anda',
          ),
        ),
        const SizedBox(height: 16),
        const Text('Tahap Tanam', style: TextStyle(fontSize: 17)),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: stage,
          isExpanded: true,
          items: [
            'Persiapan Lahan',
            'Penanaman',
            'Pemupukan & Perawatan',
            'Panen',
            'Distribusi',
          ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
          onChanged: (v) => setState(() => stage = v!),
        ),
        const SizedBox(height: 16),
        Text(
          report ? 'Dokumen Laporan' : 'Foto Perkembangan',
          style: const TextStyle(fontSize: 17),
        ),
        const SizedBox(height: 12),
        if (report && document != null)
          FarmerCard(
            radius: 14,
            child: Row(
              children: [
                const Icon(Icons.description_outlined),
                const SizedBox(width: 8),
                Expanded(child: Text(document!.name)),
                IconButton(
                  onPressed: () => setState(() => document = null),
                  tooltip: 'Hapus dokumen',
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
        if (!report && photo != null) ...[
          FarmPhoto(bytes: photo!.bytes, height: 220),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: _attach, child: const Text('Edit')),
              TextButton(
                onPressed: () => setState(() => photo = null),
                child: const Text('Hapus'),
              ),
            ],
          ),
        ],
        FarmerButton(
          label: report ? 'Tautkan Dokumen Laporan' : 'Ambil Foto',
          icon: report ? Icons.attach_file : Icons.camera_alt_outlined,
          onPressed: busy || picking ? null : _attach,
        ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Semantics(
              liveRegion: true,
              child: Text(
                error!,
                style: const TextStyle(color: FarmerDesign.red),
              ),
            ),
          ),
      ],
    ),
  );
}
