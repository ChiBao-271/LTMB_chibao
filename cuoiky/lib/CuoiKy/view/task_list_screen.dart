import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../models/group.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import './task_form_screen.dart';
import './login_screen.dart';
import './task_detail_screen.dart';
import 'groups/group_management_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final _searchController = TextEditingController();
  String? _selectedStatus;
  String? _selectedGroup;
  List<Task> _myTasks = [];
  List<Task> _assignedTasks = [];
  List<Group> _groups = [];
  Map<String, String?> _usernameCache = {};
  Map<String, bool> _isAdminOfGroupCache = {};
  bool _isLoading = false;
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  String? _currentUserRole;
  String? _currentUserId;

  final Map<String, String> _statusDisplay = {
    'To do': 'Cần làm',
    'In progress': 'Đang làm',
    'Done': 'Đã hoàn thành',
    'Cancelled': 'Đã hủy',
  };

  @override
  void initState() {
    super.initState();
    _loadCurrentUserInfo();
  }

  Future<void> _loadCurrentUserInfo() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('Không có người dùng đăng nhập');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không tìm thấy thông tin người dùng!')),
        );
        return;
      }
      setState(() => _currentUserId = user.uid);
      print('Current user ID loaded: $_currentUserId');
      final role = await _firestoreService.getUserRoleById(user.uid);
      final groups = await _firestoreService.getUserGroups(user.uid);
      setState(() {
        _currentUserRole = role ?? 'user';
        _groups = groups;
      });
      await _loadTasks();
    } catch (e) {
      print('Lỗi khi tải thông tin người dùng: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải thông tin người dùng: $e')),
      );
    }
  }

  Future<bool> _isAdminOfGroup(String? groupId) async {
    if (_currentUserId == null) {
      print('Không có ID người dùng hiện tại, không thể kiểm tra trạng thái admin');
      return false;
    }
    if (groupId == null) {
      print('Không có ID nhóm, không phải công việc nhóm');
      return false;
    }
    if (_isAdminOfGroupCache.containsKey(groupId)) {
      print('Trạng thái admin đã được lưu trữ cho nhóm $groupId: ${_isAdminOfGroupCache[groupId]}');
      return _isAdminOfGroupCache[groupId]!;
    }
    final group = await _firestoreService.getGroup(groupId);
    final isAdmin = group != null && group.adminId == _currentUserId;
    _isAdminOfGroupCache[groupId] = isAdmin;
    print('Đã kiểm tra trạng thái admin cho nhóm $groupId: $isAdmin');
    return isAdmin;
  }

  bool _isTaskMatchingStatus(Task task) {
    if (_selectedStatus == null) return true;
    if (_selectedStatus == 'Incomplete') {
      return task.status == 'To do' || task.status == 'In progress';
    }
    return task.status == _selectedStatus;
  }

  Future<void> _loadTasks() async {
    if (_currentUserId == null) {
      print('Không có ID người dùng hiện tại, không thể tải công việc');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể tải công việc: ID người dùng không hợp lệ!')),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final myTasksStream = _firestoreService.getTasks(
        userId: _currentUserId,
        status: null,
        groupId: _selectedGroup,
      );
      myTasksStream.listen((tasks) async {
        List<Task> loadedMyTasks = [];
        for (var task in tasks) {
          if (task.assignedTo == _currentUserId && _isTaskMatchingStatus(task)) {
            print('Đang tải công việc ${task.id}, createdBy: ${task.createdBy}, assignedTo: ${task.assignedTo}, groupId: ${task.groupId}, status: ${task.status}');
            if (task.dueDate != null &&
                task.status != 'Done' &&
                task.status != 'Cancelled' &&
                DateTime.now().isAfter(task.dueDate!)) {
              await _firestoreService.updateTask(
                task.copyWith(
                  status: 'Cancelled',
                  updatedAt: DateTime.now(),
                  completedAt: DateTime.now(),
                ),
              );
              task = task.copyWith(
                status: 'Cancelled',
                updatedAt: DateTime.now(),
                completedAt: DateTime.now(),
              );
            }
            String username = 'Không có';
            if (task.createdBy != null) {
              if (_usernameCache.containsKey(task.createdBy)) {
                username = _usernameCache[task.createdBy] ?? 'Không có';
              } else {
                final fetchedUsername = await _firestoreService.getUsernameById(task.createdBy!);
                username = fetchedUsername ?? 'Không có';
                _usernameCache[task.createdBy!] = username;
              }
            }
            loadedMyTasks.add(task.copyWith(createdBy: username));
          }
        }
        setState(() => _myTasks = loadedMyTasks);
        print('Đã tải ${_myTasks.length} công việc cho người dùng');
      });

      final assignedTasksStream = _firestoreService.getTasks(
        status: null,
        groupId: _selectedGroup,
      );
      assignedTasksStream.listen((tasks) async {
        List<Task> loadedAssignedTasks = [];
        for (var task in tasks) {
          if (task.createdBy == _currentUserId && task.assignedTo != _currentUserId && _isTaskMatchingStatus(task)) {
            print('Đang tải công việc được giao ${task.id}, createdBy: ${task.createdBy}, assignedTo: ${task.assignedTo}, status: ${task.status}');
            if (task.dueDate != null &&
                task.status != 'Done' &&
                task.status != 'Cancelled' &&
                DateTime.now().isAfter(task.dueDate!)) {
              await _firestoreService.updateTask(
                task.copyWith(
                  status: 'Cancelled',
                  updatedAt: DateTime.now(),
                  completedAt: DateTime.now(),
                ),
              );
              task = task.copyWith(
                status: 'Cancelled',
                updatedAt: DateTime.now(),
                completedAt: DateTime.now(),
              );
            }
            String username = 'Không có';
            if (task.assignedTo != null) {
              if (_usernameCache.containsKey(task.assignedTo)) {
                username = _usernameCache[task.assignedTo] ?? 'Không có';
              } else {
                final fetchedUsername = await _firestoreService.getUsernameById(task.assignedTo!);
                username = fetchedUsername ?? 'Không có';
                _usernameCache[task.assignedTo!] = username;
              }
            }
            loadedAssignedTasks.add(task.copyWith(assignedTo: username));
          }
        }
        setState(() {
          _assignedTasks = loadedAssignedTasks;
          _isLoading = false;
        });
        print('Đã tải ${_assignedTasks.length} công việc được giao');
      });
    } catch (e) {
      print('Lỗi khi tải công việc: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải danh sách công việc: $e')),
      );
    }
  }

  Future<void> _handleSignOut() async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Xác nhận đăng xuất', style: TextStyle(color: Colors.blue[700])),
        content: Text('Bạn có chắc chắn muốn đăng xuất không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Đăng xuất', style: TextStyle(color: Colors.blue[700])),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _authService.signOut();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
              (Route<dynamic> route) => false,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã đăng xuất thành công!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi đăng xuất: $e')),
        );
      }
    }
  }

  Future<void> _handleReload() async {
    setState(() {
      _searchController.clear();
      _selectedStatus = null;
      _selectedGroup = null;
    });
    await _loadTasks();
  }

  Future<void> _handleToggleComplete(Task task) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: Text(
          task.status == 'Done' ? 'Xác nhận hủy hoàn thành' : 'Xác nhận hoàn thành',
          style: TextStyle(color: Colors.blue[700]),
        ),
        content: Text(
            task.status == 'Done'
                ? 'Bạn có muốn hủy trạng thái hoàn thành công việc này không?'
                : 'Bạn có muốn đánh dấu công việc này là hoàn thành không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Xác nhận', style: TextStyle(color: Colors.blue[700])),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        String newStatus = task.status == 'Done' ? 'To do' : 'Done';
        DateTime? newCompletedAt = newStatus == 'Done' ? DateTime.now() : null;

        await _firestoreService.updateTask(
          task.copyWith(
            status: newStatus,
            updatedAt: DateTime.now(),
            completedAt: newCompletedAt,
          ),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                newStatus == 'Done' ? 'Đã đánh dấu hoàn thành!' : 'Đã hủy trạng thái hoàn thành!'),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi cập nhật trạng thái: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildTaskCard(Task task, {bool isAssignedTask = false}) {
    Map<String, dynamic>? categoryStyle;
    if (task.category != null) {
      categoryStyle = [
        {'name': 'Công việc hàng ngày', 'color': Colors.blue[100], 'textColor': Colors.blue[800]},
        {'name': 'Công việc quan trọng', 'color': Colors.red[100], 'textColor': Colors.red[800]},
        {'name': 'Công việc nhóm', 'color': Colors.green[100], 'textColor': Colors.green[800]},
        {'name': 'Công việc cá nhân', 'color': Colors.purple[100], 'textColor': Colors.purple[800]},
        {'name': 'Công việc dài hạn', 'color': Colors.orange[100], 'textColor': Colors.orange[800]},
        {'name': 'Công việc khẩn cấp', 'color': Color(0xFFB2EBF2), 'textColor': Color(0xFF0097A7)},
      ].firstWhere(
            (tag) => tag['name'] == task.category,
        orElse: () => {'color': Colors.grey[200], 'textColor': Colors.black87},
      );
    }

    String dueDateDisplay = task.dueDate != null
        ? DateFormat.yMd().format(task.dueDate!)
        : 'Chưa thiết lập';
    String createdAtDisplay = DateFormat.yMd().format(task.createdAt) + ' lúc ' + DateFormat.Hm().format(task.createdAt);
    String groupName = 'Cá nhân';
    if (task.groupId != null) {
      final group = _groups.firstWhere(
            (g) => g.id == task.groupId,
        orElse: () => Group(id: '', name: 'Không xác định', code: '', adminId: '', members: [], createdAt: DateTime.now()),
      );
      groupName = group.name;
    }

    return FutureBuilder<bool>(
      future: _isAdminOfGroup(task.groupId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(child: CircularProgressIndicator(color: Colors.blue)),
          );
        }
        final isAdmin = snapshot.data ?? false;
        final canEditOrDelete = task.createdBy == _currentUserId || (task.groupId == null && task.assignedTo == _currentUserId);
        print('Task ${task.id} canEditOrDelete: $canEditOrDelete, isAdmin: $isAdmin, isPersonal: ${task.groupId == null}');
        return GestureDetector(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TaskDetailScreen(task: task, onUpdate: _loadTasks),
              ),
            );
          },
          child: Card(
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                task.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: task.priority == 1
                                    ? Colors.green[100]
                                    : task.priority == 2
                                    ? Colors.teal[100]
                                    : Colors.red[100],
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                task.priority == 1 ? 'Thấp' : task.priority == 2 ? 'Trung bình' : 'Cao',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: task.priority == 1
                                      ? Colors.green[800]
                                      : task.priority == 2
                                      ? Colors.teal[800]
                                      : Colors.red[800],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Mô tả: ',
                                    style: TextStyle(fontSize: 14, color: Colors.blue[600]),
                                  ),
                                  Expanded(
                                    child: Text(
                                      task.description,
                                      style: const TextStyle(fontSize: 14, color: Colors.black),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    'Trạng thái: ',
                                    style: TextStyle(fontSize: 14, color: Colors.blue[600]),
                                  ),
                                  Text(
                                    _statusDisplay[task.status] ?? task.status,
                                    style: TextStyle(fontSize: 14, color: Colors.black),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Hạn hoàn thành: $dueDateDisplay',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tạo lúc: $createdAtDisplay',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    'Nhóm: ',
                                    style: TextStyle(fontSize: 14, color: Colors.blue[600]),
                                  ),
                                  Text(
                                    groupName,
                                    style: const TextStyle(fontSize: 14, color: Colors.black),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    isAssignedTask ? 'Giao cho: ' : 'Người giao: ',
                                    style: TextStyle(fontSize: 14, color: Colors.blue[600]),
                                  ),
                                  Text(
                                    isAssignedTask ? (task.assignedTo ?? 'Không có') : (task.createdBy ?? 'Không có'),
                                    style: const TextStyle(fontSize: 14, color: Colors.black),
                                  ),
                                ],
                              ),
                              if (categoryStyle != null) ...[
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      'Danh mục: ',
                                      style: TextStyle(fontSize: 14, color: Colors.blue[600]),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: categoryStyle['color'],
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        task.category!,
                                        style: TextStyle(fontSize: 12, color: categoryStyle['textColor']),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      IconButton(
                        icon: Icon(
                          task.status == 'Done' ? Icons.check_circle : Icons.check_circle_outline,
                          color: task.status == 'Cancelled' ? Colors.grey : task.status == 'Done' ? Colors.green : Colors.grey,
                          size: 20,
                        ),
                        onPressed: task.status == 'Cancelled' || _isLoading ? null : () => _handleToggleComplete(task),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      if (canEditOrDelete) ...[
                        IconButton(
                          icon: Icon(
                            Icons.edit,
                            color: task.status == 'Cancelled' ? Colors.grey : Colors.blue[700],
                            size: 20,
                          ),
                          onPressed: task.status == 'Cancelled' || _isLoading
                              ? null
                              : () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TaskFormScreen(task: task, onSave: _loadTasks),
                              ),
                            );
                            if (result == true) {
                              _loadTasks();
                            }
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                          onPressed: _isLoading ? null : () async {
                            bool? confirm = await showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                title: Text('Xác nhận xóa', style: TextStyle(color: Colors.blue[700])),
                                content: Text('Bạn có chắc chắn muốn xóa công việc này không?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Xóa', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true && mounted) {
                              setState(() => _isLoading = true);
                              try {
                                await _firestoreService.deleteTask(task.id);
                                _loadTasks();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Đã xóa công việc thành công!')),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Lỗi khi xóa công việc: $e')),
                                );
                              } finally {
                                setState(() => _isLoading = false);
                              }
                            }
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[50]!, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Công việc của bạn',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.group, color: Colors.blue[700]),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const GroupManagementScreen()),
                          ),
                          tooltip: 'Quản lý nhóm',
                        ),
                        IconButton(
                          icon: Icon(Icons.logout, color: Colors.blue[700]),
                          onPressed: _handleSignOut,
                          tooltip: 'Đăng xuất',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm công việc...',
                      hintStyle: TextStyle(color: Colors.grey[600]),
                      prefixIcon: Icon(Icons.search, color: Colors.blue[700]),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    ),
                    onChanged: (value) => _loadTasks(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        child: DropdownButtonFormField<String>(
                          hint: Text('Lọc trạng thái', style: TextStyle(color: Colors.grey[600])),
                          value: _selectedStatus,
                          items: [
                            {'value': null, 'label': 'Tất cả'},
                            {'value': 'Incomplete', 'label': 'Chưa hoàn thành'},
                            {'value': 'Done', 'label': 'Đã hoàn thành'},
                            {'value': 'Cancelled', 'label': 'Đã hủy'},
                          ]
                              .map((item) => DropdownMenuItem<String>(
                            value: item['value'] as String?,
                            child: Text(
                              item['label'] as String,
                              style: TextStyle(color: Colors.blue[700]),
                            ),
                          ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedStatus = value;
                              _loadTasks();
                            });
                          },
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            fillColor: Colors.white,
                            filled: true,
                          ),
                          isExpanded: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        child: DropdownButtonFormField<String>(
                          hint: Text('Lọc nhóm', style: TextStyle(color: Colors.grey[600])),
                          value: _selectedGroup,
                          items: _groups.isEmpty
                              ? [const DropdownMenuItem(value: null, child: Text('Không có nhóm'), enabled: false)]
                              : [
                            DropdownMenuItem(
                              value: null,
                              child: Text('Tất cả', style: TextStyle(color: Colors.blue[700])),
                            ),
                            ..._groups
                                .map((group) => DropdownMenuItem<String>(
                              value: group.id,
                              child: Text(group.name, style: TextStyle(color: Colors.blue[700])),
                            ))
                                .toList(),
                          ],
                          onChanged: _groups.isEmpty
                              ? null
                              : (value) {
                            setState(() {
                              _selectedGroup = value;
                              _loadTasks();
                            });
                          },
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            fillColor: Colors.white,
                            filled: true,
                          ),
                          isExpanded: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue[700]!, Colors.blue[500]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: ElevatedButton(
                        onPressed: _handleReload,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: const Text(
                          'Tải lại',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _isLoading
                    ? Center(child: CircularProgressIndicator(color: Colors.blue[700]))
                    : (_myTasks.isEmpty && _assignedTasks.isEmpty)
                    ? const Center(
                  child: Text(
                    'Không có công việc nào!',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                )
                    : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: Text(
                          'Công việc của bạn (${_myTasks.length})',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ),
                      _myTasks.isEmpty
                          ? const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'Bạn chưa có công việc nào!',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                          : ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        itemCount: _myTasks.length,
                        itemBuilder: (context, index) {
                          return _buildTaskCard(_myTasks[index]);
                        },
                      ),
                      if (_assignedTasks.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          child: Text(
                            'Công việc bạn giao (${_assignedTasks.length})',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                        ),
                        _assignedTasks.isEmpty
                            ? const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            'Bạn chưa giao công việc nào!',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        )
                            : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          itemCount: _assignedTasks.length,
                          itemBuilder: (context, index) {
                            return _buildTaskCard(_assignedTasks[index], isAssignedTask: true);
                          },
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue[700],
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => TaskFormScreen(onSave: _loadTasks)),
          );
          if (result == true) {
            _loadTasks();
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}