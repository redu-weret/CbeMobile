import 'auth.dart';

/// Admin user-management entry — matches `UserDto` from the backend.
class UserDto {
  final String id;
  final String? email;
  final String? userName;
  final String employeeId;
  final EmployeeLite? employee;
  final List<String> roles;
  final bool lockoutEnabled;
  final String? lockoutEnd;
  final int accessFailedCount;
  final String? profilePicturePath;

  const UserDto({
    required this.id,
    this.email,
    this.userName,
    required this.employeeId,
    this.employee,
    required this.roles,
    required this.lockoutEnabled,
    this.lockoutEnd,
    required this.accessFailedCount,
    this.profilePicturePath,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) {
    final emp = json['employee'];
    return UserDto(
      id: json['id']?.toString() ?? '',
      email: json['email'] as String?,
      userName: json['userName'] as String?,
      employeeId: json['employeeId']?.toString() ?? '',
      employee: emp is Map<String, dynamic> && emp.isNotEmpty
          ? EmployeeLite.fromJson(emp)
          : null,
      roles: (json['roles'] as List?)?.map((r) => r.toString()).toList() ??
          const [],
      lockoutEnabled: json['lockoutEnabled'] == true,
      lockoutEnd: json['lockoutEnd'] as String?,
      accessFailedCount: (json['accessFailedCount'] as num?)?.toInt() ?? 0,
      profilePicturePath: json['profilePicturePath'] as String?,
    );
  }
}
