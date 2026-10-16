import 'package:flutter/material.dart';

import '../../../app/router/app_router.dart';
import '../../auth/auth_session_manager.dart';
import '../../../domain/domain.dart';
import '../common/farmer_design.dart';
import '../data/farmer_repository.dart';
import '../data/farmer_fund_repository.dart';
import '../data/farmer_investment_repository.dart';
import '../../investor/wallet/data/wallet_topup_repository.dart';
import '../dashboard/presentation/pages/farmer_dashboard_page.dart';
import '../proposal/presentation/pages/proposal_list_page.dart';
import '../proposal/presentation/pages/proposal_wizard_page.dart';
import '../../profile/presentation/pages/profile_page.dart';

class FarmerShell extends StatefulWidget {
  const FarmerShell({
    super.key,
    required this.repository,
    required this.fundRepository,
    required this.walletTopUp,
    required this.investmentRepository,
    this.initialIndex = 0,
  });
  final FarmerRepository repository;
  final FarmerFundRepository fundRepository;
  final WalletTopUpRepository walletTopUp;
  final FarmerInvestmentRepository investmentRepository;
  final int initialIndex;
  @override
  State<FarmerShell> createState() => _FarmerShellState();
}

class _FarmerShellState extends State<FarmerShell> {
  late int selected = widget.initialIndex;
  Future<void> _create() async {
    final sent = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ProposalWizardPage(repository: widget.repository),
      ),
    );
    if (sent == true && mounted) setState(() => selected = 1);
  }

  void _activities() => showModalBottomSheet<void>(
    context: context,
    builder: (context) => FarmerPresentation(
      child: SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Aktivitas Proyek',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            if (widget.repository.activities.isEmpty)
              const Text('Belum ada update atau laporan yang dikirim.'),
            for (final a in widget.repository.activities)
              ListTile(
                title: Text(a.text),
                subtitle: Text(
                  '${a.report ? 'Laporan' : 'Update'} • ${farmerDate(a.createdAt)}',
                ),
                leading: Icon(
                  a.report
                      ? Icons.description_outlined
                      : Icons.chat_bubble_outline,
                ),
              ),
          ],
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => FarmerPresentation(
    child: Scaffold(
      body: SafeArea(
        bottom: false,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => ProfilePage(
                              role: UserRole.farmer,
                              name: widget.repository.farmer.name,
                              avatar: const AssetImage(
                                '${FarmerDesign.asset}avatar.png',
                              ),
                              onLogout: () {
                                AuthSessionManager.instance.clear();
                                Navigator.of(context).pushNamedAndRemoveUntil(
                                  AppRouter.onboarding,
                                  (route) => false,
                                );
                              },
                            ),
                          ),
                        ),
                        child: const CircleAvatar(
                          radius: 22,
                          backgroundColor: Color(0xFFF0F0F0),
                          backgroundImage: AssetImage(
                            '${FarmerDesign.asset}avatar.png',
                          ),
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
                                color: FarmerDesign.muted,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.repository.farmer.name,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                      IconButton.filledTonal(
                        onPressed: _activities,
                        tooltip: 'Aktivitas proyek',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: FarmerDesign.muted,
                          minimumSize: const Size(44, 44),
                        ),
                        icon: const Icon(Icons.description_outlined),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: IndexedStack(
                    index: selected,
                    children: [
                      FarmerDashboardPage(
                        repository: widget.repository,
                        fundRepository: widget.fundRepository,
                        walletTopUp: widget.walletTopUp,
                        investmentRepository: widget.investmentRepository,
                      ),
                      ProposalListPage(repository: widget.repository),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 260),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: FarmerDesign.line),
                    ),
                    child: Row(
                      children: [
                        _nav(0, 'Beranda', Icons.home_outlined, Icons.home),
                        _nav(
                          1,
                          'Proposal',
                          Icons.description_outlined,
                          Icons.description,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 56,
                height: 56,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [FarmerDesign.blue, Color(0xFF2D84B7)],
                    ),
                  ),
                  child: IconButton(
                    onPressed: _create,
                    tooltip: 'Buat Proposal',
                    icon: const Icon(Icons.add, color: Colors.white, size: 28),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  Widget _nav(int i, String label, IconData icon, IconData active) => Expanded(
    child: Material(
      color: selected == i ? const Color(0xFFE6F6FC) : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => setState(() => selected = i),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected == i ? active : icon,
                color: selected == i
                    ? FarmerDesign.blueInk
                    : FarmerDesign.muted,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: selected == i
                      ? FarmerDesign.blueInk
                      : FarmerDesign.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
