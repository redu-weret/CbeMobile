import '../models/api_response.dart';
import '../models/user.dart';
import 'api_client.dart';

class UserService {
  final ApiClient _client;

  UserService([ApiClient? client]) : _client = client ?? ApiClient();

  Future<List<UserDto>> getAll() async {
    final list = await _client.getList<UserDto>(
      '/users',
      (json) => UserDto.fromJson(json),
    );
    return list;
  }

  Future<void> assignRole({
    required String userId,
    required String roleName,
  }) async {
    final res = await _client.postJson<bool>(
      '/users/assign-role',
      {'userId': userId, 'roleName': roleName},
      (data) => data == true,
    );
    if (!res.success) throw ApiException(res.message ?? 'Failed to assign role.');
  }

  Future<void> changeRole({
    required String userId,
    required String currentRole,
    required String newRole,
  }) async {
    final res = await _client.postJson<bool>(
      '/users/change-role',
      {'userId': userId, 'currentRole': currentRole, 'newRole': newRole},
      (data) => data == true,
    );
    if (!res.success) throw ApiException(res.message ?? 'Failed to change role.');
  }

  Future<void> removeRole({
    required String userId,
    required String roleName,
  }) async {
    final res = await _client.postJson<bool>(
      '/users/remove-role',
      {'userId': userId, 'roleName': roleName},
      (data) => data == true,
    );
    if (!res.success) throw ApiException(res.message ?? 'Failed to remove role.');
  }

  Future<void> changePassword({
    required String userId,
    required String currentPassword,
    required String newPassword,
  }) async {
    final res = await _client.postJson<bool>(
      '/users/change-password',
      {'userId': userId, 'currentPassword': currentPassword, 'newPassword': newPassword},
      (data) => data == true,
    );
    if (!res.success) {
      throw ApiException(res.message ?? 'Failed to change password.');
    }
  }

  Future<void> resetPassword({
    required String userId,
    required String newPassword,
  }) async {
    final res = await _client.postJson<bool>(
      '/users/reset-password',
      {'userId': userId, 'newPassword': newPassword},
      (data) => data == true,
    );
    if (!res.success) {
      throw ApiException(res.message ?? 'Failed to reset password.');
    }
  }

  Future<void> deleteUser(String id) async {
    final res = await _client.deleteJson<bool>(
      '/users/$id',
      (data) => data == true,
    );
    if (!res.success) {
      throw ApiException(res.message ?? 'Failed to delete user.');
    }
  }

  Future<void> deleteCurrentUser() async {
    final res = await _client.deleteJson<bool>(
      '/users/me',
      (data) => data == true,
    );
    if (!res.success) {
      throw ApiException(res.message ?? 'Failed to delete account.');
    }
  }
}
