import '../money/money.dart';

class Funding {
  const Funding({
    required this.target,
    required this.collected,
    required this.investorCount,
    this.deadline,
  }) : assert(investorCount >= 0);

  final Money target;
  final Money collected;
  final int investorCount;
  final DateTime? deadline;

  double get progress {
    if (target.amount == 0) return 0;

    final raw = collected.amount / target.amount;
    return raw.clamp(0.0, 1.0);
  }

  double get percentage => progress * 100;

  bool get isFullyFunded => collected.amount >= target.amount;

  int? get daysRemaining {
    final value = deadline;
    if (value == null) return null;

    final remaining = value.difference(DateTime.now()).inDays;
    return remaining < 0 ? 0 : remaining;
  }

  Funding copyWith({
    Money? target,
    Money? collected,
    int? investorCount,
    DateTime? deadline,
  }) {
    return Funding(
      target: target ?? this.target,
      collected: collected ?? this.collected,
      investorCount: investorCount ?? this.investorCount,
      deadline: deadline ?? this.deadline,
    );
  }
}
