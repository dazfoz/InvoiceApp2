import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  admin,
  manager,
  member,
}

class CompanyUser {
  final String userId;
  final String companyId;
  final UserRole role;
  final List<String> permissions;
  final DateTime joinedAt;

  CompanyUser({
    required this.userId,
    required this.companyId,
    required this.role,
    required this.permissions,
    required this.joinedAt,
  });

  factory CompanyUser.fromMap(Map<String, dynamic> map) {
    return CompanyUser(
      userId: map['userId'] as String,
      companyId: map['companyId'] as String,
      role: UserRole.values.firstWhere(
        (e) => e.toString() == 'UserRole.${map['role']}',
        orElse: () => UserRole.member,
      ),
      permissions: List<String>.from(map['permissions'] ?? []),
      joinedAt: (map['joinedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'companyId': companyId,
      'role': role.toString().split('.').last,
      'permissions': permissions,
      'joinedAt': Timestamp.fromDate(joinedAt),
    };
  }

  bool hasPermission(String permission) {
    return permissions.contains(permission);
  }

  static List<String> getDefaultPermissions(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return [
          'manage_company',
          'manage_users',
          'manage_clients',
          'manage_invoices',
          'view_reports',
        ];
      case UserRole.manager:
        return [
          'manage_clients',
          'manage_invoices',
          'view_reports',
        ];
      case UserRole.member:
        return [
          'view_clients',
          'view_invoices',
        ];
    }
  }
}
