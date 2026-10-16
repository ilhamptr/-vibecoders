import '../money/money.dart';
import '../project/agriculture_project.dart';
import '../user/user.dart';
import 'investment_status.dart';

class Investment {
  const Investment({
    required this.id,
    required this.investor,
    required this.project,
    required this.principal,
    required this.status,
    required this.investedAt,
    this.estimatedReturn,
    this.realizedReturn,
  });

  final String id;
  final User investor;
  final AgricultureProject project;
  final Money principal;
  final InvestmentStatus status;
  final DateTime investedAt;
  final Money? estimatedReturn;
  final Money? realizedReturn;

  bool get isActive => status == InvestmentStatus.active;

  Investment copyWith({
    String? id,
    User? investor,
    AgricultureProject? project,
    Money? principal,
    InvestmentStatus? status,
    DateTime? investedAt,
    Money? estimatedReturn,
    Money? realizedReturn,
  }) {
    return Investment(
      id: id ?? this.id,
      investor: investor ?? this.investor,
      project: project ?? this.project,
      principal: principal ?? this.principal,
      status: status ?? this.status,
      investedAt: investedAt ?? this.investedAt,
      estimatedReturn: estimatedReturn ?? this.estimatedReturn,
      realizedReturn: realizedReturn ?? this.realizedReturn,
    );
  }
}
