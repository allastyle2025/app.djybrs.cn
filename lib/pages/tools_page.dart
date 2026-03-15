import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../components/menu_section.dart';
import '../room_colors.dart';
import 'room/check_in_records_page.dart';
import 'room/check_in_registration_page.dart';
import 'room/current_check_ins_page.dart';
import 'cgh_user_management_page.dart';
import 'volunteer_application_page.dart';
import 'inventory/warehouse_home_page.dart';
import 'schedule/schedule_page.dart';

class ToolsPage extends StatefulWidget {
  const ToolsPage({super.key});

  @override
  State<ToolsPage> createState() => ToolsPageState();
}

class ToolsPageState extends State<ToolsPage> {
  bool _showVolunteerApplication = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _showVolunteerApplication =
          prefs.getBool('showVolunteerApplication') ?? false;
    });
  }

  // 公共刷新方法，供外部调用
  Future<void> refreshSettings() async {
    await _loadSettings();
  }

  Widget _buildQuickAccessGrid() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RoomColors.cardBg,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '快捷入口',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: RoomColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.spaceEvenly,
              children: [
                _buildQuickAccessItem(
                  icon: Icons.app_registration,
                  label: '登记入住',
                  color: RoomColors.primary,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CheckInRegistrationPage(),
                      ),
                    );
                  },
                ),
                _buildQuickAccessItem(
                  icon: Icons.people_outline,
                  label: '在寺人员',
                  color: Colors.indigo,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CurrentCheckInsPage(),
                      ),
                    );
                  },
                ),
                _buildQuickAccessItem(
                  icon: Icons.warehouse_outlined,
                  label: '库房管理',
                  color: Colors.orange,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const WarehouseHomePage(),
                      ),
                    );
                  },
                ),
                _buildQuickAccessItem(
                  icon: Icons.schedule_outlined,
                  label: '排班管理',
                  color: Colors.purple,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SchedulePage(),
                      ),
                    );
                  },
                ),
                // _buildQuickAccessItem(
                //   icon: Icons.receipt_long_outlined,
                //   label: '入住记录表',
                //   color: Colors.orange,
                //   onTap: () {
                //     Navigator.push(
                //       context,
                //       MaterialPageRoute(builder: (context) => const CheckInRecordsPage()),
                //     );
                //   },
                // ),
                // if (_showVolunteerApplication)
                //   _buildQuickAccessItem(
                //     icon: Icons.volunteer_activism_outlined,
                //     label: '义工申请表',
                //     color: Colors.green,
                //     onTap: () {
                //       Navigator.push(
                //         context,
                //         MaterialPageRoute(builder: (context) => const VolunteerApplicationPage()),
                //       );
                //     },
                //   ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.15), color.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 24, color: color),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: RoomColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 12),
          // Grid 形式快捷入口
          _buildQuickAccessGrid(),
          const SizedBox(height: 12),
          MenuSection(
            title: '数据',
            items: [
              MenuItem(
                icon: Icons.bed_outlined,
                title: '义工申请表',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const VolunteerApplicationPage(),
                    ),
                  );
                },
              ),
              MenuItem(
                icon: Icons.receipt_long_outlined,
                title: '入住登记表',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CheckInRecordsPage(),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 12),
          MenuSection(
            title: '管理',
            items: [
              MenuItem(
                icon: Icons.warehouse_outlined,
                title: '库房管理',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WarehouseHomePage(),
                    ),
                  );
                },
              ),
              MenuItem(
                icon: Icons.schedule_outlined,
                title: '排班管理',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SchedulePage(),
                    ),
                  );
                },
              ),
              MenuItem(
                icon: Icons.people_outline,
                title: '人员管理',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CghUserManagementPage(),
                    ),
                  );
                },
              )
            ],
          ),

          // 其他菜单（暂时隐藏）
          // const SizedBox(height: 12),
          // MenuSection(
          //   title: '其他',
          //   items: [
          //     MenuItem(
          //       icon: Icons.people_outline,
          //       title: '用户管理',
          //       onTap: () {
          //         Navigator.push(
          //           context,
          //           MaterialPageRoute(builder: (context) => const UserManagementPage()),
          //         );
          //       },
          //     ),
          //     MenuItem(icon: Icons.help_outline, title: '帮助中心', onTap: () {}),
          //     MenuItem(icon: Icons.feedback_outlined, title: '意见反馈', onTap: () {}),
          //   ],
          // ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
