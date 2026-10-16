import 'package:flutter/material.dart';

const kBlue = Color(0xFF4F9FD3);

class InitialPage extends StatelessWidget {
  final VoidCallback onStart;
  final VoidCallback onLogin;

  const InitialPage({
    super.key,
    required this.onStart,
    required this.onLogin,
  });
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFA9DDEE), Color(0xFF58A6D8), Colors.white],
            stops: [0.0, 0.32, 0.55],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 8),
                // Tumpukan kartu yang memudar ke bawah
                SizedBox(
                  height: 400,
                  child: ShaderMask(
                    shaderCallback: (r) => const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black, Colors.black, Colors.transparent],
                      stops: [0.0, 0.6, 1.0],
                    ).createShader(r),
                    blendMode: BlendMode.dstIn,
                    child: Stack(
                      children: [
                        _ghost(top: 150, opacity: 0.35, inset: 0),
                        _ghost(top: 105, opacity: 0.6, inset: 0),
                        const Positioned(
                            top: 0, left: 0, right: 0, child: ProjectCard()),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                const Text(
                  'Dukung Pertanian Berkelanjutan',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Text(
                  'Temukan proyek petani dengan tujuan,\nanggaran, dan risiko yang transparan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 16, height: 1.4, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 28),
                const _Indicator(),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: onStart,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                    ),
                    child: const Text('Jadi Investor/Petani',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Sudah Memiliki Akun? ',
                        style: TextStyle(
                            fontSize: 16, color: Colors.grey.shade600)),
                    GestureDetector(
                      onTap: onLogin,
                      child: const Text('Login',
                          style: TextStyle(
                              fontSize: 16,
                              color: kBlue,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _ghost({
    required double top,
    required double opacity,
    required double inset,
  }) {
    return Positioned(
      top: top,
      left: inset,
      right: inset,
      child: Opacity(
        opacity: opacity,
        child: Container(
          height: 90,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          child: const _ProgressRow(),
        ),
      ),
    );
  }
}

class ProjectCard extends StatelessWidget {
  const ProjectCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: SizedBox(
              height: 120,
              width: double.infinity,
              // Ganti dengan Image.asset('assets/cabai.jpg', fit: BoxFit.cover)
              child: Image.network(
                'https://images.unsplash.com/photo-1583119022894-919a68a3d0e3?w=800',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(color: Colors.green.shade200),
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text('Perkebunan Cabai Alam Sutera',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Asep Suwanto', style: TextStyle(fontSize: 13)),
                SizedBox(width: 6),
                Icon(Icons.check, size: 16, color: Colors.green),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Row(
            children: [
              _StatBox(
                icon: Icons.savings_outlined,
                label: 'Perkiraan ROI',
                value: '15-20%',
                bg: Color(0xFFE3F6D8),
                fg: Color(0xFF4CAF50),
              ),
              SizedBox(width: 10),
              _StatBox(
                icon: Icons.spa_outlined,
                label: 'Panen Setiap',
                value: '4 Bulan',
                bg: Color(0xFFD9F4FD),
                fg: Color(0xFF2F7FD6),
              ),
              SizedBox(width: 10),
              _StatBox(
                icon: Icons.schedule,
                label: 'Sisa Waktu',
                value: '12 Hari',
                bg: Color(0xFFFFF4D1),
                fg: Color(0xFFD4A21F),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const _ProgressRow(),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color bg, fg;

  const _StatBox({
    required this.icon,
    required this.label,
    required this.value,
    required this.bg,
    required this.fg,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: fg),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: fg)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w600, color: fg)),
          ],
        ),
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow();

  @override
  Widget build(BuildContext context) {
    final grey = TextStyle(fontSize: 16, color: Colors.grey.shade500);
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: 0.72,
            minHeight: 6,
            backgroundColor: Colors.grey.shade200,
            valueColor: const AlwaysStoppedAnimation(kBlue),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('53 Investor', style: grey),
            Text('< 50JT • 72%', style: grey),
          ],
        ),
      ],
    );
  }
}

class _Indicator extends StatelessWidget {
  const _Indicator();

  @override
  Widget build(BuildContext context) {
    Widget bar(double h, bool active) => Container(
          width: 10,
          height: h,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: active ? kBlue : kBlue.withOpacity(0.25),
            borderRadius: BorderRadius.circular(6),
          ),
        );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [bar(28, false), bar(48, true), bar(28, false)],
    );
  }
}