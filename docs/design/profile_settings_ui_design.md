# 个人中心/设置页 UI 设计文档

## 概述
本文档记录数字般若-房间管理 APP 中个人中心/设置页的 UI 设计，方便后续复用。

## 页面结构

```
SingleChildScrollView
├── 用户信息卡片
├── 统计数据卡片（三列）
├── 功能管理菜单组
├── 系统菜单组
└── 退出登录按钮
```

## 1. 用户信息卡片

### 效果
左侧显示用户头像（首字母），中间显示用户名和ID，右侧显示箭头。

### 代码

```dart
Container(
  margin: const EdgeInsets.all(12),
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: RoomColors.cardBg,
    borderRadius: BorderRadius.circular(8),
  ),
  child: Row(
    children: [
      // 头像
      Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: RoomColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            userName.substring(0, 1).toUpperCase(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: RoomColors.primary,
            ),
          ),
        ),
      ),
      const SizedBox(width: 16),
      // 用户信息
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              userName,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: RoomColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'ID: $userId',
              style: TextStyle(
                fontSize: 13,
                color: RoomColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
      // 箭头
      Icon(
        Icons.chevron_right,
        color: RoomColors.textSecondary,
      ),
    ],
  ),
)
```

### 样式规范

| 属性 | 值 |
|------|-----|
| 卡片背景 | `RoomColors.cardBg` (白色) |
| 卡片圆角 | 8 |
| 卡片外边距 | 12 |
| 卡片内边距 | 16 |
| 头像尺寸 | 60x60 |
| 头像背景 | `RoomColors.primary.withOpacity(0.1)` |
| 头像文字 | 24, FontWeight.w600, `RoomColors.primary` |
| 用户名 | 18, FontWeight.w600, `RoomColors.textPrimary` |
| ID文字 | 13, `RoomColors.textSecondary` |

---

## 2. 统计数据卡片

### 效果
三列等宽统计，中间用竖线分隔。

### 代码

```dart
Container(
  margin: const EdgeInsets.symmetric(horizontal: 12),
  padding: const EdgeInsets.symmetric(vertical: 16),
  decoration: BoxDecoration(
    color: RoomColors.cardBg,
    borderRadius: BorderRadius.circular(8),
  ),
  child: Row(
    children: [
      Expanded(
        child: _buildStatItem('文章', '12', RoomColors.primary),
      ),
      Container(
        width: 1,
        height: 30,
        color: RoomColors.divider,
      ),
      Expanded(
        child: _buildStatItem('收藏', '36', RoomColors.occupied),
      ),
      Container(
        width: 1,
        height: 30,
        color: RoomColors.divider,
      ),
      Expanded(
        child: _buildStatItem('评论', '89', RoomColors.available),
      ),
    ],
  ),
)

Widget _buildStatItem(String label, String value, Color color) {
  return Column(
    children: [
      Text(
        value,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: RoomColors.textSecondary,
        ),
      ),
    ],
  );
}
```

### 样式规范

| 属性 | 值 |
|------|-----|
| 卡片背景 | `RoomColors.cardBg` |
| 圆角 | 8 |
| 水平外边距 | 12 |
| 垂直内边距 | 16 |
| 数值字体 | 20, FontWeight.w700 |
| 标签字体 | 12, `RoomColors.textSecondary` |
| 分隔线 | 宽1, 高30, `RoomColors.divider` |

---

## 3. 菜单组

### 效果
带标题分组的菜单列表，每项有图标、标题和右箭头，项之间有分隔线。

### 代码

```dart
Widget _buildMenuSection(String title, List<_MenuItem> items) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: RoomColors.cardBg,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 分组标题
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 12, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: RoomColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        // 菜单项
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Column(
            children: [
              ListTile(
                leading: Icon(item.icon, color: RoomColors.textPrimary, size: 22),
                title: Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 15,
                    color: item.color ?? RoomColors.textPrimary,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right,
                  color: RoomColors.textSecondary,
                  size: 20,
                ),
                onTap: item.onTap,
              ),
              // 分隔线（最后一项不显示）
              if (index < items.length - 1)
                Divider(
                  height: 1,
                  indent: 56,
                  color: RoomColors.divider,
                ),
            ],
          );
        }).toList(),
      ],
    ),
  );
}

// 菜单项数据类
class _MenuItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color? color;

  _MenuItem(this.icon, this.title, this.onTap, {this.color});
}
```

### 使用示例

```dart
_buildMenuSection('功能管理', [
  _MenuItem(Icons.edit, '编辑资料', () {}),
  _MenuItem(Icons.lock_outline, '修改密码', () {}),
  _MenuItem(Icons.notifications_outlined, '消息通知', () {}),
]),

_buildMenuSection('系统', [
  _MenuItem(Icons.help_outline, '帮助中心', () {}),
  _MenuItem(Icons.info_outline, '关于我们', () {}),
]),
```

### 样式规范

| 属性 | 值 |
|------|-----|
| 卡片背景 | `RoomColors.cardBg` |
| 圆角 | 8 |
| 水平外边距 | 12 |
| 分组标题 | 13, FontWeight.w500, `RoomColors.textSecondary` |
| 标题内边距 | left: 16, top: 12, bottom: 8 |
| 图标大小 | 22, `RoomColors.textPrimary` |
| 菜单文字 | 15, `RoomColors.textPrimary` |
| 右箭头 | 20, `RoomColors.textSecondary` |
| 分隔线 | height: 1, indent: 56, `RoomColors.divider` |

---

## 4. 退出登录按钮

### 效果
红色文字和图标的列表项。

### 代码

```dart
Container(
  margin: const EdgeInsets.symmetric(horizontal: 12),
  decoration: BoxDecoration(
    color: RoomColors.cardBg,
    borderRadius: BorderRadius.circular(8),
  ),
  child: ListTile(
    leading: Icon(Icons.logout, color: RoomColors.occupied),
    title: Text(
      '退出登录',
      style: TextStyle(color: RoomColors.occupied),
    ),
    onTap: onLogout,
  ),
)
```

### 样式规范

| 属性 | 值 |
|------|-----|
| 图标颜色 | `RoomColors.occupied` (红色) |
| 文字颜色 | `RoomColors.occupied` |

---

## 5. 关于对话框

### 代码

```dart
void _showAboutDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: RoomColors.cardBg,
      title: Text(
        '关于',
        style: TextStyle(color: RoomColors.textPrimary),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '数字般若-房间管理',
            style: TextStyle(
              color: RoomColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '版本: 1.0.0',
            style: TextStyle(color: RoomColors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            '© 2026 All Rights Reserved',
            style: TextStyle(color: RoomColors.textSecondary),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            '确定',
            style: TextStyle(color: RoomColors.primary),
          ),
        ),
      ],
    ),
  );
}
```

---

## 完整页面代码

```dart
Widget _buildProfilePage() {
  return SingleChildScrollView(
    child: Column(
      children: [
        // 用户信息卡片
        _buildUserCard(),
        
        const SizedBox(height: 12),
        
        // 统计数据
        _buildStatsCard(),
        
        const SizedBox(height: 12),
        
        // 功能列表
        _buildMenuSection('功能管理', [
          _MenuItem(Icons.edit, '编辑资料', () {}),
          _MenuItem(Icons.lock_outline, '修改密码', () {}),
          _MenuItem(Icons.notifications_outlined, '消息通知', () {}),
        ]),
        
        const SizedBox(height: 12),
        
        _buildMenuSection('系统', [
          _MenuItem(Icons.help_outline, '帮助中心', () {}),
          _MenuItem(Icons.info_outline, '关于我们', () {
            _showAboutDialog(context);
          }),
        ]),
        
        const SizedBox(height: 12),
        
        // 退出登录
        _buildLogoutButton(),
        
        const SizedBox(height: 24),
      ],
    ),
  );
}
```

---

## 颜色配置

```dart
class RoomColors {
  static const Color primary = Color(0xFF07C160);
  static const Color cardBg = Colors.white;
  static const Color background = Color(0xFFF5F5F5);
  static const Color textPrimary = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF666666);
  static const Color divider = Color(0xFFE5E5E5);
  static const Color occupied = Color(0xFFFF4D4F);
  static const Color available = Color(0xFF07C160);
}
```
