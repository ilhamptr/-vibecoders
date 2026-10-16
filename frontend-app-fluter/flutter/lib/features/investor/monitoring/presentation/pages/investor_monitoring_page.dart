import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../app/router/investor_routes.dart';
import '../../../../../shared/shared.dart';
import '../../../common/investor_design.dart';
import '../../../common/project_widgets.dart';
import '../../../common/status_view.dart';
import '../../data/investor_monitoring_repository.dart';
import '../state/monitoring_controller.dart';

class InvestorMonitoringPage extends StatefulWidget {
  const InvestorMonitoringPage({
    super.key,
    required this.repository,
    required this.investmentId,
  });

  final InvestorMonitoringRepository repository;
  final String investmentId;

  @override
  State<InvestorMonitoringPage> createState() => _InvestorMonitoringPageState();
}

class _InvestorMonitoringPageState extends State<InvestorMonitoringPage> {
  late final MonitoringController controller = MonitoringController(
    widget.repository,
    widget.investmentId,
  )..load();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _invest() {
    final investment = controller.data?.investment;
    if (investment == null) return;
    Navigator.pushNamed(context, InvestorRoutes.invest(investment.id));
  }

  @override
  Widget build(BuildContext context) => InvestorPresentation(
    child: ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final loaded = controller.status == LoadStatus.success;
        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              tooltip: 'Kembali',
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: StatusView(
            status: controller.status,
            onRetry: controller.load,
            emptyMessage: 'Investasi tidak ditemukan.',
            builder: (context) => _Content(data: controller.data!),
          ),
          bottomNavigationBar: loaded
              ? AppStickyBottomBar(
                  showTopBorder: false,
                  backgroundColor: InvestorDesign.background,
                  child: DesignButton(
                    label: 'Investasi',
                    onPressed: _invest,
                  ),
                )
              : null,
        );
      },
    ),
  );
}

class _Content extends StatelessWidget {
  const _Content({required this.data});

  final InvestorMonitoring data;

  @override
  Widget build(BuildContext context) {
    final investment = data.investment;
    final project = investment.project;
    final fund = data.fundBreakdown;
    final description = project.description?.trim();
    final location = project.location;
    final hasCoords = location.latitude != null && location.longitude != null;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      children: [
        ProjectHero(project: project),
        const SizedBox(height: 24),

        // Investment summary.
        DesignCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitle('Informasi Investasi'),
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
                      label: 'Perkiraan ROI',
                      value: '${project.roiMinPercent.round()}%',
                      backgroundColor: InvestorDesign.green,
                      labelColor: const Color(0xFF4AAB45),
                      valueColor: const Color(0xFF4AAB45),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _MetaRow(label: 'Pemilik Proyek', value: project.farmer.name),
              _MetaRow(
                label: 'Status',
                value: investmentStatusLabel(investment.status),
              ),
            ],
          ),
        ),

        // Project description.
        if (description != null && description.isNotEmpty) ...[
          const SizedBox(height: 24),
          DesignCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle('Deskripsi Proyek'),
                const SizedBox(height: 12),
                Text(
                  description,
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        ],

        // Location: OSM map tiles with a marker at the land coordinates.
        if (hasCoords) ...[
          const SizedBox(height: 24),
          DesignCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle('Lokasi Lahan'),
                const SizedBox(height: 12),
                _LocationMap(
                  latitude: location.latitude!,
                  longitude: location.longitude!,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.place_outlined,
                      size: 18,
                      color: InvestorDesign.muted,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '${location.latitude!.toStringAsFixed(6)}, '
                        '${location.longitude!.toStringAsFixed(6)}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],

        // Fund usage breakdown.
        if (fund != null) ...[
          const SizedBox(height: 24),
          DesignCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle('Rincian Penggunaan Dana'),
                const SizedBox(height: 12),
                for (final line in fund.baseLines)
                  _MetaRow(
                    label: line.label,
                    value: rupiah(line.amount.amount),
                  ),
                // "Lainnya" only appears when there is such a cost; its
                // description explains what it covers.
                if (fund.hasOthers) ...[
                  _MetaRow(
                    label: 'Lainnya',
                    value: rupiah(fund.others.amount),
                  ),
                  if (fund.description != null &&
                      fund.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 4),
                      child: Text(
                        fund.description!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: InvestorDesign.muted,
                          height: 1.4,
                        ),
                      ),
                    ),
                ],
                const Divider(height: 24),
                _MetaRow(
                  label: 'Total',
                  value: rupiah(fund.total.amount),
                  emphasize: true,
                ),
              ],
            ),
          ),
        ],

        // Field updates from the farmer. Endpoint pending; shown as a
        // placeholder so the section stays wired for when it lands.
        const SizedBox(height: 24),
        Text(
          'Update dari ${project.farmer.name}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        const DesignCard(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Belum ada pembaruan dari petani.',
              style: TextStyle(color: InvestorDesign.muted),
            ),
          ),
        ),
      ],
    );
  }
}

/// Read-only OpenStreetMap tile view centered on the land location, with a
/// marker. Interaction is disabled since this is a display-only context.
class _LocationMap extends StatelessWidget {
  const _LocationMap({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  @override
  Widget build(BuildContext context) {
    final point = LatLng(latitude, longitude);
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 180,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: point,
            initialZoom: 14,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.none,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'id.tanifund.flutter',
            ),
            const SimpleAttributionWidget(
              source: Text(
                '© OpenStreetMap contributors',
                style: TextStyle(fontSize: 10),
              ),
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: point,
                  width: 44,
                  height: 44,
                  child: const Icon(
                    Icons.location_on,
                    color: InvestorDesign.blue,
                    size: 40,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A label on the left and a value on the right, used for the meta rows and
/// the fund breakdown lines.
class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: emphasize ? InvestorDesign.ink : InvestorDesign.muted,
              fontWeight: emphasize ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}
