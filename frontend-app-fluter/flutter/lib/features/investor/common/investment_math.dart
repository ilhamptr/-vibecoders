import '../../../domain/domain.dart';

const _monthNames = [
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

/// Principal plus the project's minimum ROI. Display estimate only.
Money estimatedReturnFor(AgricultureProject project, Money principal) => Money(
  amount: (principal.amount * (1 + project.roiMinPercent / 100)).round(),
  currency: principal.currency,
);

String harvestLabel(int months, {DateTime? from}) {
  final now = from ?? DateTime.now();
  final date = DateTime(now.year, now.month + months, now.day);
  return '${_monthNames[date.month - 1]} ${date.year} ($months Bulan)';
}

abstract final class InvestmentAmountValidator {
  static const minimum = 100000;

  static int remaining(AgricultureProject project) {
    final left =
        project.funding.target.amount - project.funding.collected.amount;
    return left < 0 ? 0 : left;
  }

  static String _rupiah(int amount) => 'Rp${amount.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]}.',
  )}';

  /// Returns an error message, or null when [text] is a valid amount.
  ///
  /// [minimum] is the smallest allowed amount. When [requireOpenFunding] is
  /// true the project must be open for funding and the amount must not exceed
  /// the remaining target (marketplace flow). The real-backend invest flow
  /// sets it false and lets the server enforce eligibility.
  static String? validate(
    String text,
    AgricultureProject project, {
    int minimum = InvestmentAmountValidator.minimum,
    bool requireOpenFunding = true,
  }) {
    if (requireOpenFunding && !project.isOpenForInvestment) {
      return 'Proyek ini tidak sedang membuka pendanaan.';
    }
    final value = int.tryParse(text.trim());
    if (value == null || value < minimum) {
      return 'Masukkan nominal bulat minimal ${_rupiah(minimum)}.';
    }
    if (requireOpenFunding && value > remaining(project)) {
      return 'Nominal melebihi sisa pendanaan proyek.';
    }
    return null;
  }
}
