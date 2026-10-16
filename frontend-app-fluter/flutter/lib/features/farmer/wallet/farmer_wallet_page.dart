import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../domain/money/money.dart';
import '../common/farmer_design.dart';
import '../data/farmer_repository.dart';

/// The PDF only supplies finance entry points; this detail view is inferred.
class FarmerWalletPage extends StatefulWidget {
  const FarmerWalletPage({
    super.key,
    required this.repository,
    this.initialDeposit,
  });
  final FarmerRepository repository;
  final bool? initialDeposit;
  @override
  State<FarmerWalletPage> createState() => _FarmerWalletPageState();
}

class _FarmerWalletPageState extends State<FarmerWalletPage> {
  final amount = TextEditingController();
  late bool? deposit = widget.initialDeposit;
  bool busy = false;
  String? error;
  @override
  void dispose() {
    amount.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final value = int.tryParse(amount.text) ?? 0;
    if (value <= 0) {
      setState(() => error = 'Masukkan nominal yang valid.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.repository.transact(
        deposit: deposit!,
        amount: Money(amount: value),
      );
      if (!mounted) return;
      amount.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaksi demo berhasil dicatat.')),
      );
    } catch (e) {
      if (mounted) {
        setState(
          () => error = e is StateError
              ? e.message
              : 'Transaksi belum dapat diproses.',
        );
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.repository,
    builder: (context, _) => FarmerPage(
      title: 'Detail Keuangan',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          FarmerCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FarmerInfo(
                  label: 'Total Dana',
                  value: farmerRupiah(widget.repository.balance.amount),
                ),
                FarmerInfo(
                  label: 'Dana Tertunda',
                  value: farmerRupiah(widget.repository.pendingBalance.amount),
                ),
                FarmerInfo(
                  label: 'Saldo Tersedia',
                  value: farmerRupiah(
                    widget.repository.balance.amount -
                        widget.repository.pendingBalance.amount,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Keuangan demo • Tidak ada uang yang dipindahkan.',
            style: TextStyle(color: FarmerDesign.muted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          FarmerTabs(
            labels: const ['Deposit Dana', 'Tarik Dana'],
            selected: deposit == false ? 1 : 0,
            onChanged: (i) => setState(() {
              deposit = i == 0;
              error = null;
            }),
          ),
          const SizedBox(height: 16),
          if (deposit != null) ...[
            TextField(
              controller: amount,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Nominal',
                prefixText: 'Rp ',
              ),
            ),
            const SizedBox(height: 16),
            FarmerButton(
              label: deposit! ? 'Deposit Dana' : 'Tarik Dana',
              primary: true,
              loading: busy,
              onPressed: busy ? null : _submit,
            ),
          ],
          if (error != null)
            Text(error!, style: const TextStyle(color: FarmerDesign.red)),
          const SizedBox(height: 16),
          Text(
            'Riwayat Transaksi',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          if (widget.repository.transactions.isEmpty)
            const Text('Belum ada transaksi dalam sesi ini.'),
          for (final t in widget.repository.transactions)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(t.deposit ? 'Deposit Dana' : 'Tarik Dana'),
              subtitle: Text(farmerDate(t.createdAt)),
              trailing: Text(farmerRupiah(t.amount.amount)),
            ),
        ],
      ),
    ),
  );
}
