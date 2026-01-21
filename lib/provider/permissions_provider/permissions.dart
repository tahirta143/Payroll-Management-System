// import 'package:flutter/material.dart';
//
// class PermissionProvider with ChangeNotifier {
//   List<String> _permissions = [];
//
//   void setPermissions(List<String> permissions) {
//     _permissions = permissions;
//     notifyListeners();
//   }
//
//   bool hasPermission(String code) {
//     return _permissions.contains(code);
//   }
//
//   void clear() {
//     _permissions = [];
//     notifyListeners();
//   }
// }
import 'package:flutter/material.dart';

class PermissionProvider with ChangeNotifier {
  List<String> _permissions = [];
  String _userRole = '';

  List<String> get permissions => _permissions;
  String get userRole => _userRole;

  void setPermissions(List<String> permissions) {
    _permissions = permissions;
    notifyListeners();
  }

  void setUserRole(String role) {
    _userRole = role;
    notifyListeners();
  }

  bool hasPermission(String permission) {
    return _permissions.contains(permission);
  }

  // Permission categories for better organization
  bool get canViewDashboard => hasPermission('can-view-dashboard');
  bool get canViewAttendence => hasPermission('can-view-attendence');
  bool get canViewUsers => hasPermission('can-view-users');
  bool get canViewEmployees => hasPermission('can-view-employees');
  bool get canViewReports => hasPermission('can-view-reports');
  bool get canViewRoles => hasPermission('can-view-roles');

  // CRUD operations check
  bool canAdd(String resource) => hasPermission('can-add-$resource');
  bool canEdit(String resource) => hasPermission('can-edit-$resource');
  bool canDelete(String resource) => hasPermission('can-delete-$resource');
  bool canView(String resource) => hasPermission('can-view-$resource');

  // Check if user has any of the admin permissions
  bool get isAdminUser {
    return hasPermission('can-view-users') ||
        hasPermission('can-view-roles') ||
        hasPermission('can-add-user');
  }

  // Check if user is attendance user only
  bool get isAttendenceOnlyUser {
    final attendencePerms = _permissions.where((p) =>
        p.contains('attendence')).length;
    final totalPerms = _permissions.length;

    return attendencePerms > 0 && totalPerms <= 3; // Only has basic + attendence
  }
}