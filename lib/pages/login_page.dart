import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../room_colors.dart';
import '../services/auth_service.dart';
import 'dashboard_page.dart';
import 'server_settings_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUsername = prefs.getString('saved_username');
    final savedPassword = prefs.getString('saved_password');
    final rememberMe = prefs.getBool('remember_me') ?? false;

    if (mounted) {
      setState(() {
        _rememberMe = rememberMe;
        if (rememberMe && savedUsername != null) {
          _usernameController.text = savedUsername;
        }
        if (rememberMe && savedPassword != null) {
          _passwordController.text = savedPassword;
        }
      });
    }
  }

  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('saved_username', _usernameController.text.trim());
      await prefs.setString('saved_password', _passwordController.text);
      await prefs.setBool('remember_me', true);
    } else {
      await prefs.remove('saved_username');
      await prefs.remove('saved_password');
      await prefs.setBool('remember_me', false);
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final response = await AuthService.login(
      _usernameController.text.trim(),
      _passwordController.text,
    );

    setState(() {
      _isLoading = false;
    });

    if (response.success) {
      if (mounted) {
        // 保存登录信息（如果勾选了记住登录）
        await _saveCredentials();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('欢迎回来，${response.user?.userName ?? ''}'),
            backgroundColor: RoomColors.available,
          ),
        );
        
        // 跳转到Dashboard主页
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const DashboardPage(),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: RoomColors.occupied,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RoomColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            // 服务器设置按钮（右上角）
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ServerSettingsPage(),
                    ),
                  );
                },
                icon: Icon(
                  Icons.language,
                  color: RoomColors.textSecondary,
                ),
                tooltip: '服务器设置',
              ),
            ),
            // 登录表单
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    // Logo区域
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: RoomColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.account_circle,
                          size: 48,
                          color: RoomColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                
                // 标题
                Text(
                  'DP 房间管理',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: RoomColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '请登录以继续',
                  style: TextStyle(
                    fontSize: 14,
                    color: RoomColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),

                // 登录表单卡片
                Container(
                  decoration: BoxDecoration(
                    color: RoomColors.cardBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // 用户名输入框
                        _buildTextField(
                          controller: _usernameController,
                          hintText: '请输入用户名',
                          prefixIcon: Icons.person_outline,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return '请输入用户名';
                            }
                            return null;
                          },
                          textInputAction: TextInputAction.next,
                        ),
                        Divider(height: 1, color: RoomColors.divider),
                        
                        // 密码输入框
                        _buildTextField(
                          controller: _passwordController,
                          hintText: '请输入密码',
                          prefixIcon: Icons.lock_outline,
                          obscureText: _obscurePassword,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: RoomColors.textSecondary,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return '请输入密码';
                            }
                            if (value.length < 5) {
                              return '密码至少5位';
                            }
                            return null;
                          },
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _login(),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // 记住登录复选框
                Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: (value) {
                        setState(() {
                          _rememberMe = value ?? false;
                        });
                      },
                      activeColor: RoomColors.primary,
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _rememberMe = !_rememberMe;
                        });
                      },
                      child: Text(
                        '记住登录',
                        style: TextStyle(
                          color: RoomColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 登录按钮
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: RoomColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            '登 录',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 16),

                // 忘记密码
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('请联系管理员重置密码'),
                        backgroundColor: RoomColors.textSecondary,
                      ),
                    );
                  },
                  child: Text(
                    '忘记密码？',
                    style: TextStyle(
                      color: RoomColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    TextInputAction? textInputAction,
    Function(String)? onSubmitted,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: RoomColors.textSecondary,
          fontSize: 15,
        ),
        prefixIcon: Icon(
          prefixIcon,
          color: RoomColors.textSecondary,
          size: 22,
        ),
        suffixIcon: suffixIcon,
        border: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
    );
  }
}
