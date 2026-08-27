/// Generic API response wrapper matching the backend's `ApiResponse<T>`.
class ApiResponse<T> {
  final bool success;
  final String? message;
  final int? total;
  final T? data;

  const ApiResponse({
    required this.success,
    this.message,
    this.total,
    this.data,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? dataParser,
  ) {
    return ApiResponse<T>(
      success: json['success'] == true,
      message: json['message'] as String?,
      total: json['total'] as int?,
      data: json['data'] == null ? null : dataParser?.call(json['data']),
    );
  }
}

/// A human-readable error extracted from any HTTP failure.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}
