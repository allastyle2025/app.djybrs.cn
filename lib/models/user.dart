class User {
  final int userId;
  final String userName;
  final String token;
  final String? email;
  final String? role;
  final String? avatar;
  final String? mobile;
  final String? nickname;
  final DateTime? createdAt;

  User({
    required this.userId,
    required this.userName,
    required this.token,
    this.email,
    this.role,
    this.avatar,
    this.mobile,
    this.nickname,
    this.createdAt,
  });

  /// 兼容 nickName（驼峰命名）
  String? get nickName => nickname;

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['userId'] ?? json['id'] ?? 0,
      userName: json['userName'] ?? json['username'] ?? '',
      token: json['token'] ?? '',
      email: json['email'],
      role: json['role'],
      avatar: json['avatar'],
      mobile: json['mobile'],
      nickname: json['nickName'] ?? json['nickname'],
      createdAt: json['createdAt'] != null 
          ? DateTime.tryParse(json['createdAt']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'token': token,
      'email': email,
      'role': role,
      'avatar': avatar,
      'mobile': mobile,
      'nickName': nickname,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}

class LoginResponse {
  final String message;
  final User? user;
  final bool success;

  LoginResponse({
    required this.message,
    this.user,
    required this.success,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      message: json['message'] ?? '',
      user: json['token'] != null ? User.fromJson(json) : null,
      success: json['message']?.toString().contains('成功') ?? false,
    );
  }
}
