import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../investor/wallet/data/wallet_topup_repository.dart';
import '../common/farmer_design.dart';

/// Bottom sheet for topping up the wallet via `POST /payment/top-up-wallet`.
///
/// On success it opens the hosted `payment_link_url` in the browser and pops
/// with `true` so the caller can refresh balances. Call [FarmerDepositSheet.show].
class FarmerDepositSheet extends StatefulWidget {
  const FarmerDepositSheet({super.key, required this.repository});

  final WalletTopUpRepository repository;

  static Future<bool?> show(
    BuildContext context, {
    required WalletTopUpRepository repository,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) =>
          FarmerPresentation(child: FarmerDepositSheet(repository: repository)),
    );
  }

  @override
  State<FarmerDepositSheet> createState() => _FarmerDepositSheetState();
}

class _FarmerDepositSheetState extends State<FarmerDepositSheet> {
  final _amount = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final value = int.tryParse(_amount.text.trim());
    if (value == null || value < ApiWalletTopUpRepository.minimumAmount) {
      setState(() => _error = 'Masukkan nominal minimal Rp10.000.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await widget.repository.topUp(value);
      final opened = await launchUrl(
        Uri.parse(result.paymentLinkUrl),
        mode: LaunchMode.externalApplication,
      );
      if (!mounted) return;
      if (!opened) {
        setState(() {
          _busy = false;
          _error = 'Tidak dapat membuka halaman pembayaran.';
        });
        return;
      }
      Navigator.pop(context, true);
    } on TopUpException catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Gagal memproses deposit. Coba lagi.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 20 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Deposit Dana',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          const Text(
            'Masukkan jumlah yang ingin Anda setorkan ke dompet.',
            style: TextStyle(fontSize: 13, color: FarmerDesign.muted),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amount,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            enabled: !_busy,
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            decoration: InputDecoration(
              prefixText: 'Rp ',
              hintText: 'Masukkan nominal deposit',
              errorText: _error,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final entry in const {
                50000: '50RB',
                100000: '100RB',
                500000: '500RB',
                1000000: '1JT',
              }.entries)
                SizedBox(
                  width: 84,
                  child: FarmerButton(
                    label: entry.value,
                    onPressed: _busy
                        ? null
                        : () => _amount.text = '${entry.key}',
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Minimum deposit Rp10.000. Anda akan diarahkan ke halaman '
            'pembayaran untuk menyelesaikan transaksi.',
            style: TextStyle(fontSize: 11, color: FarmerDesign.muted),
          ),
          const SizedBox(height: 16),
          FarmerButton(
            label: 'Lanjut ke Pembayaran',
            primary: true,
            loading: _busy,
            onPressed: _busy ? null : _submit,
          ),
        ],
      ),
    );
  }
}
