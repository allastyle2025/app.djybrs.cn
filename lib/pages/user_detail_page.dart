import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/user_service.dart';

class UserDetailPage extends StatefulWidget {
  final User user;

  const UserDetailPage({super.key, required this.user});

  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  late User _user;
  bool _isLoading = false;
  bool _isEditing = false;
  String _selectedRole = '';
  
  final _formKey = GlobalKey<FormState>();
  final _userNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _nicknameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    _userNameController.text = _user.userName;
    _emailController.text = _user.email ?? '';
    _selectedRole = _user.role ?? 'user';
    _mobileController.text = _user.mobile ?? '';
    _nicknameController.text = _user.nickname ?? '';
  }

  @override
  void dispose() {
    _userNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _saveUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedUser = await UserService.updateUser(
        _user.userId,
        {
          'userName': _userNameController.text.trim(),
          'email': _emailController.text.trim(),
          'role': _selectedRole,
          'mobile': _mobileController.text.trim(),
          'nickname': _nicknameController.text.trim(),
        },
      );

      setState(() {
        _user = updatedUser;
        _isEditing = false;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('保存成功'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: $e'),
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
        title: Text(_isEditing ? '编辑用户' : '用户详情'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            ),
          if (!_isEditing)
            PopupMenuButton(
              itemBuilder: (context) {
                return [
                  PopupMenuItem(
                    value: 'change_password',
                    child: const Row(
                      children: [
                        Icon(Icons.lock, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('修改密码'),
                      ],
                    ),
                    onTap: _showChangePasswordDialog,
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: const Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('删除用户'),
                      ],
                    ),
                    onTap: _deleteUser,
                  ),
                ];
              },
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.cancel),
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _userNameController.text = _user.userName;
                  _emailController.text = _user.email ?? '';
                  _selectedRole = _user.role ?? 'user';
                });
              },
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _isLoading ? null : _saveUser,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 头像
              Center(
                child: CircleAvatar(
                  radius: 60,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    _user.userName.isNotEmpty ? _user.userName[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      fontSize: 48,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 用户ID
              _buildInfoRow('用户ID', '${_user.userId}', Icons.person),

              // 用户名
              _buildEditableField(
                label: '用户名',
                controller: _userNameController,
                enabled: _isEditing,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '用户名不能为空';
                  }
                  return null;
                },
              ),

              // 邮箱
              _buildEditableField(
                label: '邮箱',
                controller: _emailController,
                enabled: _isEditing,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    if (!value.contains('@')) {
                      return '邮箱格式不正确';
                    }
                  }
                  return null;
                },
              ),

              // 角色
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '角色',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (!_isEditing)
                      Text(
                        _selectedRole,
                        style: const TextStyle(fontSize: 16),
                      )
                    else
                      DropdownButtonFormField<String>(
                        value: _selectedRole,
                        onChanged: (value) {
                          setState(() {
                            _selectedRole = value!;
                          });
                        },
                        items: ['admin', 'user'].map((role) {
                          return DropdownMenuItem<String>(
                            value: role,
                            child: Text(role == 'admin' ? '管理员' : '普通用户'),
                          );
                        }).toList(),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 12.0,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // 手机号
              _buildEditableField(
                label: '手机号',
                controller: _mobileController,
                enabled: _isEditing,
                keyboardType: TextInputType.phone,
              ),

              // 昵称
              _buildEditableField(
                label: '昵称',
                controller: _nicknameController,
                enabled: _isEditing,
              ),

              // 注册时间
              if (_user.createdAt != null)
                _buildInfoRow('注册时间', _formatDate(_user.createdAt!), Icons.calendar_today),

              const SizedBox(height: 32),

              // 统计信息
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '统计信息',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildStatItem('发布文章', '12', Icons.article),
                      _buildStatItem('收藏文章', '36', Icons.favorite),
                      _buildStatItem('评论数', '89', Icons.comment),
                      _buildStatItem('登录次数', '156', Icons.login),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required bool enabled,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            enabled: enabled,
            keyboardType: keyboardType,
            validator: validator,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // 删除用户
  Future<void> _deleteUser() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('删除用户'),
          content: Text('确定要删除用户 "${_user.userName}" 吗？此操作不可恢复。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('删除', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        final success = await UserService.deleteUser(_user.userId);
        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('用户删除成功'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
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
  }

  // 显示修改密码对话框
  void _showChangePasswordDialog() {
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('修改密码'),
              content: Form(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: newPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: '新密码',
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(),
                      ),
                      enabled: !isLoading,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: confirmPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: '确认新密码',
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(),
                      ),
                      enabled: !isLoading,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () {
                          newPasswordController.dispose();
                          confirmPasswordController.dispose();
                          Navigator.of(context).pop();
                        },
                  child: const Text('取消'),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
                          if (newPasswordController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('请输入新密码')),
                            );
                            return;
                          }
                          if (newPasswordController.text.length < 5) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('新密码至少5位')),
                            );
                            return;
                          }
                          if (confirmPasswordController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('请确认新密码')),
                            );
                            return;
                          }
                          if (newPasswordController.text != confirmPasswordController.text) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('两次输入的密码不一致')),
                            );
                            return;
                          }

                          setDialogState(() {
                            isLoading = true;
                          });

                          try {
                            await UserService.updateUser(
                              _user.userId,
                              {'password': newPasswordController.text},
                            );

                            if (context.mounted) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('密码修改成功'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('修改失败: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } finally {
                            setDialogState(() {
                              isLoading = false;
                            });
                          }
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('确认'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
