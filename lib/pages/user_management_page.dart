import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import 'user_detail_page.dart';
import 'login_page.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  List<User> _users = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  final int _perPage = 20;
  String? _errorMessage;
  String _searchKeyword = '';
  
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 检查登录状态
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
    _loadUsers();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _loadMoreUsers();
      }
    }
  }

  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await UserService.getUsers(
        page: _currentPage,
        perPage: _perPage,
      );

      setState(() {
        _users = response.users;
        _hasMore = response.currentPage < response.lastPage;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreUsers() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await UserService.getUsers(
        page: _currentPage + 1,
        perPage: _perPage,
      );

      setState(() {
        _users.addAll(response.users);
        _currentPage++;
        _hasMore = response.currentPage < response.lastPage;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _searchUsers(String keyword) async {
    if (keyword.isEmpty) {
      _currentPage = 1;
      _loadUsers();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await UserService.searchUsers(keyword);

      setState(() {
        _users = response.users;
        _hasMore = false;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteUser(User user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除用户 "${user.userName}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await UserService.deleteUser(user.userId);
      if (mounted) {
        setState(() {
          _users.remove(user);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('删除成功'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('删除失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('用户管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddUserDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _currentPage = 1;
              _searchController.clear();
              _loadUsers();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 搜索栏
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '搜索用户...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _currentPage = 1;
                          _loadUsers();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              onSubmitted: _searchUsers,
            ),
          ),
          
          // 错误提示
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(16.0),
              color: Colors.red.shade100,
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  TextButton(
                    onPressed: _loadUsers,
                    child: const Text('重试'),
                  ),
                ],
              ),
            ),
          
          // 用户列表
          Expanded(
            child: _users.isEmpty && !_isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          '暂无用户',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      _currentPage = 1;
                      await _loadUsers();
                    },
                    displacement: 60,
                    strokeWidth: 2.5,
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: _users.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _users.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final user = _users[index];
                        return UserCard(
                          user: user,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UserDetailPage(user: user),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // 显示添加用户对话框
  void _showAddUserDialog() {
    final _formKey = GlobalKey<FormState>();
    final _usernameController = TextEditingController();
    final _emailController = TextEditingController();
    final _mobileController = TextEditingController();
    final _ageController = TextEditingController();
    final _passwordController = TextEditingController();
    final _nicknameController = TextEditingController();
    String _selectedRole = 'user';
    bool _isLoading = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('添加用户'),
              content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: '用户名',
                          hintText: '请输入用户名',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '用户名不能为空';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: '邮箱',
                          hintText: '请输入邮箱',
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '邮箱不能为空';
                          }
                          if (!value.contains('@')) {
                            return '邮箱格式不正确';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _mobileController,
                        decoration: const InputDecoration(
                          labelText: '手机号',
                          hintText: '请输入手机号',
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '手机号不能为空';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _ageController,
                        decoration: const InputDecoration(
                          labelText: '年龄',
                          hintText: '请输入年龄',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '年龄不能为空';
                          }
                          if (int.tryParse(value) == null) {
                            return '年龄必须是数字';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: const InputDecoration(
                          labelText: '密码',
                          hintText: '请输入密码',
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return '密码不能为空';
                          }
                          if (value.length < 6) {
                            return '密码长度不能少于6位';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedRole,
                        onChanged: (value) {
                          _selectedRole = value!;
                        },
                        items: ['admin', 'user'].map((role) {
                          return DropdownMenuItem<String>(
                            value: role,
                            child: Text(role == 'admin' ? '管理员' : '普通用户'),
                          );
                        }).toList(),
                        decoration: const InputDecoration(
                          labelText: '角色',
                          hintText: '请选择角色',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '角色不能为空';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nicknameController,
                        decoration: const InputDecoration(
                          labelText: '昵称',
                          hintText: '请输入昵称',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _isLoading ? null : () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: _isLoading ? null : () async {
                    if (_formKey.currentState!.validate()) {
                      setState(() {
                        _isLoading = true;
                      });

                      try {
                        final newUser = await UserService.createUser({
                          'username': _usernameController.text.trim(),
                          'email': _emailController.text.trim(),
                          'mobile': _mobileController.text.trim(),
                          'age': _ageController.text.trim(),
                          'password': _passwordController.text.trim(),
                          'role': _selectedRole,
                          'nickname': _nicknameController.text.trim(),
                        });

                        if (mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('用户添加成功'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          // 重新加载用户列表
                          _currentPage = 1;
                          _loadUsers();
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('添加失败: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } finally {
                        setState(() {
                          _isLoading = false;
                        });
                      }
                    }
                  },
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(),
                        )
                      : const Text('添加'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class UserCard extends StatelessWidget {
  final User user;
  final VoidCallback onTap;

  const UserCard({
    super.key,
    required this.user,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Text(
            user.userName.isNotEmpty ? user.userName[0].toUpperCase() : 'U',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        title: Text(
          user.userName,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user.email != null)
              Text(
                user.email!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            if (user.role != null)
              Text(
                '角色: ${user.role}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            if (user.createdAt != null)
              Text(
                '注册时间: ${_formatDate(user.createdAt!)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.visibility, color: Colors.grey),
          onPressed: onTap,
          tooltip: '查看',
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
