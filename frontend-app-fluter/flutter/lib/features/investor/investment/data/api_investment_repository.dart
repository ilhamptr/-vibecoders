import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/api_response.dart';
import '../../../../domain/domain.dart';
import 'investment_repository.dart';

/// Creates an investment through `POST /investment/invest/{investment_id}`.
///
/// Request body: `{"amount": <int, min 10000>}`.
/// Response: `{"id", "amount", "investment_id", "created_at"}`.
///
/// Here [projectId] is the backend's `investment_id` (the funding/land id the
/// detail page was opened with). The response carries no project data, so the
/// returned [Investment] uses a lightweight placeholder project; the success
/// screen only needs the principal, and the portfolio reloads fresh afterward.
class ApiInvestmentRepository implements InvestmentRepository {
  const ApiInvestmentRepository(this._api);

  final ApiClient _api;

  /// Backend minimum per the invest contract.
  static const minimumAmount = 10000;

  static const _ngrokHeaders = <String, String>{
    'ngrok-skip-browser-warning': 'true',
  };

  @override
  Future<Investment> createInvestment({
    required User investor,
    required String projectId,
    required Money amount,
  }) async {
    if (amount.amount < minimumAmount) {
      throw ArgumentError.value(
        amount.amount,
        'amount',
        'Minimum investasi Rp10.000.',
      );
    }

    final ApiResponse res;
    try {
      res = await _api.post(
        '/investment/invest/$projectId',
        authenticated: true,
        headers: _ngrokHeaders,
        body: {'amount': amount.amount},
      );
    } on ApiException catch (error) {
      // Surface the backend's message where we have one.
      throw StateError(error.message);
    }

    final data = res.data;
    final createdId = data is Map<String, dynamic>
        ? (data['id'] ?? data['investment_id'] ?? projectId).toString()
        : projectId;
    final confirmedAmount = data is Map<String, dynamic>
        ? ((data['amount'] as num?)?.toInt() ?? amount.amount)
        : amount.amount;
    final createdAt = data is Map<String, dynamic> && data['created_at'] is String
        ? DateTime.tryParse(data['created_at'] as String) ?? DateTime.now()
        : DateTime.now();

    return Investment(
      id: createdId,
      investor: investor,
      project: _placeholderProject(projectId),
      principal: Money(amount: confirmedAmount),
      status: InvestmentStatus.active,
      investedAt: createdAt,
    );
  }

  /// Minimal project so [Investment]'s non-null `project` is satisfied. The
  /// invest response does not include project details.
  static AgricultureProject _placeholderProject(String id) => AgricultureProject(
    id: id,
    title: 'Investasi',
    farmer: const User(id: '', name: 'Petani', role: UserRole.farmer),
    commodity: Commodity.other,
    location: const ProjectLocation(province: '', city: ''),
    status: ProjectStatus.growing,
    funding: const Funding(
      target: Money.zero,
      collected: Money.zero,
      investorCount: 0,
    ),
    roiMinPercent: 0,
    roiMaxPercent: 0,
    harvestCycleMonths: 4,
  );
}
