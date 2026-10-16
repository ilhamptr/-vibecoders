enum UserRole {
  farmer,
  investor;

  /// Parses a backend/stored role string into a [UserRole].
  ///
  /// Accepts common spellings the backend might use (e.g. `farmer`, `petani`,
  /// `investor`, `pemodal`). Returns null when the value is unknown or empty so
  /// callers can decide how to handle an unrecognized role.
  static UserRole? tryParse(String? value) {
    final normalized = value?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return null;
    switch (normalized) {
      case 'farmer':
      case 'petani':
        return UserRole.farmer;
      case 'investor':
      case 'pemodal':
        return UserRole.investor;
      default:
        return null;
    }
  }

  /// Canonical lowercase string used when caching the role locally.
  String get storageValue => name;
}
