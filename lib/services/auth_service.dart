import '../models/api_response.dart';
import '../models/auth.dart';
import 'api_client.dart';
import 'session.dart';


class AuthService {
  final ApiClient _client;

  AuthService([ApiClient? client]) : _client = client ?? ApiClient();

  Future<AuthResponse> login({
    required String emailOrUserName,
    required String password,
  }) async {
    final res = await _client.postJson<AuthResponse>(
      '/users/login',
      {'emailOrUserName': emailOrUserName, 'password': password},
      (json) => AuthResponse.fromJson(json),
    );
    if (!res.success || res.data == null) {
      throw ApiException(res.message ?? 'Login failed. Please try again.');
    }
    await Session.instance.saveLogin(
      token: res.data!.token,
      refreshToken: res.data!.refreshToken,
      user: res.data!.user,
    );
    return res.data!;
  }

  Future<AuthResponse> register({
    required String email,
    required String userName,
    required String password,
    required String employeeId,
  }) async {
    final res = await _client.postJson<AuthResponse>(
      '/users/register',
      {
        'email': email,
        'userName': userName,
        'password': password,
        'employeeId': employeeId,
      },
      (json) => AuthResponse.fromJson(json),
    );
    if (!res.success || res.data == null) {
      throw ApiException(res.message ?? 'Registration failed.');
    }
    await Session.instance.saveLogin(
      token: res.data!.token,
      refreshToken: res.data!.refreshToken,
      user: res.data!.user,
    );
    return res.data!;
  }

}
