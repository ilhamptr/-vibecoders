abstract interface class InvestorProfileRepository {
  /// Full name of the signed-in investor.
  Future<String> getFullName();
}
