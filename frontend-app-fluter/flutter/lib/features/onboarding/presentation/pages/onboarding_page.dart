import 'package:flutter/material.dart';

import '../../../../app/router/app_router.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../auth/presentation/pages/login_page.dart';
import '../../../onboarding/role_selection/role_selection.dart';
import '../widgets/onboarding_slide.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  static const _primaryBlue = Color(0xFF319AC9);
  final _pageController = PageController();
  int _page = 0;

  static final _slides = [
    OnboardingSlideData(
      card: _planCard(),
      title: 'Wujudkan Rencana Tanam',
      description: 'Susun kebutuhan dana dan rencana\npertanian dengan langkah yang mudah',
    ),
    OnboardingSlideData(
      card: _projectCard(),
      title: 'Dukung Pertanian Berkelanjutan',
      description: 'Temukan proyek petani dengan tujuan,\nanggaran, dan risiko yang transparan.',
    ),
    OnboardingSlideData(
      card: _fundingCard(),
      title: 'Ikuti Setiap Perkembangan',
      description: 'Lihat kabar dari lahan, penggunaan dana,\nhingga hasil panen secara terbuka.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        settings: const RouteSettings(name: '/onboarding/select-role'),
        builder: (roleContext) => RoleSelectionPage(
          onContinue: (role) =>
              Navigator.of(roleContext)
                  .pushNamed('/auth/register', arguments: role),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0, .52, .72],
            colors: [Color(0xFF91DDED), Color(0xFF43B5DF), Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (value) => setState(() => _page = value),
                  itemBuilder: (_, index) =>
                      OnboardingSlide(data: _slides[index]),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slides.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: 7,
                    height: index == _page ? 24 : 18,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: index == _page
                          ? _primaryBlue
                          : const Color(0xFFCDECF6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 58),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: AppButton(
                  label: 'Jadi Investor/Petani',
                  height: 44,
                  borderRadius: 11,
                  backgroundColor: _primaryBlue,
                  foregroundColor: Colors.white,
                  onPressed: _next,
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: GestureDetector(
                  key: const Key('onboarding-login'),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          LoginPage(repository: AppRouter.loginRepository),
                    ),
                  ),
                  child: const Text.rich(
                    TextSpan(
                      text: 'Sudah Memiliki Akun? ',
                      style: TextStyle(color: Color(0xFF969696), fontSize: 14),
                      children: [
                        TextSpan(
                          text: 'Login',
                          style: TextStyle(
                            color: Color(0xFF168BC4),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _card({
    required Widget child,
    double rotation = 0,
    Color color = Colors.white,
  }) {
    return Transform.rotate(
      angle: rotation,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .14),
              blurRadius: 12,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: child,
      ),
    );
  }

  static Widget _planCard() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 18,
          right: 18,
          top: 280,
          child: Opacity(
            opacity: 1,
            child: _card(
              color: const Color(0xFFEAF8FC),
              child: SizedBox(
                height: 128,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(
                    'assets/investor/design/chili.png',
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 4,
          right: 4,
          top: 200,
          child: Opacity(
            opacity: 1,
            child: _card(
              color: const Color(0xFFD9F2F8),
              child: SizedBox(
                height: 150,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Identifikasi Risiko', style: _cardTitle),
                    const Spacer(),
                    _editButton(),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: _card(
            rotation: -.04,
            child: SizedBox(
              height: 275,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Rencana Komoditas', style: _cardTitle),
                  const SizedBox(height: 12),
                  const _LabelValue(label: 'Komoditas', value: 'Padi'),
                  const _LabelValue(
                    label: 'Estimasi Hasil Panen',
                    value: '7 Ton',
                  ),
                  const _LabelValue(
                    label: 'Estimasi Penjualan Panen',
                    value: '2.500.000 / Ton',
                  ),
                  const _LabelValue(
                    label: 'Estimasi Waktu Panen',
                    value: 'Agustus 2026 (4 Bulan)',
                  ),
                  const Spacer(),
                  _editButton(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  static Widget _projectCard() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 34,
          right: 34,
          top: 204,
          child: Opacity(opacity: 1, child: _projectProgressLayer()),
        ),
        Positioned(
          left: 26,
          right: 26,
          top: 158,
          child: Opacity(opacity: 1, child: _projectProgressLayer()),
        ),
        Positioned(
          left: 18,
          right: 18,
          top: 108,
          child: Opacity(opacity: 1, child: _projectProgressLayer()),
        ),
        Positioned(
          left: 10,
          right: 10,
          top: 72,
          child: Opacity(opacity: 1, child: _projectProgressLayer()),
        ),
        _card(
          child: SizedBox(
            height: 245,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Image.asset(
                    'assets/investor/design/chili.png',
                    height: 87,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 10),
                const Text('Perkebunan Cabai Alam Sutera', style: _cardTitle),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFA),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Asep Suwanto  ✓',
                    style: TextStyle(color: Color(0xFF6A777B), fontSize: 9),
                  ),
                ),
                const Spacer(),
                const Row(
                  children: [
                    Expanded(
                      child: _Stat(
                        label: 'Perkiraan ROI',
                        value: '15-20%',
                        color: Color(0xFFDDF6D8),
                      ),
                    ),
                    SizedBox(width: 7),
                    Expanded(
                      child: _Stat(
                        label: 'Panen Setiap',
                        value: '4 Bulan',
                        color: Color(0xFFC9F1FB),
                      ),
                    ),
                    SizedBox(width: 7),
                    Expanded(
                      child: _Stat(
                        label: 'Sisa Waktu',
                        value: '12 Hari',
                        color: Color(0xFFFFF4CC),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const LinearProgressIndicator(
                  value: .72,
                  minHeight: 3,
                  color: Color(0xFF42A9D3),
                  backgroundColor: Color(0xFFE4EEF0),
                ),
                const SizedBox(height: 5),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('53 Investor', style: _smallText),
                    Text('< 50JT • 72%', style: _smallText),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static Widget _projectProgressLayer() => _card(
    color: const Color(0xFFD8F2FA),
    child: SizedBox(
      height: 170,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('53 Investor', style: _smallText),
          const Spacer(),
          const LinearProgressIndicator(
            value: .72,
            minHeight: 3,
            color: Color(0xFF42A9D3),
            backgroundColor: Color(0xFFE4EEF0),
          ),
          const SizedBox(height: 8),
          const Text('< 50JT • 72%', style: _smallText),
        ],
      ),
    ),
  );

  static Widget _fundingCard() {
    return _fixedFundingCard();
  }

  static Widget _fixedFundingCard() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 36,
          right: 36,
          top: 192,
          child: _card(
            child: SizedBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Dana Terkumpul', style: _cardTitle),
                  const SizedBox(height: 6),
                  const Text.rich(
                    TextSpan(
                      text: '111.000.000 ',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                      children: [
                        TextSpan(
                          text: '/ 150.000.000',
                          style: TextStyle(
                            color: Color(0xFF999999),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  const LinearProgressIndicator(
                    value: .74,
                    minHeight: 4,
                    color: Color(0xFF319AC9),
                    backgroundColor: Color(0xFFE1EDF0),
                  ),
                  const SizedBox(height: 5),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('53 Investor', style: _smallText),
                      Text('< 50JT • 72%', style: _smallText),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const _WideStat(
                    label: 'Sisa Waktu',
                    value: '12 Hari',
                    color: Color(0xFFFFF4CC),
                  ),
                  const SizedBox(height: 5),
                  const Row(
                    children: [
                      Expanded(
                        child: _Stat(
                          label: 'Perkiraan ROI',
                          value: '15-20%',
                          color: Color(0xFFDDF6D8),
                        ),
                      ),
                      SizedBox(width: 7),
                      Expanded(
                        child: _Stat(
                          label: 'Risiko',
                          value: 'Sedang',
                          color: Color(0xFFFFF0C7),
                        ),
                      ),
                      SizedBox(width: 7),
                      Expanded(
                        child: _Stat(
                          label: 'Panen Setiap',
                          value: '4 Bulan',
                          color: Color(0xFFC9F1FB),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 24,
          right: 24,
          top: 128,
          child: _card(
            child: SizedBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Dana Terkumpul', style: _cardTitle),
                  const SizedBox(height: 6),
                  const Text.rich(
                    TextSpan(
                      text: '111.000.000 ',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                      children: [
                        TextSpan(
                          text: '/ 150.000.000',
                          style: TextStyle(
                            color: Color(0xFF999999),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  const LinearProgressIndicator(
                    value: .74,
                    minHeight: 4,
                    color: Color(0xFF319AC9),
                    backgroundColor: Color(0xFFE1EDF0),
                  ),
                  const SizedBox(height: 5),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('53 Investor', style: _smallText),
                      Text('< 50JT • 72%', style: _smallText),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const _WideStat(
                    label: 'Sisa Waktu',
                    value: '12 Hari',
                    color: Color(0xFFFFF4CC),
                  ),
                  const SizedBox(height: 5),
                  const Row(
                    children: [
                      Expanded(
                        child: _Stat(
                          label: 'Perkiraan ROI',
                          value: '15-20%',
                          color: Color(0xFFDDF6D8),
                        ),
                      ),
                      SizedBox(width: 7),
                      Expanded(
                        child: _Stat(
                          label: 'Risiko',
                          value: 'Sedang',
                          color: Color(0xFFFFF0C7),
                        ),
                      ),
                      SizedBox(width: 7),
                      Expanded(
                        child: _Stat(
                          label: 'Panen Setiap',
                          value: '4 Bulan',
                          color: Color(0xFFC9F1FB),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 12,
          right: 12,
          top: 64,
          child: _card(
            child: SizedBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Dana Terkumpul', style: _cardTitle),
                  const SizedBox(height: 6),
                  const Text.rich(
                    TextSpan(
                      text: '111.000.000 ',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                      children: [
                        TextSpan(
                          text: '/ 150.000.000',
                          style: TextStyle(
                            color: Color(0xFF999999),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  const LinearProgressIndicator(
                    value: .74,
                    minHeight: 4,
                    color: Color(0xFF319AC9),
                    backgroundColor: Color(0xFFE1EDF0),
                  ),
                  const SizedBox(height: 5),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('53 Investor', style: _smallText),
                      Text('< 50JT • 72%', style: _smallText),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const _WideStat(
                    label: 'Sisa Waktu',
                    value: '12 Hari',
                    color: Color(0xFFFFF4CC),
                  ),
                  const SizedBox(height: 5),
                  const Row(
                    children: [
                      Expanded(
                        child: _Stat(
                          label: 'Perkiraan ROI',
                          value: '15-20%',
                          color: Color(0xFFDDF6D8),
                        ),
                      ),
                      SizedBox(width: 7),
                      Expanded(
                        child: _Stat(
                          label: 'Risiko',
                          value: 'Sedang',
                          color: Color(0xFFFFF0C7),
                        ),
                      ),
                      SizedBox(width: 7),
                      Expanded(
                        child: _Stat(
                          label: 'Panen Setiap',
                          value: '4 Bulan',
                          color: Color(0xFFC9F1FB),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: _card(
            child: SizedBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Dana Terkumpul', style: _cardTitle),
                  const SizedBox(height: 6),
                  const Text.rich(
                    TextSpan(
                      text: '111.000.000 ',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                      children: [
                        TextSpan(
                          text: '/ 150.000.000',
                          style: TextStyle(
                            color: Color(0xFF999999),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  const LinearProgressIndicator(
                    value: .74,
                    minHeight: 4,
                    color: Color(0xFF319AC9),
                    backgroundColor: Color(0xFFE1EDF0),
                  ),
                  const SizedBox(height: 5),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('53 Investor', style: _smallText),
                      Text('< 50JT • 72%', style: _smallText),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const _WideStat(
                    label: 'Sisa Waktu',
                    value: '12 Hari',
                    color: Color(0xFFFFF4CC),
                  ),
                  const SizedBox(height: 5),
                  const Row(
                    children: [
                      Expanded(
                        child: _Stat(
                          label: 'Perkiraan ROI',
                          value: '15-20%',
                          color: Color(0xFFDDF6D8),
                        ),
                      ),
                      SizedBox(width: 7),
                      Expanded(
                        child: _Stat(
                          label: 'Risiko',
                          value: 'Sedang',
                          color: Color(0xFFFFF0C7),
                        ),
                      ),
                      SizedBox(width: 7),
                      Expanded(
                        child: _Stat(
                          label: 'Panen Setiap',
                          value: '4 Bulan',
                          color: Color(0xFFC9F1FB),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  static Widget _usageRow(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        Expanded(child: Text(label, style: TextStyle(fontSize: 10))),
        Text(value, style: TextStyle(fontSize: 10)),
      ],
    ),
  );

  static Widget _editButton() => Container(
    height: 30,
    decoration: BoxDecoration(
      color: const Color(0xFFEAF6FA),
      borderRadius: BorderRadius.circular(18),
    ),
    child: const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.edit_outlined, size: 14),
        SizedBox(width: 7),
        Text('Edit', style: TextStyle(fontSize: 13)),
      ],
    ),
  );
}

const _cardTitle = TextStyle(
  color: Color(0xFF20252B),
  fontSize: 15,
  fontWeight: FontWeight.w600,
);

class _UsageBar extends StatelessWidget {
  const _UsageBar();

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(4),
    child: const SizedBox(
      height: 6,
      child: Row(
        children: [
          Expanded(flex: 30, child: ColoredBox(color: Color(0xFF319AC9))),
          Expanded(flex: 25, child: ColoredBox(color: Color(0xFFFFC857))),
          Expanded(flex: 20, child: ColoredBox(color: Color(0xFF72C98D))),
          Expanded(flex: 25, child: ColoredBox(color: Color(0xFFE58A8A))),
        ],
      ),
    ),
  );
}

const _smallText = TextStyle(color: Color(0xFF999999), fontSize: 11);

class _LabelValue extends StatelessWidget {
  const _LabelValue({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF999999), fontSize: 11),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    ),
  );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 7),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(11),
    ),
    child: Column(
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 9, color: Color(0xFF4E6974)),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: Color(0xFF198BC1)),
        ),
      ],
    ),
  );
}

class _WideStat extends StatelessWidget {
  const _WideStat({
    required this.label,
    required this.value,
    required this.color,
  });
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    height: 30,
    padding: const EdgeInsets.symmetric(horizontal: 10),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(11),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Color(0xFF8D721F)),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 12, color: Color(0xFFBD8A00)),
        ),
      ],
    ),
  );
}
