import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser;

import '../core/config.dart';
import '../models/api_response.dart';
import '../models/auth.dart';
import 'api_client.dart';

/// Profile picture constants mirrored from the backend validation.
class ProfileService {
  static const int maxPictureBytes = 5 * 1024 * 1024; // 5 MB
  static const List<String> allowedExtensions = ['jpg', 'jpeg', 'png', 'webp'];

  final ApiClient _client;

  ProfileService([ApiClient? client]) : _client = client ?? ApiClient();

  /// Build the absolute URL of a stored profile picture (served from wwwroot).
  static String? pictureUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('data:') || path.startsWith('blob:') ||
        path.startsWith('http')) {
      return path;
    }
    return '${AppConfig.publicBase}/${path.replaceFirst(RegExp(r'^/+'), '')}';
  }

  static String? validate(File file, String fileName) {
    final ext = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : '';
    if (!allowedExtensions.contains(ext)) {
      return 'Only JPG, JPEG, PNG and WEBP images are allowed.';
    }
    if (file.lengthSync() > maxPictureBytes) {
      return 'Image must be 5 MB or smaller.';
    }
    return null;
  }

  Future<CurrentUser> upload({required String userId, required File file, required String fileName}) async {
    final multipartFile = await http.MultipartFile.fromPath('file', file.path,
        filename: fileName, contentType: _mediaType(fileName));
    final res = await _client.postMultipart<CurrentUser>(
      '/users/$userId/profile-picture',
      multipartFile,
      (json) => CurrentUser.fromJson(json),
    );
    if (!res.success || res.data == null) {
      throw ApiException(res.message ?? 'Failed to upload profile picture.');
    }
    return res.data!;
  }

  Future<CurrentUser> update({required String userId, required File file, required String fileName}) async {
    final multipartFile = await http.MultipartFile.fromPath('file', file.path,
        filename: fileName, contentType: _mediaType(fileName));
    final res = await _client.putMultipart<CurrentUser>(
      '/users/$userId/profile-picture',
      multipartFile,
      (json) => CurrentUser.fromJson(json),
    );
    if (!res.success || res.data == null) {
      throw ApiException(res.message ?? 'Failed to update profile picture.');
    }
    return res.data!;
  }

  Future<void> remove(String userId) async {
    final res = await _client.deleteJson<bool>(
      '/users/$userId/profile-picture',
      (data) => data == true,
    );
    if (!res.success) {
      throw ApiException(res.message ?? 'Failed to remove profile picture.');
    }
  }

  static http_parser.MediaType _mediaType(String fileName) {
    final ext = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : 'jpeg';
    // The backend requires Content-Type to start with image/.
    return http_parser.MediaType('image', ext == 'jpg' ? 'jpeg' : ext);
  }
}
