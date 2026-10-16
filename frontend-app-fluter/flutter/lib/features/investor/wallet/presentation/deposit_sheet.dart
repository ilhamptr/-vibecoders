import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../shared/shared.dart';
import '../../common/investor_design.dart';
import '../data/wallet_topup_repository.dart';

/// Bottom sheet for topping up the wallet via `/payment/top-up-wallet`.
///
/// On success it opens the hosted `payment_link_url` in the browser and pops.
/// Call [DepositSheet.show] to present it.
class DepositSheet extends StatefulWidget {
  const DepositSheet({super.key, required this.repository});

  final WalletTopUpRepository repository;

  static Future<void> show(
    BuildContext context, {
    required WalletTopUpRepository repository,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DepositSheet(repository: repository),
    );
  }

  @override
  State<DepositSheet> createState() => _DepositSheetState();
}

class _DepositSheetState extends State<DepositSheet> {
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
      Navigator.pop(context);
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
            style: TextStyle(fontSize: 13, color: InvestorDesign.muted),
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
                  child: AppButton(
                    label: entry.value,
                    height: 36,
                    variant: AppButtonVariant.secondary,
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
            style: TextStyle(fontSize: 11, color: InvestorDesign.muted),
          ),
          const SizedBox(height: 16),
          AppButton(
            label: 'Lanjut ke Pembayaran',
            backgroundColor: InvestorDesign.blue,
            foregroundColor: Colors.white,
            isLoading: _busy,
            onPressed: _busy ? null : _submit,
          ),
        ],
      ),
    );
  }
}
