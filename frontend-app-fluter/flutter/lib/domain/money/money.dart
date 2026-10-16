class Money {
  const Money({required this.amount, this.currency = 'IDR'})
    : assert(amount >= 0, 'Money amount cannot be negative.');

  final int amount;
  final String currency;

  static const zero = Money(amount: 0);

  Money operator +(Money other) {
    _ensureSameCurrency(other);
    return Money(amount: amount + other.amount, currency: currency);
  }

  Money operator -(Money other) {
    _ensureSameCurrency(other);
    final result = amount - other.amount;

    if (result < 0) {
      throw StateError('Money result cannot be negative.');
    }

    return Money(amount: result, currency: currency);
  }

  bool isGreaterThan(Money other) {
    _ensureSameCurrency(other);
    return amount > other.amount;
  }

  bool isGreaterThanOrEqualTo(Money other) {
    _ensureSameCurrency(other);
    return amount >= other.amount;
  }

  void _ensureSameCurrency(Money other) {
    if (currency != other.currency) {
      throw ArgumentError(
        'Cannot operate on different currencies: '
        '$currency and ${other.currency}.',
      );
    }
  }

  @override
  bool operator ==(Object other) {
    return other is Money &&
        other.amount == amount &&
        other.currency == currency;
  }

  @override
  int get hashCode => Object.hash(amount, currency);

  @override
  String toString() => '$currency $amount';
}
