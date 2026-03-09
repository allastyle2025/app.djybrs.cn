# 统计卡片设计文档

## 概述
本文档记录房间管理 APP 中使用的统计卡片样式，方便后续复用。

## 1. 三列统计卡片

### 效果
横向排列的三个统计项，中间用竖线分隔。

### 代码参考

```dart
// 统计数据
int get _totalRooms => _rooms.length;
int get _occupiedBeds => _rooms.fold(0, (sum, r) => sum + r.occupiedBeds);
int get _availableBeds => _rooms.fold(0, (sum, r) => sum + r.availableBeds);

// 构建方法
@override
Widget build(BuildContext context) {
  return Column(
    children: [
      // 统计概览
      Container(
        color: RoomColors.cardBg,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            _buildStatItem('总房间', '$_totalRooms', RoomColors.textPrimary),
            _buildDivider(),
            _buildStatItem('已入住', '$_occupiedBeds', RoomColors.occupied),
            _buildDivider(),
            _buildStatItem('空床位', '$_availableBeds', RoomColors.available),
          ],
        ),
      ),
    ],
  );
}

// 统计项组件
Widget _buildStatItem(String label, String value, Color color) {
  return Expanded(
    child: Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: RoomColors.textSecondary,
          ),
        ),
      ],
    ),
  );
}

// 分隔线组件
Widget _buildDivider() {
  return Container(
    width: 1,
    height: 30,
    color: RoomColors.divider,
  );
}
```

### 样式规范

| 属性 | 值 |
|------|-----|
| 背景色 | `RoomColors.cardBg` (白色) |
| 水平内边距 | 12 |
| 垂直内边距 | 12 |
| 数值字体大小 | 20 |
| 数值字体粗细 | FontWeight.w700 |
| 标签字体大小 | 12 |
| 分隔线宽度 | 1 |
| 分隔线高度 | 30 |
| 分隔线颜色 | `RoomColors.divider` |

---

## 2. 总体统计卡片（带入住率）

### 效果
顶部显示入住率大数字，底部横向排列四个统计项。

### 代码参考

```dart
Widget _buildOverallStatsCard() {
  final totalRooms = _rooms.length;
  final totalBeds = _rooms.fold(0, (sum, r) => sum + r.totalCapacity);
  final occupiedBeds = _rooms.fold(0, (sum, r) => sum + r.occupiedBeds);
  final availableBeds = totalBeds - occupiedBeds;
  final occupancyRate = totalBeds > 0 ? (occupiedBeds / totalBeds * 100).toInt() : 0;

  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: RoomColors.cardBg,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '总体入住率',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: RoomColors.textPrimary,
              ),
            ),
            Text(
              '$occupancyRate%',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: RoomColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildStatItem('总房间', '$totalRooms', RoomColors.textPrimary),
            ),
            Container(
              width: 1,
              height: 30,
              color: RoomColors.divider,
            ),
            Expanded(
              child: _buildStatItem('总床位', '$totalBeds', RoomColors.textPrimary),
            ),
            Container(
              width: 1,
              height: 30,
              color: RoomColors.divider,
            ),
            Expanded(
              child: _buildStatItem('已入住', '$occupiedBeds', RoomColors.occupied),
            ),
            Container(
              width: 1,
              height: 30,
              color: RoomColors.divider,
            ),
            Expanded(
              child: _buildStatItem('空床位', '$availableBeds', RoomColors.available),
            ),
          ],
        ),
      ],
    ),
  );
}
```

### 样式规范

| 属性 | 值 |
|------|-----|
| 背景色 | `RoomColors.cardBg` (白色) |
| 圆角 | 8 |
| 内边距 | 16 |
| 标题字体大小 | 15 |
| 入住率字体大小 | 24 |
| 入住率颜色 | `RoomColors.primary` |

---

## 3. 颜色配置参考

```dart
class RoomColors {
  static const Color primary = Color(0xFF07C160);
  static const Color cardBg = Colors.white;
  static const Color background = Color(0xFFF5F5F5);
  static const Color textPrimary = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF666666);
  static const Color divider = Color(0xFFE5E5E5);
  static const Color available = Color(0xFF07C160);
  static const Color occupied = Color(0xFFFF4D4F);
  static const Color partial = Color(0xFFFFA940);
}
```

---

## 使用建议

1. **三列统计卡片**：适合页面顶部快速展示核心数据
2. **总体统计卡片**：适合作为首页的概览卡片，信息更丰富
3. 可以根据需要调整统计项的数量和颜色
4. 分隔线可根据视觉需求选择是否显示
