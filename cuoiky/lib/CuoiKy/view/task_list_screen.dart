import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import './task_form_screen.dart';
import './login_screen.dart';
import './task_detail_screen.dart';
import './group_management_screen.dart';

enum ViewMode { list, kanban }

class TaskListScreen extends StatefulWidget {
  @override
  _TaskListScreenState createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final _searchController = TextEditingController();
  String? _selectedStatus;
  String? _selectedCategory;
  List<Task> _tasks = [];
  Map<String, String?> _usernameCache = {};
  bool _isLoading = false;
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  String? _currentUserRole;
  String? _currentUserId;
  ViewMode _viewMode = ViewMode.list;

  final List<Map<String, dynamic>> _categoryTags = [
    {'name': 'Công việc hàng ngày', 'color': Colors.blue[100], 'textColor': Colors.blue[800]},
    {'name': 'Công việc quan trọng', 'color': Colors.red[100], 'textColor': Colors.red[800]},
    {'name': 'Công việc nhóm', 'color': Colors.green[100], 'textColor': Colors.green[800]},
    {'name': 'Công việc cá nhân', 'color': Colors.purple[100], 'textColor': Colors.purple[800]},
    {'name': 'Công việc dài hạn', 'color': Colors.orange[100], 'textColor': Colors.orange[800]},
    {'name': 'Công việc khẩn cấp', 'color': Color(0xFFB2EBF2), 'textColor': Color(0xFF0097A7)},
  ];

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không tìm thấy thông tin người dùng')),
        );
        return;
      }
      setState(() {
        _currentUserId = user.uid;
      });
      final role = await _firestoreService.getUserRoleById(user.uid);
      setState(() {
        _currentUserRole = role ?? 'user';
      });
      await _loadTasks();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải thông tin người dùng: $e')),
      );
    }
  }

  Future<void> _loadTasks() async {
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể tải công việc: ID người dùng không hợp lệ')),
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      final stream = _firestoreService.getTasks(
        userId: _currentUserRole == 'admin' ? null : _currentUserId,
        status: _selectedStatus,
        category: _selectedCategory,
      );
      stream.listen((tasks) async {
        List<Task> loadedTasks = [];
        for (var task in tasks) {
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
          loadedTasks.add(task.copyWith(assignedTo: username));
        }

        setState(() {
          _tasks = loadedTasks;
          _isLoading = false;
        });
        print('Loaded tasks: ${_tasks.length}');
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể tải danh sách công việc: $e')),
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
            child: Text('Hủy', style: TextStyle(color: Colors.grey)),
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
          SnackBar(content: Text('Đã đăng xuất thành công')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi đăng xuất: $e')),
        );
      }
    }
  }

  Future<void> _handleReload() async {
    setState(() {
      _searchController.clear();
      _selectedStatus = null;
      _selectedCategory = null;
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
            style: TextStyle(color: Colors.blue[700])),
        content: Text(task.status == 'Done'
            ? 'Bạn có muốn hủy trạng thái hoàn thành công việc này không?'
            : 'Bạn có muốn đánh dấu công việc này là hoàn thành không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Xác nhận', style: TextStyle(color: Colors.blue[700])),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });
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
              content: Text(newStatus == 'Done'
                  ? 'Đã đánh dấu hoàn thành'
                  : 'Đã hủy trạng thái hoàn thành')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi cập nhật trạng thái: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildTaskCard(Task task) {
    Map<String, dynamic>? categoryStyle;
    if (task.category != null) {
      categoryStyle = _categoryTags.firstWhere(
            (tag) => tag['name'] == task.category,
        orElse: () => {'color': Colors.grey[200], 'textColor': Colors.black87},
      );
    }

    String dueDateDisplay;
    if (task.status == 'Done' && task.dueDate != null && task.completedAt != null) {
      bool hasTime =
          task.dueDate!.hour != 0 || task.dueDate!.minute != 0 || task.dueDate!.second != 0;
      if (hasTime) {
        dueDateDisplay =
        '${DateFormat.yMd().format(task.dueDate!)} lúc ${DateFormat.Hm().format(task.dueDate!)} phút, hoàn thành lúc ${DateFormat.Hm().format(task.completedAt!)} phút';
      } else {
        dueDateDisplay =
        '${DateFormat.yMd().format(task.dueDate!)} lúc ${DateFormat.Hm().format(task.completedAt!)} phút';
      }
    } else if (task.dueDate != null) {
      dueDateDisplay = DateFormat.yMd().format(task.dueDate!);
    } else {
      dueDateDisplay = 'Chưa thiết lập';
    }

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
        margin: EdgeInsets.symmetric(vertical: 8),
        child: SizedBox(
          height: _viewMode == ViewMode.kanban ? 222 : null,
          child: _viewMode == ViewMode.kanban
              ? Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Stack(
                    children: [
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: task.priority == 1
                                ? Colors.green[100]
                                : task.priority == 2
                                ? Colors.teal[100]
                                : Colors.red[100],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            task.priority == 1
                                ? 'Thấp'
                                : task.priority == 2
                                ? 'Trung bình'
                                : 'Cao',
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
                      ),
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Giao cho: ',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    task.assignedTo ?? 'Không có',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 6),
                            Text(
                              task.title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 6),
                            Text(
                              'Mô tả: ${task.description}',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Trạng thái: ${_statusDisplay[task.status] ?? task.status}',
                              style: TextStyle(
                                fontSize: 13,
                                color: task.status == 'To do'
                                    ? Colors.blue[600]
                                    : task.status == 'In progress'
                                    ? Colors.teal[600]
                                    : task.status == 'Done'
                                    ? Colors.green[600]
                                    : Colors.red[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Hạn hoàn thành: $dueDateDisplay',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: 3),
                            if (task.category != null)
                              Row(
                                children: [
                                  Text(
                                    'Danh mục: ',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  Container(
                                    padding:
                                    EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: categoryStyle!['color'],
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      task.category!,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: categoryStyle['textColor'],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            if (task.completedAt != null) SizedBox(height: 3),
                            if (task.completedAt != null)
                              Text(
                                'Hủy ngày: ${DateFormat.yMd().format(task.completedAt!)} lúc ${DateFormat.Hm().format(task.completedAt!)} phút',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(right: 16, bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: Icon(
                        task.status == 'Done'
                            ? Icons.check_circle
                            : Icons.check_circle_outline,
                        color: task.status == 'Cancelled'
                            ? Colors.grey
                            : task.status == 'Done'
                            ? Colors.green
                            : Colors.grey,
                        size: 16,
                      ),
                      onPressed: task.status == 'Cancelled' || _isLoading
                          ? null
                          : () => _handleToggleComplete(task),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.edit,
                        color:
                        task.status == 'Cancelled' ? Colors.grey : Colors.blue[700],
                        size: 16,
                      ),
                      onPressed: task.status == 'Cancelled' || _isLoading
                          ? null
                          : () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                TaskFormScreen(task: task, onSave: _loadTasks),
                          ),
                        );
                        if (result == true) {
                          _loadTasks();
                        }
                      },
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete,
                        color: Colors.red,
                        size: 16,
                      ),
                      onPressed: _isLoading
                          ? null
                          : () async {
                        bool? confirm = await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20)),
                            title: Text('Xác nhận xóa',
                                style: TextStyle(color: Colors.blue[700])),
                            content:
                            Text('Bạn có chắc chắn muốn xóa công việc này?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child:
                                Text('Hủy', style: TextStyle(color: Colors.grey)),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child:
                                Text('Xóa', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          setState(() {
                            _isLoading = true;
                          });
                          try {
                            await _firestoreService.deleteTask(task.id);
                            _loadTasks();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text('Đã xóa công việc thành công')),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Lỗi khi xóa công việc: $e')),
                            );
                          } finally {
                            setState(() {
                              _isLoading = false;
                            });
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          )
              : Stack(
            children: [
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: task.priority == 1
                        ? Colors.green[100]
                        : task.priority == 2
                        ? Colors.teal[100]
                        : Colors.red[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    task.priority == 1
                        ? 'Thấp'
                        : task.priority == 2
                        ? 'Trung bình'
                        : 'Cao',
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
              ),
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Giao cho: ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            task.assignedTo ?? 'Không có',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      task.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8),
                    Padding(
                      padding: EdgeInsets.only(left: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mô tả: ${task.description}',
                            style: TextStyle(fontSize: 14, color: Colors.black87),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Trạng thái: ${_statusDisplay[task.status] ?? task.status}',
                            style: TextStyle(
                              fontSize: 14,
                              color: task.status == 'To do'
                                  ? Colors.blue[600]
                                  : task.status == 'In progress'
                                  ? Colors.teal[600]
                                  : task.status == 'Done'
                                  ? Colors.green[600]
                                  : Colors.red[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Hạn hoàn thành: $dueDateDisplay',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          if (task.category != null)
                            Row(
                              children: [
                                Text(
                                  'Danh mục: ',
                                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                ),
                                Container(
                                  padding:
                                  EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: categoryStyle!['color'],
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    task.category!,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: categoryStyle['textColor'],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          SizedBox(height: 4),
                          if (task.attachments != null && task.attachments!.isNotEmpty)
                            Text(
                              'Tệp: ${task.attachments!.length > 1 ? '${task.attachments!.first.split('/').last}...' : task.attachments!.first.split('/').last}',
                              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          SizedBox(height: 4),
                          Text(
                            'Tạo ngày: ${DateFormat.yMd().format(task.createdAt)} lúc ${DateFormat.Hm().format(task.createdAt)} phút',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Cập nhật ngày: ${DateFormat.yMd().format(task.updatedAt)} lúc ${DateFormat.Hm().format(task.updatedAt)} phút',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (task.completedAt != null)
                            Text(
                              'Hủy ngày: ${DateFormat.yMd().format(task.completedAt!)} lúc ${DateFormat.Hm().format(task.completedAt!)} phút',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: Icon(
                            task.status == 'Done'
                                ? Icons.check_circle
                                : Icons.check_circle_outline,
                            color: task.status == 'Cancelled'
                                ? Colors.grey
                                : task.status == 'Done'
                                ? Colors.green
                                : Colors.grey,
                            size: 20,
                          ),
                          onPressed: task.status == 'Cancelled' || _isLoading
                              ? null
                              : () => _handleToggleComplete(task),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.edit,
                            color: task.status == 'Cancelled'
                                ? Colors.grey
                                : Colors.blue[700],
                            size: 20,
                          ),
                          onPressed: task.status == 'Cancelled' || _isLoading
                              ? null
                              : () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    TaskFormScreen(task: task, onSave: _loadTasks),
                              ),
                            );
                            if (result == true) {
                              _loadTasks();
                            }
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete,
                            color: Colors.red,
                            size: 20,
                          ),
                          onPressed: _isLoading
                              ? null
                              : () async {
                            bool? confirm = await showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)),
                                title: Text('Xác nhận xóa',
                                    style: TextStyle(color: Colors.blue[700])),
                                content: Text(
                                    'Bạn có chắc chắn muốn xóa công việc này?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: Text('Hủy',
                                        style: TextStyle(color: Colors.grey)),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: Text('Xóa',
                                        style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              setState(() {
                                _isLoading = true;
                              });
                              try {
                                await _firestoreService.deleteTask(task.id);
                                _loadTasks();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content:
                                      Text('Đã xóa công việc thành công')),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text('Lỗi khi xóa công việc: $e')),
                                );
                              } finally {
                                setState(() {
                                  _isLoading = false;
                                });
                              }
                            }
                          },
                        ),
                      ],
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

  Widget _buildKanbanBoard() {
    final statuses = ['To do', 'In progress', 'Done', 'Cancelled'];
    Map<String, List<Task>> tasksByStatus = {
      'To do': [],
      'In progress': [],
      'Done': [],
      'Cancelled': [],
    };

    for (var task in _tasks) {
      if (_selectedCategory == null || task.category == _selectedCategory) {
        tasksByStatus[task.status]!.add(task);
      }
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: statuses.map((status) {
          return Container(
            width: 300,
            margin: EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: status == 'To do'
                        ? Colors.blue[50]
                        : status == 'In progress'
                        ? Colors.teal[50]
                        : status == 'Done'
                        ? Colors.green[50]
                        : Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _statusDisplay[status] ?? status,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: status == 'To do'
                              ? Colors.blue[700]
                              : status == 'In progress'
                              ? Colors.teal[700]
                              : status == 'Done'
                              ? Colors.green[700]
                              : Colors.red[700],
                        ),
                      ),
                      Text(
                        '${tasksByStatus[status]!.length}',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8),
                Expanded(
                  child: tasksByStatus[status]!.isEmpty
                      ? Center(
                    child: Text(
                      'Không có công việc',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  )
                      : ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    itemCount: tasksByStatus[status]!.length,
                    itemBuilder: (context, index) {
                      return _buildTaskCard(tasksByStatus[status]![index]);
                    },
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
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
              Container(
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
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
                          icon: Icon(
                            _viewMode == ViewMode.list ? Icons.view_column : Icons.list,
                            color: Colors.blue[700],
                          ),
                          onPressed: () {
                            setState(() {
                              _viewMode =
                              _viewMode == ViewMode.list ? ViewMode.kanban : ViewMode.list;
                            });
                          },
                          tooltip: _viewMode == ViewMode.list ? 'Chuyển sang Kanban' : 'Chuyển sang List',
                        ),
                        IconButton(
                          icon: Icon(Icons.group, color: Colors.blue[700]),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => GroupManagementScreen(),
                              ),
                            );
                          },
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
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm công việc...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: Icon(Icons.search, color: Colors.blue[700]),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                    ),
                    onChanged: (value) => _loadTasks(),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        child: DropdownButtonFormField<String>(
                          hint: Text('Trạng thái', style: TextStyle(color: Colors.grey[600])),
                          value: _selectedStatus,
                          items: [
                            {'value': 'To do', 'label': 'Cần làm'},
                            {'value': 'In progress', 'label': 'Đang làm'},
                            {'value': 'Done', 'label': 'Đã hoàn thành'},
                            {'value': 'Cancelled', 'label': 'Đã hủy'},
                          ]
                              .map((item) => DropdownMenuItem<String>(
                            value: item['value'] as String,
                            child: Text(item['label'] as String),
                          ))
                              .toList(),
                          onChanged: _viewMode == ViewMode.kanban
                              ? null
                              : (value) {
                            setState(() {
                              _selectedStatus = value;
                              _loadTasks();
                            });
                          },
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          ),
                          isExpanded: true,
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        child: DropdownButtonFormField<String>(
                          hint: Text('Danh mục', style: TextStyle(color: Colors.grey[600])),
                          value: _selectedCategory,
                          items: _categoryTags
                              .map((tag) => DropdownMenuItem<String>(
                            value: tag['name'] as String,
                            child: Text(tag['name'] as String),
                          ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCategory = value;
                              _loadTasks();
                            });
                          },
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          ),
                          isExpanded: true,
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
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
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          'Tải lại',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Expanded(
                child: _isLoading
                    ? Center(child: CircularProgressIndicator(color: Colors.blue[700]))
                    : _tasks.isEmpty
                    ? Center(
                  child: Text(
                    'Không có công việc nào',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                )
                    : _viewMode == ViewMode.list
                    ? ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: _tasks.length,
                  itemBuilder: (context, index) {
                    final task = _tasks[index];
                    return _buildTaskCard(task);
                  },
                )
                    : _buildKanbanBoard(),
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
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}