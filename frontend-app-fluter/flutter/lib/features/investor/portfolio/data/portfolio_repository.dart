import '../../../../domain/domain.dart';

abstract interface class PortfolioRepository {
  Future<List<Investment>> getInvestments({InvestmentStatus? status});

  Future<Investment?> getInvestmentById(String investmentId);
}
