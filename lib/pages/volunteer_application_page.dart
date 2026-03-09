import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/volunteer_application.dart';
import '../services/volunteer_application_service.dart';
import '../services/auth_service.dart';
import '../room_colors.dart';
import 'login_page.dart';

class VolunteerApplicationPage extends StatefulWidget {
  const VolunteerApplicationPage({super.key});

  @override
  State<VolunteerApplicationPage> createState() => _VolunteerApplicationPageState();
}

class _VolunteerApplicationPageState extends State<VolunteerApplicationPage> {
  List<VolunteerApplication> _applications = [];
  bool _isLoading = true; // 首次进入显示加载动画
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _currentPage = 0;
  int _total = 0;
  final int _pageSize = 10;
  bool _hasMore = true;

  final TextEditingController _searchController = TextEditingController();
  String? _keyword;

  @override
  void initState() {
    super.initState();
    if (!AuthService.isLoggedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginPage()),
            (route) => false,
          );
        }
      });
      return;
    }
    _loadApplications();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String value) {
    setState(() {
      _keyword = value.trim().isEmpty ? null : value.trim();
      _currentPage = 0;
      _applications = [];
      _hasMore = true;
    });
    _loadApplications();
  }

  Future<void> _loadApplications({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 0;
        _applications = [];
        _hasMore = true;
      });
    }

    // 首次加载时 _isLoading 为 true，需要允许执行
    if ((_isLoading && _applications.isNotEmpty) || (_isLoadingMore && !refresh)) {
      return;
    }

    setState(() {
      if (refresh) {
        _isLoading = true;
      } else {
        _isLoadingMore = true;
      }
      _errorMessage = null;
    });

    try {
      final response = await VolunteerApplicationService.getApplications(
        page: _currentPage,
        size: _pageSize,
        keyword: _keyword,
      );

      print('Response data: ${response.data}');
      if (response.data.isNotEmpty) {
        print('First application: ${response.data.first}');
        print('First application idCardName: ${response.data.first.idCardName}');
        print('First application idCardNumber: ${response.data.first.idCardNumber}');
        print('First application address: ${response.data.first.address}');
        print('First application major: ${response.data.first.major}');
        print('First application clientIp: ${response.data.first.clientIp}');
        print('First application deviceType: ${response.data.first.deviceType}');
        print('First application browser: ${response.data.first.browser}');
        print('First application os: ${response.data.first.os}');
        print('First application userId: ${response.data.first.userId}');
        print('First application status: ${response.data.first.status}');
        print('First application requestId: ${response.data.first.requestId}');
      }
      
      setState(() {
        // 分页模式：直接替换数据，不是追加
        _applications = response.data;
        _total = response.total ?? response.data.length;
        _hasMore = response.data.length >= _pageSize;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Widget _buildBody() {
    return Stack(
      children: [
        Column(
          children: [
            // 搜索栏
            _buildSearchBar(),
            // 统计信息
            _buildStatsBar(),
            // 内容区域
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
        // 分页按钮 - 悬浮于底部中央
        Positioned(
          left: 0,
          right: 0,
          bottom: 12,
          child: Center(
            child: _buildPagination(),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: RoomColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: '搜索姓名、身份证号或手机号',
          hintStyle: TextStyle(
            fontSize: 14,
            color: RoomColors.textGrey,
          ),
          prefixIcon: Icon(Icons.search, size: 20, color: RoomColors.textGrey),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, size: 18, color: RoomColors.textGrey),
                  onPressed: () {
                    _searchController.clear();
                    _onSearch('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        onSubmitted: _onSearch,
        textInputAction: TextInputAction.search,
      ),
    );
  }

  Widget _buildStatsBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            RoomColors.primary.withOpacity(0.08),
            RoomColors.primary.withOpacity(0.03),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: RoomColors.primary.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.people_outline,
            size: 18,
            color: RoomColors.primary,
          ),
          const SizedBox(width: 8),
          Text(
            '共 $_total 条申请',
            style: TextStyle(
              fontSize: 13,
              color: RoomColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          if (_keyword != null && _keyword!.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: RoomColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search, size: 12, color: RoomColors.primary),
                  const SizedBox(width: 4),
                  Text(
                    _keyword!,
                    style: TextStyle(
                      fontSize: 12,
                      color: RoomColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    // 如果是分页加载（不是首次加载），显示列表和底部加载指示器
    if (_isLoading && _applications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(RoomColors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              '加载中...',
              style: TextStyle(
                fontSize: 14,
                color: RoomColors.textGrey,
              ),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null && _applications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red.shade400, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _loadApplications(refresh: true),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('重试'),
              style: ElevatedButton.styleFrom(
                backgroundColor: RoomColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_applications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: RoomColors.cardBg,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.people_outline,
                size: 48,
                color: RoomColors.textGrey,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _keyword != null ? '未找到匹配的申请' : '暂无义工申请',
              style: TextStyle(
                color: RoomColors.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (_keyword != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  _searchController.clear();
                  _onSearch('');
                },
                child: Text(
                  '清除搜索',
                  style: TextStyle(color: RoomColors.primary),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Stack(
      children: [
        ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
          itemCount: _applications.length,
          separatorBuilder: (context, index) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final application = _applications[index];
            return VolunteerApplicationCard(
              application: application,
              onTap: () => _showApplicationDetail(application),
            );
          },
        ),
        // 分页加载时的半透明遮罩
        if (_isLoadingMore)
          Positioned.fill(
            child: Container(
              color: Colors.white.withOpacity(0.5),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(RoomColors.primary),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPagination() {
    final totalPages = (_total / _pageSize).ceil();
    if (totalPages <= 1) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.75),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 上一页按钮
                _buildPageButton(
                  icon: Icons.chevron_left,
                  onTap: _currentPage > 0 && !_isLoadingMore
                      ? () {
                          setState(() {
                            _currentPage--;
                          });
                          _loadApplications();
                        }
                      : null,
                ),
                const SizedBox(width: 20),
                // 页码信息
                Text(
                  '${_currentPage + 1} / $totalPages',
                  style: TextStyle(
                    fontSize: 14,
                    color: RoomColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 20),
                // 下一页按钮
                _buildPageButton(
                  icon: Icons.chevron_right,
                  onTap: _currentPage < totalPages - 1 && !_isLoadingMore
                      ? () {
                          setState(() {
                            _currentPage++;
                          });
                          _loadApplications();
                        }
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageButton({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    final isEnabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        child: Icon(
          icon,
          size: 30,
          color: isEnabled ? RoomColors.textPrimary : RoomColors.textGrey.withOpacity(0.3),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: RoomColors.background,
        foregroundColor: RoomColors.textPrimary,
        title: const Text(
          '义工申请',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: RoomColors.primary),
            onPressed: () => _loadApplications(refresh: true),
          ),
        ],
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  void _showApplicationDetail(VolunteerApplication application) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: 900,
                constraints: const BoxConstraints(maxWidth: 900, maxHeight: 800),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.5),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 头部
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            RoomColors.primary.withOpacity(0.1),
                            RoomColors.primary.withOpacity(0.02),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Stack(
                        children: [
                          // 关闭按钮
                          Positioned(
                            right: 0,
                            top: 0,
                            child: GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close,
                                  size: 20,
                                  color: RoomColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                          // 内容
                          Column(
                            children: [
                              // 头像
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      RoomColors.primary.withOpacity(0.2),
                                      RoomColors.primary.withOpacity(0.05),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.network(
                                    '${VolunteerApplicationService.baseUrl}/api/files/temp/image/${application.accessToken}/${application.lifePhoto}',
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Center(
                                        child: Icon(
                                          Icons.person_outline,
                                          size: 36,
                                          color: RoomColors.primary.withOpacity(0.5),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                application.name,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: RoomColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.schedule_outlined,
                                    size: 14,
                                    color: RoomColors.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatRelativeTime(application.submitTime),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: RoomColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // 内容
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDetailSection('基本信息', [
                              _buildDetailItem('申请ID', application.id.toString()),
                              _buildDetailItem('姓名', application.idCardName ?? '未填写'),
                              _buildIdCardItem('身份证号', application.idCardNumber ?? '未填写'),
                              _buildDetailItem('性别', _getGenderText(application.gender)),
                              _buildDetailItem('年龄', application.age?.toString() ?? '未填写'),
                              _buildDetailItem('民族', application.ethnicity ?? '未填写'),
                              _buildDetailItem('健康状态', application.healthStatus ?? '未填写'),
                            ]),
                            const SizedBox(height: 16),
                            _buildDetailSection('联系方式', [
                              _buildPhoneDetailItem(context, '手机号', application.phone ?? '未填写'),
                              _buildDetailItem('地址', application.address ?? '未填写'),
                            ]),
                            const SizedBox(height: 16),
                            _buildDetailSection('紧急联系人', [
                              _buildDetailItem('姓名', application.emergencyContactName ?? '未填写'),
                              _buildDetailItem('关系', application.emergencyContactRelation ?? '未填写'),
                              _buildDetailItem('电话', application.emergencyContactPhone ?? '未填写'),
                            ]),
                            const SizedBox(height: 16),
                            _buildDetailSection('教育背景', [
                              _buildDetailItem('学历', _getEducationText(application.education)),
                              _buildDetailItem('专业', application.major ?? '未填写'),
                              _buildDetailItem('特长', application.specialty ?? '未填写'),
                            ]),
                            const SizedBox(height: 16),
                            _buildDetailSection('信仰信息', [
                              _buildDetailItem('是否皈依', _getConvertText(application.isConvert)),
                              _buildDetailItem('法名', application.dharmaName ?? '未填写'),
                              _buildDetailItem('发心时间', _getDevotionTimeText(application.usualDevotionTime)),
                              _buildDetailItem('早晚课', _getMorningEveningText(application.morningEveningClass)),
                              _buildDetailItem('发心时长', application.devotionDays?.toString() ?? '未填写'),
                              _buildDetailItem('来寺原因', application.reasonForComing ?? '未填写'),
                              _buildDetailItem('期望收获', application.expectedResult ?? '未填写'),
                            ]),
                          ],
                        ),
                      ),
                    ),
                    // 底部留白
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 14,
              decoration: BoxDecoration(
                color: RoomColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: RoomColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                RoomColors.cardBg,
                RoomColors.background.withOpacity(0.5),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: RoomColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: RoomColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: RoomColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdCardItem(String label, String value) {
    if (value == '未填写') {
      return _buildDetailItem(label, value);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: RoomColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: IdCardNumberDisplay(idCardNumber: value),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneDetailItem(BuildContext context, String label, String phone) {
    final isEmpty = phone == '未填写';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: RoomColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: isEmpty
                  ? null
                  : () {
                      showDialog(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: Row(
                            children: [
                              Icon(
                                Icons.phone,
                                color: RoomColors.primary,
                              ),
                              const SizedBox(width: 8),
                              const Text('拨打电话'),
                            ],
                          ),
                          content: Text('是否拨打 $phone？'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(dialogContext).pop(),
                              child: Text(
                                '取消',
                                style: TextStyle(color: RoomColors.textGrey),
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(dialogContext).pop();
                                // 这里可以调用 url_launcher 拨打电话
                                // launchUrl(Uri.parse('tel:$phone'));
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: RoomColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('拨打'),
                            ),
                          ],
                        ),
                      );
                    },
              child: Text(
                phone,
                style: TextStyle(
                  fontSize: 13,
                  color: isEmpty ? RoomColors.textSecondary : RoomColors.primary,
                  decoration: isEmpty ? null : TextDecoration.underline,
                  decorationColor: RoomColors.primary.withOpacity(0.5),
                ),
              ),
            ),
          ),
          if (!isEmpty)
            GestureDetector(
              onTap: () {
                // 复制到剪贴板
                // Clipboard.setData(ClipboardData(text: phone));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('已复制 $phone'),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: RoomColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(
                  Icons.copy_outlined,
                  size: 12,
                  color: RoomColors.primary,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _getGenderText(String? gender) {
    switch (gender?.toLowerCase()) {
      case 'male':
      case '男':
        return '男';
      case 'female':
      case '女':
        return '女';
      default:
        return '未填写';
    }
  }

  String _getEducationText(String? education) {
    switch (education?.toLowerCase()) {
      case 'primary':
      case 'primary_school':
        return '小学';
      case 'middle':
      case 'middle_school':
        return '初中';
      case 'high_school':
        return '高中';
      case 'college':
      case 'junior_college':
        return '大专';
      case 'bachelor':
      case 'university':
        return '本科';
      case 'master':
        return '硕士';
      case 'phd':
        return '博士';
      default:
        return education ?? '未填写';
    }
  }

  String _getConvertText(String? isConvert) {
    switch (isConvert?.toLowerCase()) {
      case 'yes':
      case 'true':
        return '是';
      case 'no':
      case 'false':
        return '否';
      default:
        return isConvert ?? '未填写';
    }
  }

  String _getMorningEveningText(String? morningEveningClass) {
    switch (morningEveningClass?.toLowerCase()) {
      case 'morning':
        return '早课';
      case 'evening':
        return '晚课';
      case 'both':
      case 'all':
        return '早晚课';
      default:
        return morningEveningClass ?? '未填写';
    }
  }

  String _getDevotionTimeText(String? usualDevotionTime) {
    switch (usualDevotionTime?.toLowerCase()) {
      case 'weekday_morning':
        return '工作日早上';
      case 'weekday_evening':
        return '工作日晚上';
      case 'weekday_day':
        return '工作日白天';
      case 'weekend':
        return '周末';
      case 'holiday':
        return '节假日';
      case 'all':
        return '随时';
      default:
        return usualDevotionTime ?? '未填写';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _getGenderIcon(String? gender) {
    switch (gender?.toLowerCase()) {
      case 'male':
      case '男':
        return '♂';
      case 'female':
      case '女':
        return '♀';
      default:
        return '•';
    }
  }

  Color _getGenderColor(String? gender) {
    switch (gender?.toLowerCase()) {
      case 'male':
      case '男':
        return Colors.blue;
      case 'female':
      case '女':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  static String _formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return '刚刚';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks}星期前';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '${months}个月前';
    } else {
      final years = (difference.inDays / 365).floor();
      return '${years}年前';
    }
  }
}

class VolunteerApplicationCard extends StatelessWidget {
  final VolunteerApplication application;
  final VoidCallback onTap;

  const VolunteerApplicationCard({
    super.key,
    required this.application,
    required this.onTap,
  });

  bool get _isNewApplication {
    final now = DateTime.now();
    final difference = now.difference(application.submitTime);
    return difference.inHours < 24;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: RoomColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    // 头像
                    _buildAvatar(),
                    const SizedBox(width: 14),
                    // 信息
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 姓名行
                          Row(
                            children: [
                              Text(
                                application.name,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: RoomColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildGenderBadge(),
                              if (application.age != null) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: RoomColors.textGrey.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${application.age}岁',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: RoomColors.textGrey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          // 电话
                          _buildInfoRow(
                            icon: Icons.phone_outlined,
                            text: application.phone ?? '未填写手机号',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // 新申请 badge - 最上面
              if (_isNewApplication)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.red.shade400,
                          Colors.red.shade500,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Text(
                      '新',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              // 时间 - 右上角，在badge下方
              Positioned(
                right: 8,
                top: _isNewApplication ? 26 : 8,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.schedule_outlined,
                      size: 10,
                      color: RoomColors.textGrey,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      _formatRelativeTime(application.submitTime),
                      style: TextStyle(
                        fontSize: 10,
                        color: RoomColors.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            RoomColors.primary.withOpacity(0.15),
            RoomColors.primary.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          '${VolunteerApplicationService.baseUrl}/api/files/temp/image/${application.accessToken}/${application.lifePhoto}',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: Icon(
                Icons.person_outline,
                size: 28,
                color: RoomColors.primary.withOpacity(0.5),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildGenderBadge() {
    final isMale = application.gender?.toLowerCase() == 'male' ||
        application.gender == '男';
    final isFemale = application.gender?.toLowerCase() == 'female' ||
        application.gender == '女';

    Color bgColor;
    Color textColor;
    String text;

    if (isMale) {
      bgColor = const Color(0xFFE3F2FD);
      textColor = const Color(0xFF1976D2);
      text = '男';
    } else if (isFemale) {
      bgColor = const Color(0xFFFCE4EC);
      textColor = const Color(0xFFC2185B);
      text = '女';
    } else {
      bgColor = RoomColors.divider;
      textColor = RoomColors.textGrey;
      text = '未知';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String text,
    Color? iconColor,
    Color? textColor,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: iconColor ?? RoomColors.textSecondary,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: textColor ?? RoomColors.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  static String _formatRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return '刚刚';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks}周前';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '${months}个月前';
    } else {
      final years = (difference.inDays / 365).floor();
      return '${years}年前';
    }
  }
}

// 身份证号显示组件 - 支持双击切换显示/隐藏
class IdCardNumberDisplay extends StatefulWidget {
  final String idCardNumber;

  const IdCardNumberDisplay({
    super.key,
    required this.idCardNumber,
  });

  @override
  State<IdCardNumberDisplay> createState() => _IdCardNumberDisplayState();
}

class _IdCardNumberDisplayState extends State<IdCardNumberDisplay> {
  bool _isVisible = false;

  String _getMaskedIdCard(String idCard) {
    if (idCard.length < 8) return idCard;
    // 显示前3位和后4位，中间用*代替
    return '${idCard.substring(0, 3)}***********${idCard.substring(idCard.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    final displayText = _isVisible ? widget.idCardNumber : _getMaskedIdCard(widget.idCardNumber);

    return GestureDetector(
      onDoubleTap: () {
        setState(() {
          _isVisible = !_isVisible;
        });
      },
      child: Text(
        displayText,
        style: TextStyle(
          fontSize: 13,
          color: RoomColors.textPrimary,
          fontFamily: 'monospace',
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
