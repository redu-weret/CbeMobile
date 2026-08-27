/// Current authenticated user — matches `CurrentUserDto`.
class CurrentUser {
  final String userId;
  final String? email;
  final String? userName;
  final String employeeId; // GUID of linked employee record
  final EmployeeLite? employee;
  final List<String> roles;
  final String? profilePicturePath;

  const CurrentUser({
    required this.userId,
    this.email,
    this.userName,
    required this.employeeId,
    this.employee,
    required this.roles,
    this.profilePicturePath,
  });

  bool get isAdmin => roles.contains('Admin');

  factory CurrentUser.fromJson(Map<String, dynamic> json) {
    final emp = json['employee'];
    return CurrentUser(
      userId: json['userId']?.toString() ?? '',
      email: json['email'] as String?,
      userName: json['userName'] as String?,
      employeeId: json['employeeId']?.toString() ?? '',
      employee: emp is Map<String, dynamic> && emp.isNotEmpty
          ? EmployeeLite.fromJson(emp)
          : null,
      roles: (json['roles'] as List?)?.map((r) => r.toString()).toList() ??
          const [],
      profilePicturePath: json['profilePicturePath'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'email': email,
        'userName': userName,
        'employeeId': employeeId,
        'employee': employee?.toJson(),
        'roles': roles,
        'profilePicturePath': profilePicturePath,
      };

  CurrentUser copyWith({String? profilePicturePath}) => CurrentUser(
        userId: userId,
        email: email,
        userName: userName,
        employeeId: employeeId,
        employee: employee,
        roles: roles,
        profilePicturePath: profilePicturePath ?? this.profilePicturePath,
      );
}

/// Compact employee info embedded in user payloads.
class EmployeeLite {
  final String id;
  final String employeeId;
  final String fullName;
  final String? profilePicturePath;

  const EmployeeLite({
    required this.id,
    required this.employeeId,
    required this.fullName,
    this.profilePicturePath,
  });

  factory EmployeeLite.fromJson(Map<String, dynamic> json) => EmployeeLite(
        id: json['id']?.toString() ?? '',
        employeeId: json['employeeId']?.toString() ?? '',
        fullName: json['fullName']?.toString() ?? '',
        profilePicturePath: json['profilePicturePath'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'employeeId': employeeId,
        'fullName': fullName,
        'profilePicturePath': profilePicturePath,
      };
}

/// Auth response from login / register / refresh.
class AuthResponse {
  final String token;
  final String expiration;
  final CurrentUser user;
  final String? refreshToken;

  const AuthResponse({
    required this.token,
    required this.expiration,
    required this.user,
    this.refreshToken,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        token: json['token']?.toString() ?? '',
        expiration: json['expiration']?.toString() ?? '',
        user: CurrentUser.fromJson(
          json['user'] as Map<String, dynamic>? ?? const {},
        ),
        refreshToken: json['refreshToken'] as String?,
      );
}
