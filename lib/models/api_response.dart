/// 通用API响应模型
class ApiResponse<T> {
  final int code;
  final String message;
  final T? data;

  ApiResponse({
    required this.code,
    required this.message,
    this.data,
  });

  /// Treat any 2xx HTTP status code as success.
  bool get isSuccess => code >= 200 && code < 300;
}
