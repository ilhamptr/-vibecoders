import '../../../../domain/domain.dart';

abstract interface class InvestmentRepository {
  Future<Investment> createInvestment({
    required User investor,
    required String projectId,
    required Money amount,
  });
}
