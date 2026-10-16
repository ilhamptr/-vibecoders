import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../domain/domain.dart';
import '../../../shared/shared.dart';

abstract final class FarmerDesign {
  static const background = Color(0xFFFBFFFF);
  static const ink = Color(0xFF1C1D21);
  static const muted = Color(0xFF5F6368);
  static const blue = Color(0xFF3FA7D6);
  static const blueInk = Color(0xFF006FAE);
  static const cyan = Color(0xFFC8F7FF);
  static const gold = Color(0xFF906500);
  static const yellow = Color(0xFFFFF7D0);
  static const red = Color(0xFFBA1734);
  static const pink = Color(0xFFFFD8CF);
  static const line = Color(0xFFEDEEEE);
  static const asset = 'assets/farmer/design/';

  static ThemeData theme(BuildContext context) {
    final base = Theme.of(context);
    return base.copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: base.colorScheme.copyWith(
        primary: blueInk,
        onPrimary: Colors.white,
        surface: Colors.white,
        onSurface: ink,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontSize: 16),
        bodyMedium: TextStyle(fontSize: 14),
        bodySmall: TextStyle(fontSize: 12, color: muted),
        labelLarge: TextStyle(fontSize: 16),
      ).apply(fontFamily: 'Roboto', bodyColor: ink, displayColor: ink),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 16,
        ),
        hintStyle: const TextStyle(color: muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: blueInk),
        ),
      ),
    );
  }
}

class FarmerPresentation extends StatelessWidget {
  const FarmerPresentation({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) =>
      Theme(data: FarmerDesign.theme(context), child: child);
}

class FarmerCard extends StatelessWidget {
  const FarmerCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.radius = 24,
  });
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double radius;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      boxShadow: const [
        BoxShadow(
          color: Color(0x06000000),
          blurRadius: 6,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: AppCard(
      borderRadius: radius,
      borderColor: FarmerDesign.line,
      padding: padding,
      onTap: onTap,
      child: child,
    ),
  );
}

class FarmerButton extends StatelessWidget {
  const FarmerButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.primary = false,
    this.icon,
    this.loading = false,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool primary;
  final IconData? icon;
  final bool loading;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(primary ? 12 : 999),
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: primary
            ? const [Color(0xFF287DA7), Color(0xFF23658F)]
            : const [Colors.white, Color(0xFFF9F9F9)],
      ),
      border: primary ? null : Border.all(color: FarmerDesign.line),
    ),
    child: AppButton(
      label: label,
      onPressed: onPressed,
      isLoading: loading,
      leading: icon == null ? null : Icon(icon, size: 20),
      height: 48,
      borderRadius: primary ? 12 : 999,
      backgroundColor: Colors.transparent,
      foregroundColor: primary ? Colors.white : FarmerDesign.ink,
    ),
  );
}

class FarmerActions extends StatelessWidget {
  const FarmerActions({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.onBack,
  });
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final VoidCallback? onBack;
  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FarmerButton(
            label: label,
            onPressed: onPressed,
            primary: true,
            loading: loading,
          ),
          TextButton.icon(
            onPressed: onBack ?? () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Kembali'),
          ),
        ],
      ),
    ),
  );
}

class FarmerPage extends StatelessWidget {
  const FarmerPage({
    super.key,
    required this.child,
    this.title,
    this.bottom,
    this.showBack = true,
  });
  final Widget child;
  final String? title;
  final Widget? bottom;
  final bool showBack;
  @override
  Widget build(BuildContext context) => FarmerPresentation(
    child: Scaffold(
      appBar: showBack
          ? AppBar(
              leading: BackButton(onPressed: () => Navigator.pop(context)),
              title: title == null ? null : Text(title!),
            )
          : null,
      body: SafeArea(
        bottom: bottom == null,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: child,
          ),
        ),
      ),
      bottomNavigationBar: bottom,
    ),
  );
}

class FarmPhoto extends StatelessWidget {
  const FarmPhoto({
    super.key,
    this.height = 88,
    this.bytes,
    this.url,
    this.asset = 'chili.png',
  });
  final double height;
  final Uint8List? bytes;

  /// Remote image (e.g. Supabase storage). Falls back to [asset] on error.
  final String? url;
  final String? asset;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(16),
    child: SizedBox(
      width: double.infinity,
      height: height,
      child: bytes != null
          ? Image.memory(bytes!, fit: BoxFit.cover)
          : url != null
          ? Image.network(
              url!,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) => progress == null
                  ? child
                  : const ColoredBox(color: Color(0xFFF4F8F9)),
              errorBuilder: (context, error, stack) => Image.asset(
                '${FarmerDesign.asset}${asset ?? 'chili.png'}',
                fit: BoxFit.cover,
              ),
            )
          : asset != null
          ? Image.asset('${FarmerDesign.asset}$asset', fit: BoxFit.cover)
          : const ColoredBox(
              color: Color(0xFFF4F8F9),
              child: Center(
                child: Text(
                  'Foto lahan belum diunggah',
                  style: TextStyle(color: FarmerDesign.muted, fontSize: 12),
                ),
              ),
            ),
    ),
  );
}

class FarmHero extends StatelessWidget {
  const FarmHero({
    super.key,
    required this.title,
    required this.location,
    this.bytes,
    this.asset = 'chili.png',
  });
  final String title;
  final String location;
  final Uint8List? bytes;
  final String? asset;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(24),
    child: SizedBox(
      height: 256,
      child: Stack(
        fit: StackFit.expand,
        children: [
          FarmPhoto(height: 256, bytes: bytes, asset: asset),
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
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  location,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class FarmerInfo extends StatelessWidget {
  const FarmerInfo({super.key, required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: FarmerDesign.muted)),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 17)),
      ],
    ),
  );
}

class FarmerTint extends StatelessWidget {
  const FarmerTint({
    super.key,
    required this.child,
    this.color = FarmerDesign.cyan,
  });
  final Widget child;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(14),
    ),
    child: child,
  );
}

class FarmerTabs extends StatelessWidget {
  const FarmerTabs({
    super.key,
    required this.labels,
    required this.selected,
    required this.onChanged,
  });
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: const Color(0xFFF4F8F9),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: Material(
              color: i == selected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
              child: InkWell(
                borderRadius: BorderRadius.circular(999),
                onTap: () => onChanged(i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 8,
                  ),
                  child: Text(
                    labels[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: i == selected
                          ? FarmerDesign.ink
                          : FarmerDesign.muted,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

String farmerRupiah(num value, {bool prefix = true}) =>
    '${prefix ? 'Rp ' : ''}${value.round().toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
String farmerNumber(num value) =>
    value.toString().replaceAll(RegExp(r'\.0$'), '').replaceAll('.', ',');
const farmerMonths = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];
String farmerMonth(DateTime date) =>
    '${farmerMonths[date.month - 1]} ${date.year}';
String farmerDate(DateTime date) => '${date.day} ${farmerMonth(date)}';
String farmerCommodity(Commodity c) => switch (c) {
  Commodity.rice => 'Padi',
  Commodity.vegetables => 'Sayuran',
  Commodity.spices => 'Rempah',
  Commodity.fruits => 'Buah',
  Commodity.secondaryCrops => 'Palawija',
  Commodity.plantation => 'Perkebunan',
  Commodity.other => 'Lainnya',
};
