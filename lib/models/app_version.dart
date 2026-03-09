/// 应用版本检查响应
class AppVersionResponse {
  final int code;
  final String message;
  final AppVersion? data;

  AppVersionResponse({
    required this.code,
    required this.message,
    this.data,
  });

  factory AppVersionResponse.fromJson(Map<String, dynamic> json) {
    return AppVersionResponse(
      code: json['code'] ?? 0,
      message: json['message'] ?? '',
      data: json['data'] != null ? AppVersion.fromJson(json['data']) : null,
    );
  }
}

/// 应用版本信息
class AppVersion {
  final bool hasUpdate;
  final String? version;
  final String? versionCode;
  final String? downloadUrl;
  final bool? forceUpdate;
  final String? updateLog;
  final int? fileSize;
  final DateTime? releaseTime;

  AppVersion({
    required this.hasUpdate,
    this.version,
    this.versionCode,
    this.downloadUrl,
    this.forceUpdate,
    this.updateLog,
    this.fileSize,
    this.releaseTime,
  });

  factory AppVersion.fromJson(Map<String, dynamic> json) {
    return AppVersion(
      hasUpdate: json['hasUpdate'] ?? false,
      version: json['version'],
      versionCode: json['versionCode'],
      downloadUrl: json['downloadUrl'],
      forceUpdate: json['forceUpdate'],
      updateLog: json['updateLog'],
      fileSize: json['fileSize'],
      releaseTime: json['releaseTime'] != null
          ? DateTime.tryParse(json['releaseTime'])
          : null,
    );
  }

  /// 格式化文件大小显示
  String get formattedFileSize {
    if (fileSize == null) return '';
    if (fileSize! < 1024) return '${fileSize}B';
    if (fileSize! < 1024 * 1024) return '${(fileSize! / 1024).toStringAsFixed(1)}KB';
    return '${(fileSize! / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  /// 格式化发布时间
  String get formattedReleaseTime {
    if (releaseTime == null) return '';
    return '${releaseTime!.year}-${releaseTime!.month.toString().padLeft(2, '0')}-${releaseTime!.day.toString().padLeft(2, '0')}';
  }
}
