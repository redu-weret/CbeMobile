/// Attendance check result — matches `AttendanceCheckResultDto`.
class AttendanceCheckResult {
  final String id;
  final String employeeId;
  final String fullName;
  final String division;
  final String jobTitle;
  final String department;
  final String phoneNumber;
  final String meetingDate;
  final String session;
  final bool isAttended;
  final String? attendanceTime;

  const AttendanceCheckResult({
    required this.id,
    required this.employeeId,
    required this.fullName,
    required this.division,
    required this.jobTitle,
    required this.department,
    required this.phoneNumber,
    required this.meetingDate,
    required this.session,
    required this.isAttended,
    this.attendanceTime,
  });

  factory AttendanceCheckResult.fromJson(Map<String, dynamic> json) =>
      AttendanceCheckResult(
        id: json['id']?.toString() ?? '',
        employeeId: json['employeeId']?.toString() ?? '',
        fullName: json['fullName']?.toString() ?? '',
        division: json['division']?.toString() ?? '',
        jobTitle: json['jobTitle']?.toString() ?? '',
        department: json['department']?.toString() ?? '',
        phoneNumber: json['phoneNumber']?.toString() ?? '',
        meetingDate: json['meetingDate']?.toString() ?? '',
        session: json['session']?.toString() ?? '',
        isAttended: json['isAttended'] == true,
        attendanceTime: json['attendanceTime'] as String?,
      );

  AttendanceCheckResult copyWith({
    bool? isAttended,
    String? attendanceTime,
    String? session,
  }) =>
      AttendanceCheckResult(
        id: id,
        employeeId: employeeId,
        fullName: fullName,
        division: division,
        jobTitle: jobTitle,
        department: department,
        phoneNumber: phoneNumber,
        meetingDate: meetingDate,
        session: session ?? this.session,
        isAttended: isAttended ?? this.isAttended,
        attendanceTime: attendanceTime ?? this.attendanceTime,
      );
}

/// A single attendance record — matches `AttendanceDto`.
class AttendanceRecord {
  final String id;
  final String employeeUniqueId;
  final String employeeFullName;
  final String department;
  final String meetingDate;
  final String session;
  final String attendanceTime;

  const AttendanceRecord({
    required this.id,
    required this.employeeUniqueId,
    required this.employeeFullName,
    required this.department,
    required this.meetingDate,
    required this.session,
    required this.attendanceTime,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) =>
      AttendanceRecord(
        id: json['id']?.toString() ?? '',
        employeeUniqueId: json['employeeUniqueId']?.toString() ?? '',
        employeeFullName: json['employeeFullName']?.toString() ?? '',
        department: json['department']?.toString() ?? '',
        meetingDate: json['meetingDate']?.toString() ?? '',
        session: json['session']?.toString() ?? '',
        attendanceTime: json['attendanceTime']?.toString() ?? '',
      );
}

/// Dashboard stats — matches `DashboardDto`.
class DashboardData {
  final int totalEmployees;
  final int todayMorningCount;
  final int todayAfternoonCount;
  final double todayAttendanceRate;
  final List<AttendanceRecord> recentAttendances;

  const DashboardData({
    required this.totalEmployees,
    required this.todayMorningCount,
    required this.todayAfternoonCount,
    required this.todayAttendanceRate,
    required this.recentAttendances,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) => DashboardData(
        totalEmployees: (json['totalEmployees'] as num?)?.toInt() ?? 0,
        todayMorningCount: (json['todayMorningCount'] as num?)?.toInt() ?? 0,
        todayAfternoonCount: (json['todayAfternoonCount'] as num?)?.toInt() ?? 0,
        todayAttendanceRate: (json['todayAttendanceRate'] as num?)?.toDouble() ?? 0,
        recentAttendances: (json['recentAttendances'] as List?)
                ?.map((e) => AttendanceRecord.fromJson(e as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}
