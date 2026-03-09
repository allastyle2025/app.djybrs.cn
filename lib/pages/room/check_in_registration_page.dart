import 'package:flutter/material.dart';
import '../../room_colors.dart';
import '../../services/room_service.dart';
import 'select_room_page.dart';

class CheckInRegistrationPage extends StatefulWidget {
  const CheckInRegistrationPage({super.key});

  @override
  State<CheckInRegistrationPage> createState() => _CheckInRegistrationPageState();
}

class _CheckInRegistrationPageState extends State<CheckInRegistrationPage> {
  final TextEditingController _idCardController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';
  List<UserInfo> _searchResults = [];
  int? _selectedUserId;

  @override
  void dispose() {
    _idCardController.dispose();
    super.dispose();
  }

  Future<void> _searchUser() async {
    final idCard = _idCardController.text.trim();
    if (idCard.isEmpty) {
      setState(() {
        _errorMessage = '请输入身份证号码';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _searchResults = [];
      _selectedUserId = null;
    });

    final response = await RoomService.getUserByIdCard(idCard);

    setState(() {
      _isLoading = false;
      if (response.isSuccess && response.data != null) {
        _searchResults = [response.data!];
      } else {
        _errorMessage = response.message;
      }
    });
  }

  void _proceedToSelectRoom() {
    if (_selectedUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择一位用户')),
      );
      return;
    }

    final selectedUser = _searchResults.firstWhere((u) => u.id == _selectedUserId);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SelectRoomPage(
          user: selectedUser,
          initialGender: selectedUser.gender,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RoomColors.background,
      appBar: AppBar(
        backgroundColor: RoomColors.cardBg,
        elevation: 0,
        iconTheme: IconThemeData(color: RoomColors.textPrimary),
        title: Text(
          '入住登记',
          style: TextStyle(
            color: RoomColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 搜索框
            Container(
              decoration: BoxDecoration(
                color: RoomColors.cardBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _idCardController,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  hintText: '请输入身份证号码',
                  hintStyle: TextStyle(color: RoomColors.textGrey),
                  prefixIcon: Icon(Icons.search, color: RoomColors.textSecondary),
                  suffixIcon: _idCardController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: RoomColors.textSecondary),
                          onPressed: () {
                            _idCardController.clear();
                            setState(() {
                              _searchResults = [];
                              _errorMessage = '';
                              _selectedUserId = null;
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onSubmitted: (_) => _searchUser(),
              ),
            ),
            const SizedBox(height: 12),
            // 搜索按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _searchUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: RoomColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('查询'),
              ),
            ),
            const SizedBox(height: 24),
            // 错误提示
            if (_errorMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: RoomColors.occupied.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: RoomColors.occupied, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage,
                        style: TextStyle(color: RoomColors.occupied),
                      ),
                    ),
                  ],
                ),
              ),
            // 搜索结果
            if (_searchResults.isNotEmpty) ...[
              Text(
                '查询结果',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: RoomColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final user = _searchResults[index];
                    return _buildUserItem(user);
                  },
                ),
              ),
            ],
          ],
        ),
      ),
      // 底部下一步按钮
      bottomNavigationBar: _searchResults.isNotEmpty
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _selectedUserId != null ? _proceedToSelectRoom : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: RoomColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      disabledBackgroundColor: RoomColors.divider,
                    ),
                    child: const Text(
                      '下一步：选择房间',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildUserItem(UserInfo user) {
    final isSelected = _selectedUserId == user.id;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedUserId = user.id;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? RoomColors.primary.withOpacity(0.1) : RoomColors.cardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? RoomColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            // 单选框
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? RoomColors.primary : RoomColors.divider,
                  width: 2,
                ),
                color: isSelected ? RoomColors.primary : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 16),
            // 用户信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        user.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: RoomColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: user.gender == 'male'
                              ? const Color(0xff42A5F5).withOpacity(0.1)
                              : const Color.fromARGB(255, 255, 107, 164).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          user.gender == 'male' ? '男' : '女',
                          style: TextStyle(
                            fontSize: 11,
                            color: user.gender == 'male'
                                ? const Color(0xff42A5F5)
                                : const Color.fromARGB(255, 255, 107, 164),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.phone_outlined, size: 14, color: RoomColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        user.phone,
                        style: TextStyle(
                          fontSize: 13,
                          color: RoomColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.badge_outlined, size: 14, color: RoomColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        user.idCard,
                        style: TextStyle(
                          fontSize: 12,
                          color: RoomColors.textGrey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 用户信息模型
class UserInfo {
  final int id;
  final String name;
  final String gender;
  final String phone;
  final int age;
  final String idCard;
  final String address;
  final String ethnicity;

  UserInfo({
    required this.id,
    required this.name,
    required this.gender,
    required this.phone,
    required this.age,
    required this.idCard,
    required this.address,
    required this.ethnicity,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      gender: json['gender'] ?? 'male',
      phone: json['phone'] ?? '',
      age: json['age'] ?? 0,
      idCard: json['idCard'] ?? '',
      address: json['address'] ?? '',
      ethnicity: json['ethnicity'] ?? '',
    );
  }
}

// API响应模型
class UserInfoResponse {
  final int code;
  final UserInfo? data;
  final String message;

  UserInfoResponse({
    required this.code,
    this.data,
    required this.message,
  });

  factory UserInfoResponse.fromJson(Map<String, dynamic> json) {
    return UserInfoResponse(
      code: json['code'] ?? 0,
      data: json['data'] != null ? UserInfo.fromJson(json['data']) : null,
      message: json['message'] ?? '',
    );
  }

  bool get isSuccess => code == 200;
}

// 快速入住响应模型
class QuickCheckInResponse {
  final int code;
  final dynamic data;
  final String message;

  QuickCheckInResponse({
    required this.code,
    this.data,
    required this.message,
  });

  factory QuickCheckInResponse.fromJson(Map<String, dynamic> json) {
    return QuickCheckInResponse(
      code: json['code'] ?? 0,
      data: json['data'],
      message: json['message'] ?? '',
    );
  }

  bool get isSuccess => code == 200 || code == 201;
}
