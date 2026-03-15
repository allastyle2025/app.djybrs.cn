import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/schedule/person.dart';
import '../../models/schedule/position.dart';
import '../../models/schedule/schedule_assignment.dart';
import '../../models/room_check_in.dart';
import '../../services/room_service.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  List<Person> _allPersons = [];
  bool _isLoading = true;
  String _errorMessage = '';

  final List<Position> _positions = [
    Position(
      id: 1,
      name: '扫地',
      description: '负责寺院地面清洁',
      maxCapacity: 3,
      color: '#4CAF50',
      icon: '🧹',
    ),
    Position(
      id: 2,
      name: '做饭',
      description: '负责斋堂饭菜制作',
      maxCapacity: 4,
      color: '#FF9800',
      icon: '🍳',
    ),
    Position(
      id: 3,
      name: '洗衣服',
      description: '负责衣物清洗',
      maxCapacity: 2,
      color: '#2196F3',
      icon: '👕',
    ),
    Position(
      id: 4,
      name: '接待',
      description: '负责访客接待',
      maxCapacity: 2,
      color: '#9C27B0',
      icon: '👋',
    ),
    Position(
      id: 5,
      name: '园艺',
      description: '负责花草养护',
      maxCapacity: 2,
      color: '#795548',
      icon: '🌿',
    ),
  ];

  Map<int, List<int>> _assignments = {}; // positionId -> list of personIds
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadVolunteerData();
    _loadAssignments();
  }

  Future<void> _loadVolunteerData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await RoomService.getCurrentCheckIns();
      
      if (response.isSuccess) {
        final checkIns = response.data;
        
        // 过滤出身份为义工的人员（purpose为'volunteer'且状态为'CHECKED_IN'）
        final volunteerCheckIns = checkIns.where((checkIn) {
          return checkIn.purpose == 'volunteer' && checkIn.status == 'CHECKED_IN';
        }).toList();
        
        // 转换为Person对象
        final volunteers = volunteerCheckIns.map((checkIn) {
          return Person(
            id: checkIn.userId, // 使用userId作为唯一标识
            name: checkIn.cname,
            department: _getDepartmentFromRoomArea(checkIn.roomArea),
            avatar: null,
            isAvailable: true,
          );
        }).toList();
        
        setState(() {
          _allPersons = volunteers;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '加载义工数据失败: $e';
        _isLoading = false;
      });
    }
  }

  String _getDepartmentFromRoomArea(String roomArea) {
    switch (roomArea) {
      case 'hy':
        return '华严殿';
      case 'yd':
        return '圆通殿';
      case 'be':
        return '报恩';
      case 'zts':
        return '斋堂上';
      case 'ktx':
        return '客堂下';
      case 'cz':
        return '常住';
      case 'ld':
        return '老殿';
      case 'wz':
        return '外';
      case 'other':
        return '其他';
      default:
        return roomArea;
    }
  }

  Future<void> _loadAssignments() async {
    final prefs = await SharedPreferences.getInstance();
    final dateKey = _selectedDate.toIso8601String().split('T')[0];
    final assignmentsJson = prefs.getString('schedule_$dateKey');
    
    if (assignmentsJson != null) {
      try {
        final assignments = ScheduleAssignment.fromJson(
          Map<String, dynamic>.from(assignmentsJson as Map)
        );
        setState(() {
          _assignments[assignments.positionId] = assignments.personIds;
        });
      } catch (e) {
        // 如果解析失败，使用空数据
        _initializeAssignments();
      }
    } else {
      _initializeAssignments();
    }
  }

  void _initializeAssignments() {
    setState(() {
      _assignments = {};
      for (final position in _positions) {
        _assignments[position.id] = [];
      }
    });
  }

  Future<void> _saveAssignments() async {
    final prefs = await SharedPreferences.getInstance();
    final dateKey = _selectedDate.toIso8601String().split('T')[0];
    
    for (final entry in _assignments.entries) {
      final assignment = ScheduleAssignment(
        positionId: entry.key,
        personIds: entry.value,
        date: _selectedDate,
      );
      await prefs.setString(
        'schedule_${dateKey}_${entry.key}',
        assignment.toJson().toString(),
      );
    }
  }

  void _assignPersonToPosition(int personId, int positionId) {
    setState(() {
      // 先从其他岗位移除该人员
      for (final entry in _assignments.entries) {
        if (entry.value.contains(personId)) {
          entry.value.remove(personId);
        }
      }
      
      // 添加到目标岗位
      if (!_assignments[positionId]!.contains(personId)) {
        _assignments[positionId]!.add(personId);
      }
      
      _saveAssignments();
    });
  }

  void _removePersonFromPosition(int personId, int positionId) {
    setState(() {
      _assignments[positionId]!.remove(personId);
      _saveAssignments();
    });
  }

  Person _getPersonById(int id) {
    return _allPersons.firstWhere((person) => person.id == id);
  }

  Position _getPositionById(int id) {
    return _positions.firstWhere((position) => position.id == id);
  }

  List<Person> _getAvailablePersons() {
    final assignedPersonIds = _assignments.values.expand((ids) => ids).toSet();
    return _allPersons.where((person) => !assignedPersonIds.contains(person.id)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('排班管理'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('正在加载义工数据...'),
                ],
              ),
            )
          : _errorMessage.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage,
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadVolunteerData,
                        child: const Text('重新加载'),
                      ),
                    ],
                  ),
                )
              : _allPersons.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 48,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '当前没有可用的义工',
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '请先添加身份为义工的入住人员',
                            style: TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        // 人员列表（顶部）
                        Container(
                          height: 120,
                          child: _buildPersonList(),
                        ),
                        
                        // 分隔线
                        Container(
                          height: 1,
                          color: Colors.grey.shade300,
                        ),
                        
                        // 岗位区块（底部）
                        Expanded(
                          child: _buildPositionList(),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildPersonList() {
    final availablePersons = _getAvailablePersons();
    
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '可分配人员 (${availablePersons.length}/${_allPersons.length})',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.5,
              ),
              itemCount: availablePersons.length,
              itemBuilder: (context, index) {
                final person = availablePersons[index];
                return _buildPersonItem(person);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonItem(Person person) {
    return Draggable<Person>(
      data: person,
      feedback: Material(
        elevation: 4,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            person.name,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      ),
      childWhenDragging: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          person.name,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade400,
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.blue.shade100),
        ),
        child: Center(
          child: Text(
            person.name,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildPositionList() {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '岗位分配',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: _positions.length,
              itemBuilder: (context, index) {
                final position = _positions[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: _buildPositionCard(position),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPositionCard(Position position) {
    final assignedPersons = _assignments[position.id] ?? [];
    final color = Color(int.parse(position.color.replaceFirst('#', '0xFF')));
    
    return DragTarget<Person>(
      onAccept: (person) {
        if (assignedPersons.length < position.maxCapacity) {
          _assignPersonToPosition(person.id, position.id);
        }
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          height: 120,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: candidateData.isNotEmpty 
                  ? color.withOpacity(0.5) 
                  : color.withOpacity(0.3),
              width: candidateData.isNotEmpty ? 3 : 1,
            ),
          ),
          child: Row(
            children: [
              // 左侧岗位信息
              Container(
                width: 100,
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      position.icon,
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      position.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${assignedPersons.length}/${position.maxCapacity}',
                      style: TextStyle(
                        fontSize: 11,
                        color: color.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              
              // 右侧人员列表
              Expanded(
                child: assignedPersons.isEmpty
                    ? Center(
                        child: Text(
                          '拖拽人员到此',
                          style: TextStyle(
                            fontSize: 12,
                            color: color.withOpacity(0.5),
                          ),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(8),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                          childAspectRatio: 2.5,
                        ),
                        itemCount: assignedPersons.length,
                        itemBuilder: (context, index) {
                          final personId = assignedPersons[index];
                          final person = _getPersonById(personId);
                          return _buildAssignedPersonItem(person, position.id);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAssignedPersonItem(Person person, int positionId) {
    return Draggable<Person>(
      data: person,
      feedback: Material(
        elevation: 4,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            person.name,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
          ),
        ),
      ),
      childWhenDragging: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey.shade300, width: 0.5),
        ),
        child: Text(
          person.name,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade400,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.grey.shade300, width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              person.name,
              style: const TextStyle(fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: () => _removePersonFromPosition(person.id, positionId),
              child: Icon(
                Icons.close,
                size: 10,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}