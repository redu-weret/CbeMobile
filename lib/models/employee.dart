/// Employee model — matches `EmployeeDto` from the backend.
class Employee {
  final String id;
  final String employeeId; // e.g. EMP001
  final String fullName;
  final String division;
  final String jobTitle;
  final String department;
  final String phoneNumber;
  final String createdAt;
  final String? profilePicturePath;

  const Employee({
    required this.id,
    required this.employeeId,
    required this.fullName,
    required this.division,
    required this.jobTitle,
    required this.department,
    required this.phoneNumber,
    required this.createdAt,
    this.profilePicturePath,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id']?.toString() ?? '',
      employeeId: json['employeeId']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      division: json['division']?.toString() ?? '',
      jobTitle: json['jobTitle']?.toString() ?? '',
      department: json['department']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
      profilePicturePath: json['profilePicturePath'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'employeeId': employeeId,
        'fullName': fullName,
        'division': division,
        'jobTitle': jobTitle,
        'department': department,
        'phoneNumber': phoneNumber,
        'createdAt': createdAt,
        'profilePicturePath': profilePicturePath,
      };
}

/// Payload for registering a new employee.
class RegisterEmployeeDto {
  final String employeeId;
  final String fullName;
  final String division;
  final String jobTitle;
  final String department;
  final String phoneNumber;

  const RegisterEmployeeDto({
    required this.employeeId,
    required this.fullName,
    required this.division,
    required this.jobTitle,
    required this.department,
    required this.phoneNumber,
  });

  Map<String, dynamic> toJson() => {
        'employeeId': employeeId,
        'fullName': fullName,
        'division': division,
        'jobTitle': jobTitle,
        'department': department,
        'phoneNumber': phoneNumber,
      };
}

/// Payload for updating an employee (employeeId is immutable).
class UpdateEmployeeDto {
  final String fullName;
  final String division;
  final String jobTitle;
  final String department;
  final String phoneNumber;

  const UpdateEmployeeDto({
    required this.fullName,
    required this.division,
    required this.jobTitle,
    required this.department,
    required this.phoneNumber,
  });

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'division': division,
        'jobTitle': jobTitle,
        'department': department,
        'phoneNumber': phoneNumber,
      };
}
