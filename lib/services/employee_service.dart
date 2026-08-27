import '../models/api_response.dart';
import '../models/attendance.dart';
import '../models/employee.dart';
import 'api_client.dart';

class EmployeeService {
  final ApiClient _client;

  EmployeeService([ApiClient? client]) : _client = client ?? ApiClient();

  Future<List<Employee>> getAll() async {
    final list = await _client.getList<Employee>(
      '/employees',
      (json) => Employee.fromJson(json),
    );
    return list;
  }

  Future<Employee> register(RegisterEmployeeDto dto) async {
    final res = await _client.postJson<Employee>(
      '/employees/register',
      dto.toJson(),
      (json) => Employee.fromJson(json),
    );
    if (!res.success || res.data == null) {
      throw ApiException(res.message ?? 'Failed to register employee.');
    }
    return res.data!;
  }

  Future<Employee> update(String id, UpdateEmployeeDto dto) async {
    final res = await _client.putJson<Employee>(
      '/employee/$id',
      dto.toJson(),
      (json) => Employee.fromJson(json),
    );
    if (!res.success || res.data == null) {
      throw ApiException(res.message ?? 'Failed to update employee.');
    }
    return res.data!;
  }

  Future<void> delete(String id) async {
    final res = await _client.deleteJson<bool>(
      '/employee/$id',
      (data) => data == true,
    );
    if (!res.success) {
      throw ApiException(res.message ?? 'Failed to delete employee.');
    }
  }

  /// Check an employee's attendance status by their string ID (e.g. EMP001).
  Future<AttendanceCheckResult> checkStatus(String employeeId) async {
    final res = await _client.getJson<AttendanceCheckResult>(
      '/employees/$employeeId',
      (json) => AttendanceCheckResult.fromJson(json),
    );
    if (!res.success || res.data == null) {
      throw ApiException(res.message ?? 'No employee found with that ID.');
    }
    return res.data!;
  }
}
