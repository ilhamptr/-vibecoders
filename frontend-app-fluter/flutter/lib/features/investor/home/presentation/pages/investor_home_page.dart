import 'package:flutter/material.dart';

import '../../../../../app/router/investor_routes.dart';
import '../../../../../shared/shared.dart';
import '../../../common/investor_design.dart';
import '../../../common/status_view.dart';
import '../../../home/data/investor_fund_repository.dart';
import '../../../portfolio/data/portfolio_repository.dart';
import '../../../portfolio/presentation/state/portfolio_controller.dart';
import '../../../portfolio/presentation/widgets/investment_card.dart';
import '../../../wallet/data/wallet_topup_repository.dart';
import '../../../wallet/presentation/deposit_sheet.dart';

class InvestorHomePage extends StatefulWidget {
  const InvestorHomePage({
    super.key,
    required this.repository,
    required this.fundRepository,
    required this.walletTopUp,
    required this.onOpenPortfolio,
  });

  final PortfolioRepository repository;
  final InvestorFundRepository fundRepository;
  final WalletTopUpRepository walletTopUp;
  final VoidCallback onOpenPortfolio;

  @override
  State<InvestorHomePage> createState() => _InvestorHomePageState();
}

class _InvestorHomePageState extends State<InvestorHomePage> {
  late final PortfolioController controller = PortfolioController(
    widget.repository,
  )..load();

  /// Wallet + invested totals from `GET /investment/investment-fund`.
  /// Falls back to zeros if the call fails so the dashboard still renders.
  late Future<InvestorFund> _fund = _loadFund();

  Future<InvestorFund> _loadFund() => widget.fundRepository.getFund().catchError(
    (Object error) {
      debugPrint('InvestorHomePage: failed to load fund: $error');
      return InvestorFund.empty;
    },
  );

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _deposit() async {
    await DepositSheet.show(context, repository: widget.walletTopUp);
    // Refresh wallet/invested figures after returning from the payment flow.
    if (mounted) setState(() => _fund = _loadFund());
  }

  void _walletNotice() => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Mode simulasi'),
      content: const Text(
        'Deposit dan penarikan belum terhubung. Tidak ada uang yang dipindahkan.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Tutup'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      final items = controller.investments;
      return ListView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        children: [
          DesignCard(
            child: Column(
              children: [
                FutureBuilder<InvestorFund>(
                  future: _fund,
                  builder: (context, snapshot) {
                    final fund = snapshot.data ?? InvestorFund.empty;
                    final loading =
                        snapshot.connectionState == ConnectionState.waiting;
                    return Row(
                      children: [
                        Expanded(
                          child: _Figure(
                            'Dana Diinvestasikan',
                            loading
                                ? '…'
                                : rupiah(fund.investedFund.amount,
                                    prefix: false),
                          ),
                        ),
                        Expanded(
                          child: _Figure(
                            'Saldo Dompet',
                            loading
                                ? '…'
                                : rupiah(fund.walletBalance.amount,
                                    prefix: false),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: 'Lihat Detail Keuangan',
                  height: 34,
                  variant: AppButtonVariant.secondary,
                  borderRadius: 999,
                  onPressed: widget.onOpenPortfolio,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Deposit Dana',
                  height: 44,
                  variant: AppButtonVariant.secondary,
                  leading: const Icon(Icons.north_east, size: 16),
                  onPressed: _deposit,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: 'Tarik Dana',
                  height: 44,
                  variant: AppButtonVariant.secondary,
                  leading: const Icon(Icons.south_east, size: 16),
                  onPressed: _walletNotice,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          StatusView(
            status: controller.status,
            onRetry: controller.load,
            emptyMessage: 'Belum ada investasi. Mulai dari Pasar.',
            builder: (context) => Column(
              children: [
                for (final investment in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: InvestmentCard(
                      investment: investment,
                      showFunding: true,
                      onTap: () => Navigator.pushNamed(
                        context,
                        InvestorRoutes.portfolioProject(investment.id),
                      ),
                    ),
                  ),
                if (items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Text('Belum ada investasi.'),
                  ),
              ],
            ),
          ),
        ],
      );
    },
  );
}

class _Figure extends StatelessWidget {
  const _Figure(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(color: InvestorDesign.muted, fontSize: 12),
      ),
      const SizedBox(height: 6),
      Text(
        value,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
      ),
    ],
  );
}
