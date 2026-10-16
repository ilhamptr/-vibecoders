import '../../../domain/money/money.dart';
import 'farmer_investment_repository.dart';

/// In-memory [FarmerInvestmentRepository] for mock mode and widget tests.
/// Items have no image URLs, so cards fall back to the bundled photo.
class FakeFarmerInvestmentRepository implements FarmerInvestmentRepository {
  FakeFarmerInvestmentRepository({
    this.latency = const Duration(milliseconds: 200),
    Map<FarmerInvestmentStatus, List<FarmerInvestment>>? data,
  }) : data = data ?? _seed();

  final Duration latency;
  final Map<FarmerInvestmentStatus, List<FarmerInvestment>> data;

  @override
  Future<List<FarmerInvestment>> getInvestments(
    FarmerInvestmentStatus status,
  ) async {
    await Future<void>.delayed(latency);
    return List.unmodifiable(data[status] ?? const []);
  }

  static Map<FarmerInvestmentStatus, List<FarmerInvestment>> _seed() => {
    FarmerInvestmentStatus.running: [
      FarmerInvestment(
        id: 'mock-investment-running',
        commodity: 'Buah',
        status: FarmerInvestmentStatus.running.apiValue,
        numberOfInvestors: 3,
        endDate: DateTime.now().add(const Duration(days: 54)),
        targetAmount: const Money(amount: 7000000),
        collectedAmount: const Money(amount: 4100000),
        roi: 242.86,
        areaName: 'Perkebunan Cabai Alam Sutera',
      ),
    ],
    FarmerInvestmentStatus.completed: [
      FarmerInvestment(
        id: 'mock-investment-completed',
        commodity: 'Padi',
        status: FarmerInvestmentStatus.completed.apiValue,
        numberOfInvestors: 12,
        endDate: DateTime(2026, 8, 1),
        targetAmount: const Money(amount: 16000000),
        collectedAmount: const Money(amount: 16000000),
        roi: 18.5,
        areaName: 'Sawah Pak Wowok',
      ),
    ],
  };
}
