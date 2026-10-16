import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../domain/domain.dart';
import '../../../common/farmer_design.dart';
import '../../../common/farmer_media_service.dart';
import '../../../data/farmer_repository.dart';
import '../state/proposal_wizard_controller.dart';
import '../widgets/farmer_location_picker.dart';
import '../widgets/proposal_summary.dart';
import 'investor_preview_page.dart';

class ProposalWizardPage extends StatefulWidget {
  const ProposalWizardPage({
    super.key,
    required this.repository,
    this.initial,
    this.editingId,
    this.initialStep = 0,
    this.sectionOnly = false,
    this.media,
  });
  final FarmerRepository repository;
  final FarmerProposalDetails? initial;
  final String? editingId;
  final int initialStep;
  final bool sectionOnly;
  final FarmerMediaService? media;
  @override
  State<ProposalWizardPage> createState() => _ProposalWizardPageState();
}

class _ProposalWizardPageState extends State<ProposalWizardPage> {
  late final controller = ProposalWizardController(
    repository: widget.repository,
    initial: widget.initial,
    editingId: widget.editingId,
  )..step = widget.initialStep;
  final scroll = ScrollController();
  final inputs = <String, TextEditingController>{};
  late final media = widget.media ?? FarmerMediaService();
  bool mediaBusy = false;
  @override
  void dispose() {
    controller.dispose();
    scroll.dispose();
    for (final input in inputs.values) {
      input.dispose();
    }
    super.dispose();
  }

  void _move(VoidCallback action) {
    action();
    if (scroll.hasClients) scroll.jumpTo(0);
  }

  void _back() {
    if (controller.busy) return;
    if (widget.sectionOnly || controller.step == 0) {
      Navigator.pop(context);
    } else {
      _move(controller.back);
    }
  }

  Future<void> _next() async {
    FocusScope.of(context).unfocus();
    if (widget.sectionOnly) {
      if (controller.validate()) {
        Navigator.pop(context, controller.draft.copy());
      }
    } else if (controller.step < 4) {
      _move(controller.next);
    } else if (await controller.submit() && mounted) {
      await Navigator.push<void>(
        context,
        MaterialPageRoute(builder: (_) => const ProposalSuccessPage()),
      );
      if (mounted) Navigator.pop(context, true);
    }
  }

  Future<void> _capture(bool sppt) async {
    if (mediaBusy) return;
    setState(() => mediaBusy = true);
    try {
      // SPPT is PDF-only (backend `/area/upload-area-document` accepts PDF).
      final attachment = sppt
          ? await media.pdfDocument()
          : await media.uploadImage();
      if (attachment == null || !mounted) return;
      if (sppt) {
        controller.draft.sppt = attachment.bytes;
        controller.draft.spptName = attachment.name;
      } else {
        controller.draft.farmPhoto = attachment.bytes;
        controller.draft.farmPhotoName = attachment.name;
      }
      controller.changed();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is StateError ? e.message : 'Lampiran tidak dapat dibuka. Periksa izin perangkat lalu coba lagi.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => mediaBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) => PopScope(
      canPop: !controller.busy,
      child: FarmerPage(
        showBack: false,
        bottom: FarmerActions(
          label: widget.sectionOnly
              ? 'Simpan Perubahan'
              : controller.step == 4
              ? 'Konfirmasi'
              : 'Selanjutnya',
          onPressed: controller.busy || mediaBusy ? null : _next,
          loading: controller.busy,
          onBack: _back,
        ),
        child: ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          children: [
            if (!widget.sectionOnly && controller.step < 4)
              Padding(
                padding: const EdgeInsets.fromLTRB(72, 8, 72, 16),
                child: Row(
                  children: [
                    for (var i = 0; i < 5; i++)
                      Expanded(
                        child: Container(
                          height: 5,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color: i <= controller.step
                                ? FarmerDesign.blue
                                : const Color(0xFFD6EEF6),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            Text(
              [
                'Tentukan Lokasi Lahan',
                'Komoditas dan Target Panen',
                'Kebutuhan Modal',
                'Identifikasi Risiko',
                'Review dan Kirim',
              ][controller.step],
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            Text(
              [
                'Bantu kami mengetahui lokasi lahan yang investor akan danai nantinya',
                'Tentukan komoditas target hasil panen yang akan anda hasilkan',
                'Tentukan rincian dana yang dibutuhkan untuk lahan tanam anda',
                'Identifikasi potensi risiko untuk lahan tanam anda untuk menghadapinya',
                'Periksa kembali detail proposal anda sebelum dikirim ke investor.',
              ][controller.step],
              style: const TextStyle(color: FarmerDesign.muted, fontSize: 16),
            ),
            const SizedBox(height: 16),
            if (controller.error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    controller.error!,
                    style: const TextStyle(color: FarmerDesign.red),
                  ),
                ),
              ),
            ...switch (controller.step) {
              0 => _location(),
              1 => _commodity(),
              2 => _budget(),
              3 => _risks(),
              _ => _review(),
            },
          ],
        ),
      ),
    ),
  );
  Widget _field(
    String label,
    String name,
    String initial,
    ValueChanged<String> change, {
    String? hint,
    String? suffix,
    bool number = false,
    bool money = false,
    int lines = 1,
  }) {
    final input = inputs.putIfAbsent(
      name,
      () => TextEditingController(text: initial),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 17)),
          const SizedBox(height: 12),
          TextField(
            key: ValueKey(name),
            controller: input,
            minLines: lines,
            maxLines: lines,
            keyboardType: number || money
                ? const TextInputType.numberWithOptions(decimal: true)
                : lines > 1
                ? TextInputType.multiline
                : TextInputType.text,
            inputFormatters: number || money
                ? [
                    FilteringTextInputFormatter.allow(
                      RegExp(money ? r'[0-9]' : r'[0-9.,]'),
                    ),
                  ]
                : null,
            decoration: InputDecoration(
              hintText: hint,
              suffixText: suffix,
              prefixText: money ? 'Rp ' : null,
            ),
            onChanged: (s) {
              change(s);
              controller.changed();
            },
          ),
        ],
      ),
    );
  }

  double _decimal(String s) => double.tryParse(s.replaceAll(',', '.')) ?? 0;
  List<Widget> _location() {
    final d = controller.draft;
    return [
      _field(
        'Nama Lahan',
        'land-name',
        d.landName,
        (s) => d.landName = s,
        hint: 'Contoh: Sawah Pak Budi',
      ),
      FarmerLocationPicker(
        location: d.location,
        onChanged: (l) {
          d.location = l;
          controller.changed();
        },
      ),
      const SizedBox(height: 16),
      _field(
        'Alamat Lengkap',
        'address',
        d.address,
        (s) => d.address = s,
        hint: 'Jalan, RT/RW, desa, kecamatan, kota/kabupaten, provinsi',
        lines: 3,
      ),
      _field(
        'Luas Lahan',
        'area',
        d.area == 0 ? '' : farmerNumber(d.area),
        (s) => d.area = _decimal(s),
        hint: 'Masukkan luas lahan anda',
        suffix: 'Hektar',
        number: true,
      ),
      _field(
        'Deskripsi Lahan',
        'land-description',
        d.landDescription,
        (s) => d.landDescription = s,
        hint: 'Kondisi lahan, jenis tanah, sumber air, dll.',
        lines: 3,
      ),
      const Text('Foto Lahan', style: TextStyle(fontSize: 17)),
      const SizedBox(height: 12),
      if (d.farmPhoto != null) ...[
        FarmPhoto(bytes: d.farmPhoto),
        const SizedBox(height: 8),
      ],
      FarmerButton(
        label: d.farmPhoto == null ? 'Unggah Foto Lahan' : 'Ganti Foto Lahan',
        icon: Icons.upload_outlined,
        onPressed: mediaBusy ? null : () => _capture(false),
      ),
      const SizedBox(height: 8),
      const Text(
        'Pilih foto lahan dari galeri. Format JPG, PNG, atau WEBP.',
        style: TextStyle(color: FarmerDesign.muted, fontSize: 12),
      ),
      const SizedBox(height: 16),
      const Text('Surat Kepemilikan (SPPT) *', style: TextStyle(fontSize: 17)),
      const SizedBox(height: 12),
      if (d.spptName != null)
        Row(
          children: [
            Expanded(child: Text(d.spptName!)),
            IconButton(
              tooltip: 'Hapus SPPT',
              onPressed: () {
                d.sppt = null;
                d.spptName = null;
                controller.changed();
              },
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      FarmerButton(
        label: d.spptName == null
            ? 'Unggah Dokumen SPPT (PDF)'
            : 'Ganti Dokumen SPPT (PDF)',
        icon: Icons.picture_as_pdf_outlined,
        onPressed: mediaBusy ? null : () => _capture(true),
      ),
      const SizedBox(height: 8),
      const Text(
        'Wajib diunggah. Format PDF, maksimal 10 MB.',
        style: TextStyle(color: FarmerDesign.muted, fontSize: 12),
      ),
    ];
  }

  List<Widget> _commodity() {
    final d = controller.draft;
    const emojis = ['🌾', '🥬', '🌶️', '🍊', '🌽', '🌴'];
    final choices = Commodity.values.take(6).toList();
    return [
      const Text('Komoditas yang Akan Ditanam', style: TextStyle(fontSize: 17)),
      const SizedBox(height: 12),
      LayoutBuilder(
        builder: (context, box) {
          final columns =
              box.maxWidth < 320 ||
                  MediaQuery.textScalerOf(context).scale(16) > 20
              ? 2
              : 3;
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < choices.length; i++)
                SizedBox(
                  width: (box.maxWidth - (columns - 1) * 8) / columns,
                  child: Semantics(
                    selected: d.commodity == choices[i],
                    button: true,
                    child: FarmerCard(
                      radius: 16,
                      onTap: () {
                        d.commodity = choices[i];
                        controller.changed();
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  emojis[i],
                                  style: const TextStyle(fontSize: 28),
                                ),
                              ),
                              Icon(
                                d.commodity == choices[i]
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                color: d.commodity == choices[i]
                                    ? FarmerDesign.blueInk
                                    : FarmerDesign.muted,
                                size: 16,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            farmerCommodity(choices[i]),
                            style: const TextStyle(fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
      const SizedBox(height: 16),
      const Text('Perkiraan Waktu Tanam', style: TextStyle(fontSize: 17)),
      const SizedBox(height: 12),
      FarmerButton(
        label: farmerMonth(d.plantingMonth),
        icon: Icons.calendar_month_outlined,
        onPressed: () async {
          final date = await showDatePicker(
            context: context,
            initialDate: d.plantingMonth,
            firstDate: DateTime(2026),
            lastDate: DateTime(2036),
          );
          if (date != null && mounted) {
            d.plantingMonth = DateTime(date.year, date.month);
            controller.changed();
          }
        },
      ),
      const SizedBox(height: 8),
      const Text(
        'Tanggal akan disesuaikan setelah proses verifikasi',
        style: TextStyle(color: FarmerDesign.muted, fontSize: 12),
      ),
      const SizedBox(height: 16),
      _field(
        'Estimasi Hasil Panen',
        'harvest',
        d.harvestTons == 0 ? '' : farmerNumber(d.harvestTons),
        (s) => d.harvestTons = _decimal(s),
        hint: 'Masukkan estimasi hasil panen Anda',
        suffix: 'Ton',
        number: true,
      ),
      _field(
        'Estimasi Penjualan Panen',
        'sale',
        d.salePrice == 0 ? '' : '${d.salePrice}',
        (s) => d.salePrice = int.tryParse(s) ?? 0,
        hint: 'Harga penjualan panen',
        suffix: '/ Ton',
        money: true,
      ),
      _field(
        'Deskripsi Proposal',
        'description',
        d.description,
        (s) => d.description = s,
        hint: 'Jelaskan rencana budidaya Anda kepada investor',
        lines: 3,
      ),
    ];
  }

  List<Widget> _budget() => [
    const Text(
      'Total Dana Dibutuhkan',
      style: TextStyle(color: FarmerDesign.muted),
    ),
    const SizedBox(height: 8),
    Text(
      farmerRupiah(controller.draft.total),
      style: const TextStyle(fontSize: 26),
    ),
    const SizedBox(height: 16),
    for (final category in FarmerProposalDetails.budgetCategories)
      _field(
        category,
        'budget-$category',
        controller.draft.budget[category] == 0
            ? ''
            : '${controller.draft.budget[category]}',
        (s) {
          controller.draft.budget[category] = int.tryParse(s) ?? 0;
          // A description is only allowed alongside an other-cost amount.
          if (category == FarmerProposalDetails.otherCost &&
              controller.draft.otherCostAmount <= 0) {
            controller.draft.otherCostDescription = '';
            inputs['other-cost-description']?.clear();
          }
        },
        hint: 'Masukkan dana ${category.toLowerCase()} anda',
        money: true,
      ),
    _otherCostDescription(),
  ];

  Widget _otherCostDescription() {
    final d = controller.draft;
    final enabled = d.otherCostAmount > 0;
    final input = inputs.putIfAbsent(
      'other-cost-description',
      () => TextEditingController(text: d.otherCostDescription),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Deskripsi Biaya Lainnya',
            style: TextStyle(
              fontSize: 17,
              color: enabled ? null : FarmerDesign.muted,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('other-cost-description'),
            controller: input,
            enabled: enabled,
            minLines: 3,
            maxLines: 3,
            keyboardType: TextInputType.multiline,
            decoration: InputDecoration(
              hintText: enabled
                  ? 'Jelaskan peruntukan biaya lainnya'
                  : 'Isi jumlah biaya lainnya terlebih dahulu',
            ),
            onChanged: (s) {
              d.otherCostDescription = s;
              controller.changed();
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _risks() => [
    Wrap(
      spacing: 8,
      runSpacing: 12,
      children: [
        for (final (label, emoji) in [
          ('Risiko Cuaca', '🌦️'),
          ('Serangan Hama', '🐛'),
          ('Fluktuasi Harga Pasar', '📉'),
        ])
          SizedBox(
            width: label == 'Fluktuasi Harga Pasar' ? double.infinity : null,
            child: FilterChip(
              label: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 28)),
                    const SizedBox(height: 8),
                    Text(label),
                  ],
                ),
              ),
              selected: controller.draft.risks.contains(label),
              selectedColor: FarmerDesign.cyan,
              backgroundColor: Colors.white,
              onSelected: (selected) {
                selected
                    ? controller.draft.risks.add(label)
                    : controller.draft.risks.remove(label);
                controller.changed();
              },
            ),
          ),
      ],
    ),
  ];
  List<Widget> _review() => [
    FarmerButton(
      label: 'Lihat Proposal Sebagai Investor',
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => InvestorPreviewPage(details: controller.draft.copy()),
        ),
      ),
    ),
    const SizedBox(height: 16),
    ProposalSummary(
      details: controller.draft,
      onEdit: (step) => _move(() => controller.edit(step)),
    ),
  ];
}

class ProposalSuccessPage extends StatelessWidget {
  const ProposalSuccessPage({super.key});
  @override
  Widget build(BuildContext context) => FarmerPresentation(
    child: Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Image.asset(
                '${FarmerDesign.asset}success.png',
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Proposal Berhasil Dikirim!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Pantau terus kemajuan dari proposal anda melalui aplikasi',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: FarmerDesign.muted, fontSize: 16),
                  ),
                  const SizedBox(height: 48),
                  FarmerButton(
                    label: 'Selesai',
                    primary: true,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
