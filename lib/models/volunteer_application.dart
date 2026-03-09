class VolunteerApplication {
  final int id;
  final String name;
  final String lifePhoto;
  final DateTime submitTime;
  final String? idCardName;
  final String? idCardNumber;
  final int? age;
  final String? gender;
  final String? phone;
  final String? address;
  final String? ethnicity;
  final String? healthStatus;
  final String? emergencyContactName;
  final String? emergencyContactRelation;
  final String? emergencyContactPhone;
  final String? education;
  final String? major;
  final String? specialty;
  final String? isConvert;
  final String? dharmaName;
  final String? usualDevotionTime;
  final String? morningEveningClass;
  final int? devotionDays;
  final String? reasonForComing;
  final String? expectedResult;
  final String? fillId;
  final String? accessToken;
  final String? clientIp;
  final String? userAgent;
  final String? deviceType;
  final String? browser;
  final String? os;
  final String? referer;
  final String? requestId;
  final DateTime? tokenExpireTime;
  final DateTime? tokenCreatedTime;
  final int? userId;
  final String? status;

  VolunteerApplication({
    required this.id,
    required this.name,
    required this.lifePhoto,
    required this.submitTime,
    this.idCardName,
    this.idCardNumber,
    this.age,
    this.gender,
    this.phone,
    this.address,
    this.ethnicity,
    this.healthStatus,
    this.emergencyContactName,
    this.emergencyContactRelation,
    this.emergencyContactPhone,
    this.education,
    this.major,
    this.specialty,
    this.isConvert,
    this.dharmaName,
    this.usualDevotionTime,
    this.morningEveningClass,
    this.devotionDays,
    this.reasonForComing,
    this.expectedResult,
    this.fillId,
    this.accessToken,
    this.clientIp,
    this.userAgent,
    this.deviceType,
    this.browser,
    this.os,
    this.referer,
    this.requestId,
    this.tokenExpireTime,
    this.tokenCreatedTime,
    this.userId,
    this.status,
  });

  factory VolunteerApplication.fromJson(Map<String, dynamic> json) {
    return VolunteerApplication(
      id: json['id'] ?? 0,
      name: json['idCardName'] ?? json['name'] ?? '',
      lifePhoto: json['lifePhoto'] ?? '',
      submitTime: json['submitTime'] != null
          ? DateTime.tryParse(json['submitTime']) ?? DateTime.now()
          : DateTime.now(),
      idCardName: json['idCardName'],
      idCardNumber: json['idCardNumber'],
      age: json['age'] != null ? int.tryParse(json['age'].toString()) : null,
      gender: json['gender'],
      phone: json['phone'],
      address: json['address'],
      ethnicity: json['ethnicity'],
      healthStatus: json['healthStatus'],
      emergencyContactName: json['emergencyContactName'],
      emergencyContactRelation: json['emergencyContactRelation'],
      emergencyContactPhone: json['emergencyContactPhone'],
      education: json['education'],
      major: json['major'],
      specialty: json['specialty'],
      isConvert: json['isConvert'],
      dharmaName: json['dharmaName'],
      usualDevotionTime: json['usualDevotionTime'],
      morningEveningClass: json['morningEveningClass'],
      devotionDays: json['devotionDays'] != null ? int.tryParse(json['devotionDays'].toString()) : null,
      reasonForComing: json['reasonForComing'],
      expectedResult: json['expectedResult'],
      fillId: json['fillId'],
      accessToken: json['accessToken'],
      clientIp: json['clientIp'],
      userAgent: json['userAgent'],
      deviceType: json['deviceType'],
      browser: json['browser'],
      os: json['os'],
      referer: json['referer'],
      requestId: json['requestId'],
      tokenExpireTime: json['tokenExpireTime'] != null
          ? DateTime.tryParse(json['tokenExpireTime'])
          : null,
      tokenCreatedTime: json['tokenCreatedTime'] != null
          ? DateTime.tryParse(json['tokenCreatedTime'])
          : null,
      userId: json['userId'] != null ? int.tryParse(json['userId'].toString()) : null,
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'lifePhoto': lifePhoto,
      'submitTime': submitTime.toIso8601String(),
    };
  }
}

class VolunteerApplicationResponse {
  final int code;
  final String message;
  final List<VolunteerApplication> data;
  final int? total;
  final int? totalPages;
  final int? currentPage;
  final int? size;

  VolunteerApplicationResponse({
    required this.code,
    required this.message,
    required this.data,
    this.total,
    this.totalPages,
    this.currentPage,
    this.size,
  });

  factory VolunteerApplicationResponse.fromJson(Map<String, dynamic> json) {
    List<dynamic> dataList = [];
    int? total;
    int? totalPages;
    int? currentPage;
    int? size;

    // 处理嵌套的 data 对象
    if (json['data'] is Map) {
      final dataObj = json['data'] as Map<String, dynamic>;
      dataList = dataObj['content'] ?? dataObj['data'] ?? [];
      total = dataObj['total'] ?? dataObj['totalElements'];
      totalPages = dataObj['totalPages'];
      currentPage = dataObj['currentPage'] ?? dataObj['page'] ?? dataObj['number'];
      size = dataObj['size'];
    } else if (json['data'] is List) {
      dataList = json['data'] ?? [];
    }

    return VolunteerApplicationResponse(
      code: json['code'] ?? 0,
      message: json['message'] ?? '',
      data: dataList.map((item) => VolunteerApplication.fromJson(item)).toList(),
      total: total,
      totalPages: totalPages,
      currentPage: currentPage,
      size: size,
    );
  }
}
