import '../../../../domain/money/money.dart';

/// Cost breakdown for an investment, from
/// `GET /investment/investment-fund-details/{investment_id}`:
/// `{seedling, fertilizer, labour, others, description, total}`.
///
/// `description` explains what the `others` cost covers. By the backend's
/// contract it is only set when `others > 0`; when `others` is 0 there is
/// nothing to describe and `description` is null.
class FundBreakdown {
  const FundBreakdown({
    required this.seedling,
    required this.fertilizer,
    required this.labour,
    required this.others,
    required this.total,
    this.description,
  });

  final Money seedling;
  final Money fertilizer;
  final Money labour;
  final Money others;
  final Money total;

  /// Explanation of the `others` cost. Null when `others` is 0.
  final String? description;

  bool get hasOthers => others.amount > 0;

  /// Fixed cost lines always shown (bibit, pupuk, tenaga kerja).
  List<FundLine> get baseLines => [
    FundLine('Bibit', seedling),
    FundLine('Pupuk', fertilizer),
    FundLine('Tenaga Kerja', labour),
  ];
}

class FundLine {
  const FundLine(this.label, this.amount);

  final String label;
  final Money amount;
}
