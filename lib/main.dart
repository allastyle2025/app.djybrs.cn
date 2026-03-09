import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pages/login_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/server_settings_page.dart';
import 'room_colors.dart';
import 'services/auth_service.dart';
import 'services/room_service.dart';
import 'theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RoomService.init(); // 加载服务器地址
  await AuthService.init(); // 加载用户信息

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'DP 房间管理',
      debugShowCheckedModeBanner: false,
      theme: themeProvider.getThemeData(context),
      home: const SplashPage(), // 启动时显示加载页面
    );
  }
}

// 启动加载页面
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // 延迟3秒让用户看到加载动画
    await Future.delayed(const Duration(seconds: 3));

    // 如果已登录，验证token有效性
    if (AuthService.isLoggedIn) {
      print('用户已登录，开始验证Token...');
      final result = await AuthService.verifyToken();
      final isTokenValid = result['valid'] ?? false;
      final isServerError = result['serverError'] ?? false;
      final serverErrorMessage = result['message'] ?? '';
      print('Token验证结果: $isTokenValid, 服务器错误: $isServerError');

      if (mounted) {
        if (isServerError) {
          // 服务器错误，显示错误页面
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ServerErrorPage(message: serverErrorMessage),
            ),
          );
        } else if (isTokenValid) {
          // Token有效，进入首页
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const DashboardPage(),
            ),
          );
        } else {
          // Token无效，进入登录页
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const LoginPage(),
            ),
          );
        }
      }
    } else {
      // 未登录，进入登录页
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const LoginPage(),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RoomColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App 图标
            Image.asset(
              'assets/icon/icon.png',
              width: 100,
              height: 100,
            ),
            const SizedBox(height: 32),
            // App 名称
            Text(
              'DP 房间管理',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: RoomColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '数字般若',
              style: TextStyle(
                fontSize: 14,
                color: RoomColors.textSecondary,
              ),
            ),
            const SizedBox(height: 48),
            // 加载指示器
            SizedBox(
              width: 120,
              child: LinearProgressIndicator(
                backgroundColor: RoomColors.divider,
                valueColor: AlwaysStoppedAnimation<Color>(RoomColors.primary),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 服务器错误页面
class ServerErrorPage extends StatelessWidget {
  final String message;

  const ServerErrorPage({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RoomColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_off,
                size: 64,
                color: RoomColors.occupied,
              ),
              const SizedBox(height: 24),
              Text(
                '无法连接到服务器',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: RoomColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message.isNotEmpty ? message : '请检查服务器地址设置或网络连接',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: RoomColors.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  // 跳转到服务器设置页面
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ServerSettingsPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.settings),
                label: const Text('去设置服务器地址'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: RoomColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
