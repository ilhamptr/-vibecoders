import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../domain/project/project_location.dart';
import '../../../common/farmer_design.dart';

/// OSM tiles are authorized by the user. Public address lookup stays disabled.
class FarmerLocationPicker extends StatefulWidget {
  const FarmerLocationPicker({
    super.key,
    required this.onChanged,
    this.location,
  });
  final ValueChanged<ProjectLocation> onChanged;
  final ProjectLocation? location;
  @override
  State<FarmerLocationPicker> createState() => _FarmerLocationPickerState();
}

class _FarmerLocationPickerState extends State<FarmerLocationPicker> {
  final map = MapController();
  late LatLng point = LatLng(
    widget.location?.latitude ?? -7.705,
    widget.location?.longitude ?? 110.601,
  );
  bool busy = false;
  String? error;
  void _select(LatLng p) {
    setState(() {
      point = p;
      error = null;
    });
    final old = widget.location;
    widget.onChanged(
      ProjectLocation(
        province: old?.province ?? '',
        city: old?.city ?? '',
        village: old?.village,
        district: old?.district,
        latitude: p.latitude,
        longitude: p.longitude,
      ),
    );
  }

  Future<void> _gps() async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw StateError('Aktifkan layanan lokasi perangkat.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw StateError(
          'Izin lokasi belum diberikan. Anda tetap dapat mengisi alamat secara manual.',
        );
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
      if (!mounted) return;
      final p = LatLng(pos.latitude, pos.longitude);
      map.move(p, 15);
      _select(p);
    } catch (e) {
      if (mounted) {
        setState(
          () => error = e is StateError
              ? e.message
              : 'Lokasi saat ini tidak tersedia. Isi lokasi secara manual.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    map.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SizedBox(
          height: 240,
          child: Stack(
            children: [
              const Positioned.fill(
                child: ColoredBox(color: Color(0xFFF0F5F2)),
              ),
              const Positioned.fill(
                child: CustomPaint(painter: _GridPainter()),
              ),
              FlutterMap(
                mapController: map,
                options: MapOptions(
                  initialCenter: point,
                  initialZoom: 13,
                  onTap: (_, p) => _select(p),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'id.farmer.flutter',
                    errorImage: const AssetImage(
                      '${FarmerDesign.asset}map-unavailable.png',
                    ),
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
                          color: FarmerDesign.blueInk,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 8),
      FarmerButton(
        label: busy ? 'Mencari lokasi…' : 'Gunakan Lokasi Saat Ini',
        onPressed: busy ? null : _gps,
        icon: Icons.my_location,
      ),
      const SizedBox(height: 8),
      const Text(
        'Ketuk peta untuk memilih titik. Isi alamat lahan secara manual.',
        style: TextStyle(color: FarmerDesign.muted, fontSize: 12),
      ),
      if (widget.location?.latitude != null)
        Text(
          '${widget.location!.latitude!.toStringAsFixed(5)}, ${widget.location!.longitude!.toStringAsFixed(5)}',
          style: const TextStyle(color: FarmerDesign.blueInk, fontSize: 12),
        ),
      if (error != null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(error!, style: const TextStyle(color: FarmerDesign.red)),
        ),
    ],
  );
}

class _GridPainter extends CustomPainter {
  const _GridPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final pen = Paint()
      ..color = const Color(0xFFD9E5DE)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 32) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), pen);
    }
    for (double y = 0; y < size.height; y += 32) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), pen);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) => false;
}
