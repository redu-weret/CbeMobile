import '../models/api_response.dart';
import '../models/attendance.dart';
import 'api_client.dart';

class AttendanceService {
  final ApiClient _client;

  AttendanceService([ApiClient? client]) : _client = client ?? ApiClient();

  Future<AttendanceRecord> take({
    required String employeeId,
    String? meetingDate,
    String? session,
  }) async {
    final res = await _client.postJson<AttendanceRecord>(
      '/attendance',
      {
        'employeeId': employeeId,
        if (meetingDate != null) 'meetingDate': meetingDate,
        if (session != null) 'session': session,
      },
      (json) => AttendanceRecord.fromJson(json),
    );
    if (!res.success || res.data == null) {
      throw ApiException(res.message ?? 'Failed to take attendance.');
    }
    return res.data!;
  }

  Future<DashboardData> getDashboard() async {
    final res = await _client.getJson<DashboardData>(
      '/admin/dashboard',
      (json) => DashboardData.fromJson(json),
    );
    if (!res.success || res.data == null) {
      throw ApiException(res.message ?? 'Failed to load dashboard data.');
    }
    return res.data!;
  }

  /// Download an exported report. Returns file bytes.
  Future<List<int>> exportData(String format) async {
    return _client.download(
      '/admin/export/excel',
      query: {'format': format},
    );
  }
}
