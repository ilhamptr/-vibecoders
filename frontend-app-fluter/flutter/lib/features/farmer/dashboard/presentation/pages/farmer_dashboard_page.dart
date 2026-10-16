import 'package:flutter/material.dart';

import '../../../../../domain/domain.dart';
import '../../../common/farmer_design.dart';
import '../../../data/farmer_repository.dart';
import '../../../data/farmer_fund_repository.dart';
import '../../../data/farmer_investment_repository.dart';
import '../../../../investor/wallet/data/wallet_topup_repository.dart';
import '../../../activity/farmer_activity_page.dart';
import '../../../wallet/farmer_wallet_page.dart';
import '../../../wallet/farmer_deposit_sheet.dart';

class FarmerDashboardPage extends StatefulWidget {
  const FarmerDashboardPage({
    super.key,
    required this.repository,
    required this.fundRepository,
    required this.walletTopUp,
    required this.investmentRepository,
  });
  final FarmerRepository repository;
  final FarmerFundRepository fundRepository;
  final WalletTopUpRepository walletTopUp;
  final FarmerInvestmentRepository investmentRepository;
  @override
  State<FarmerDashboardPage> createState() => _FarmerDashboardPageState();
}

class _FarmerDashboardPageState extends State<FarmerDashboardPage> {
  /// Tabs map 1:1 to the backend `investment_status` filter.
  static const _tabs = FarmerInvestmentStatus.values;

  int selected = 0;
  bool withdrawableVisible = true;
  bool totalVisible = true;

  /// Wallet totals from `GET /investment/get-farmer-fund`.
  /// Falls back to zeros if the call fails so the dashboard still renders.
  late Future<FarmerFund> _fund = _loadFund();

  /// Projects from `GET /investment/get-farmers-investments` for the
  /// selected tab.
  late Future<List<FarmerInvestment>> _investments = _loadInvestments();

  FarmerInvestmentStatus get _status => _tabs[selected];

  @override
  void initState() {
    super.initState();
    // A newly submitted proposal notifies the repository; refetch the list.
    widget.repository.addListener(_reloadInvestments);
  }

  @override
  void dispose() {
    widget.repository.removeListener(_reloadInvestments);
    super.dispose();
  }

  Future<FarmerFund> _loadFund() =>
      widget.fundRepository.getFund().catchError((Object error) {
        debugPrint('FarmerDashboardPage: failed to load fund: $error');
        return FarmerFund.empty;
      });

  Future<List<FarmerInvestment>> _loadInvestments() =>
      widget.investmentRepository.getInvestments(_status);

  void _reloadInvestments() {
    if (!mounted) return;
    setState(() {
      _investments = _loadInvestments();
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _fund = _loadFund();
      _investments = _loadInvestments();
    });
    await Future.wait<Object?>([
      _fund,
      _investments.catchError((Object _) => <FarmerInvestment>[]),
    ]);
  }

  Future<void> _wallet([bool? deposit]) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => FarmerWalletPage(
          repository: widget.repository,
          initialDeposit: deposit,
        ),
      ),
    );
    // Refresh the withdrawable balance after any deposit/withdrawal.
    if (!mounted) return;
    setState(() {
      _fund = _loadFund();
    });
  }

  /// Deposit via `POST /payment/top-up-wallet`, then refresh the balance.
  Future<void> _deposit() async {
    final ok = await FarmerDepositSheet.show(
      context,
      repository: widget.walletTopUp,
    );
    if (ok != true || !mounted) return;
    setState(() {
      _fund = _loadFund();
    });
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: _refresh,
    child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      children: [
        FarmerCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              FutureBuilder<FarmerFund>(
                future: _fund,
                builder: (context, snapshot) {
                  final fund = snapshot.data ?? FarmerFund.empty;
                  final loading =
                      snapshot.connectionState == ConnectionState.waiting;
                  return Row(
                    children: [
                      Expanded(
                        child: _balance(
                          'Dana Investor',
                          fund.amountToWithdraw,
                          withdrawableVisible,
                          () => setState(
                            () => withdrawableVisible = !withdrawableVisible,
                          ),
                          FarmerDesign.gold,
                          loading: loading,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _balance(
                          'Saldo Wallet',
                          fund.walletBalance,
                          totalVisible,
                          () => setState(() => totalVisible = !totalVisible),
                          FarmerDesign.muted,
                          loading: loading,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),
              FarmerButton(
                label: 'Lihat Detail Keuangan',
                onPressed: () => _wallet(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: FarmerButton(
                label: 'Deposit Dana',
                icon: Icons.north_east,
                onPressed: _deposit,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FarmerButton(
                label: 'Tarik Dana',
                icon: Icons.south_east,
                onPressed: () => _wallet(false),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FarmerTabs(
          labels: [for (final s in _tabs) s.apiValue],
          selected: selected,
          onChanged: (value) {
            if (value == selected) return;
            setState(() {
              selected = value;
              _investments = _loadInvestments();
            });
          },
        ),
        const SizedBox(height: 12),
        FutureBuilder<List<FarmerInvestment>>(
          future: _investments,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              debugPrint(
                'FarmerDashboardPage: failed to load investments: '
                '${snapshot.error}',
              );
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'Gagal memuat proyek. Periksa koneksi lalu coba lagi.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FarmerButton(
                      label: 'Coba Lagi',
                      icon: Icons.refresh,
                      onPressed: _reloadInvestments,
                    ),
                  ],
                ),
              );
            }
            final items = snapshot.data ?? const <FarmerInvestment>[];
            if (items.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Belum ada proyek pada tahap ini.',
                  textAlign: TextAlign.center,
                ),
              );
            }
            return Column(
              children: [
                for (final item in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _card(item),
                  ),
              ],
            );
          },
        ),
      ],
    ),
  );

  Widget _card(FarmerInvestment item) {
    final running = _status == FarmerInvestmentStatus.running;
    final days = item.daysRemaining;
    return FarmerCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FarmPhoto(url: item.images.isEmpty ? null : item.images.first),
          const SizedBox(height: 10),
          Text(
            item.areaName.isEmpty ? 'Lahan tanpa nama' : item.areaName,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _stat(
                  'Komoditas',
                  item.commodity.isEmpty ? '-' : item.commodity,
                  FarmerDesign.cyan,
                  FarmerDesign.blueInk,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _stat(
                  'Estimasi ROI',
                  '${farmerNumber(double.parse(item.roi.toStringAsFixed(2)))}%',
                  FarmerDesign.yellow,
                  FarmerDesign.gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _stat(
                  'Investor Saat Ini',
                  '${item.numberOfInvestors}',
                  FarmerDesign.cyan,
                  FarmerDesign.blueInk,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _stat(
                  'Sisa Waktu',
                  days == null ? '-' : '$days Hari',
                  FarmerDesign.yellow,
                  FarmerDesign.gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: item.progress,
              minHeight: 8,
              color: FarmerDesign.blue,
              backgroundColor: FarmerDesign.line,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${farmerRupiah(item.collectedAmount.amount, prefix: false)} / '
                  '${farmerRupiah(item.targetAmount.amount, prefix: false)}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(item.progress * 100).round()}%',
                style: const TextStyle(color: FarmerDesign.muted, fontSize: 12),
              ),
            ],
          ),
          if (item.endDate != null) ...[
            const SizedBox(height: 12),
            FarmerTint(
              color: FarmerDesign.yellow,
              child: Row(
                children: [
                  const Icon(
                    Icons.schedule,
                    color: FarmerDesign.gold,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Tanggal Selesai',
                      style: TextStyle(color: FarmerDesign.gold),
                    ),
                  ),
                  Flexible(
                    child: Text(
                      farmerDate(item.endDate!),
                      textAlign: TextAlign.end,
                      style: const TextStyle(color: FarmerDesign.gold),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (running) ...[
            const SizedBox(height: 10),
            FarmerButton(
              label: 'Kirim Update',
              icon: Icons.chat_bubble_outline,
              onPressed: () => _activity(item, false),
            ),
            const SizedBox(height: 10),
            FarmerButton(
              label: 'Kirim Laporan',
              icon: Icons.description_outlined,
              onPressed: () => _activity(item, true),
            ),
          ],
        ],
      ),
    );
  }

  void _activity(FarmerInvestment item, bool report) => Navigator.push(
    context,
    MaterialPageRoute<void>(
      builder: (_) => FarmerActivityPage(
        repository: widget.repository,
        project: item.toProject(widget.repository.farmer),
        report: report,
      ),
    ),
  );

  Widget _balance(
    String label,
    Money amount,
    bool visible,
    VoidCallback toggle,
    Color color, {
    bool loading = false,
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Flexible(
            child: Text(label, style: TextStyle(fontSize: 13, color: color)),
          ),
          IconButton(
            onPressed: toggle,
            tooltip: visible ? 'Sembunyikan $label' : 'Tampilkan $label',
            icon: Icon(
              visible
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              size: 16,
            ),
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
      Text(
        !visible
            ? '••••••••'
            : loading
            ? '…'
            : farmerRupiah(amount.amount, prefix: false),
        style: const TextStyle(fontSize: 23),
      ),
    ],
  );

  Widget _stat(String label, String value, Color color, Color ink) =>
      FarmerTint(
        color: color,
        child: Column(
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: ink),
            ),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 19, color: ink)),
          ],
        ),
      );
}
