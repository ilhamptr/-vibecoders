import 'package:flutter/foundation.dart';

import '../../../../../domain/domain.dart';

class RoleSelectionController extends ChangeNotifier {
  UserRole? _selectedRole;

  UserRole? get selectedRole => _selectedRole;

  bool get canContinue => _selectedRole != null;

  void selectRole(UserRole role) {
    if (_selectedRole == role) return;

    _selectedRole = role;
    notifyListeners();
  }

  void clearSelection() {
    if (_selectedRole == null) return;

    _selectedRole = null;
    notifyListeners();
  }
}
