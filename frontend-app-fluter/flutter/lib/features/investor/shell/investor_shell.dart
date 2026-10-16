import 'package:flutter/material.dart';

import '../../../domain/domain.dart';
import '../../../shared/shared.dart';
import '../common/investor_design.dart';
import '../home/presentation/pages/investor_home_page.dart';
import '../investor_dependencies.dart';
import '../marketplace/presentation/pages/marketplace_page.dart';
import '../portfolio/presentation/pages/portfolio_page.dart';
import '../../profile/presentation/pages/profile_page.dart';

/// Investor navigation shell: Beranda · Pasar · Portofolio.
class InvestorShell extends StatefulWidget {
  const InvestorShell({
    super.key,
    required this.dependencies,
    this.initialIndex = 0,
  });

  final InvestorDependencies dependencies;
  final int initialIndex;

  @override
  State<InvestorShell> createState() => _InvestorShellState();
}

class _InvestorShellState extends State<InvestorShell> {
  late int index = widget.initialIndex;

  /// Fetched once per shell; the header falls back to a neutral label on error.
  late final Future<String> _fullName = widget.dependencies.profile
      .getFullName()
      .catchError((Object error) {
        debugPrint('InvestorShell: failed to load full name: $error');
        return 'Investor';
      });

  void _showReports() => showModalBottomSheet<void>(
    context: context,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Laporan', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            const Text('Belum ada laporan baru untuk investasi Anda.'),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _tab() {
    final deps = widget.dependencies;
    // Keyed so switching tabs reloads from the shared store.
    return switch (index) {
      0 => InvestorHomePage(
        key: const ValueKey('home'),
        repository: deps.portfolio,
        fundRepository: deps.fund,
        walletTopUp: deps.walletTopUp,
        onOpenPortfolio: () => setState(() => index = 2),
      ),
      1 => MarketplacePage(
        key: const ValueKey('marketplace'),
        repository: deps.marketplace,
      ),
      _ => PortfolioPage(
        key: const ValueKey('portfolio'),
        repository: deps.userInvestments,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final compact =
        MediaQuery.sizeOf(context).width < 360 ||
        MediaQuery.textScalerOf(context).scale(10) > 12;
    final navInset = compact ? 24.0 : 56.0;
    return InvestorPresentation(
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => ProfilePage(
                            role: UserRole.investor,
                            name: widget.dependencies.investor.name,
                            avatar: const AssetImage(
                              '${InvestorDesign.asset}avatar.png',
                            ),
                            onLogout: () => Navigator.of(
                              context,
                            ).popUntil((route) => route.isFirst),
                          ),
                        ),
                      ),
                      child: const AppAvatar(
                        image: AssetImage('${InvestorDesign.asset}avatar.png'),
                        size: 40,
                        borderRadius: 999,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Halo!',
                            style: TextStyle(
                              fontSize: 13,
                              color: InvestorDesign.muted,
                            ),
                          ),
                          FutureBuilder<String>(
                            future: _fullName,
                            builder: (context, snapshot) => Text(
                              snapshot.data ?? '…',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Tooltip(
                      message: 'Laporan proyek',
                      child: AppCard(
                        padding: const EdgeInsets.all(10),
                        borderRadius: 999,
                        onTap: _showReports,
                        child: const Icon(
                          Icons.description_outlined,
                          size: 20,
                          color: InvestorDesign.muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: _tab()),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(navInset, 12, navInset, 20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: DecoratedBox(
                decoration: const BoxDecoration(color: Colors.white),
                child: LayoutBuilder(
                  builder: (context, box) => Stack(
                    children: [
                      Positioned(
                        left: box.maxWidth / 3 * index + 3,
                        top: 3,
                        bottom: 3,
                        width: box.maxWidth / 3 - 6,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: const Color(0xFFE6F6FC),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      Theme(
                        data: InvestorDesign.theme(context)
                            .copyWith(dividerColor: Colors.white),
                        child: AppBottomNavigation(
                          backgroundColor: Colors.transparent,
                          height:
                              60 +
                              (MediaQuery.textScalerOf(context).scale(10) -
                                      10) *
                                  8,
                          activeColor: InvestorDesign.blue,
                          inactiveColor: InvestorDesign.muted,
                          items: const [
                            AppBottomNavItem(
                              label: 'Beranda',
                              icon: Icon(Icons.home_outlined),
                              activeIcon: Icon(Icons.home),
                            ),
                            AppBottomNavItem(
                              label: 'Pasar',
                              icon: Icon(Icons.area_chart_outlined),
                              activeIcon: Icon(Icons.area_chart),
                            ),
                            AppBottomNavItem(
                              label: 'Portofolio',
                              icon: Icon(Icons.account_balance_wallet_outlined),
                              activeIcon: Icon(Icons.account_balance_wallet),
                            ),
                          ],
                          currentIndex: index,
                          onTap: (value) => setState(() => index = value),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
