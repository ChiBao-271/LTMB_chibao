import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/firestore_service.dart';
import '../view/task_detail_screen.dart';
import '../view/task_form_screen.dart';

class TaskItem extends StatefulWidget {
  final Task task;
  final VoidCallback onUpdate;

  TaskItem({required this.task, required this.onUpdate});

  @override
  _TaskItemState createState() => _TaskItemState();
}

class _TaskItemState extends State<TaskItem> {
  bool _isLoading = false;
  final FirestoreService _firestoreService = FirestoreService();
  String? _currentUserId;

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
        print('Không có người dùng đăng nhập, thử lại sau 1 giây');
        await Future.delayed(Duration(seconds: 1));
        final retryUser = FirebaseAuth.instance.currentUser;
        if (retryUser == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Không tìm thấy thông tin người dùng!')),
            );
          }
          return;
        }
        setState(() => _currentUserId = retryUser.uid);
      } else {
        setState(() => _currentUserId = user.uid);
      }
      print('Current user ID: $_currentUserId, Task createdBy: ${widget.task.createdBy}, isPersonal: ${widget.task.groupId == null}');
    } catch (e) {
      print('Lỗi khi tải thông tin người dùng: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi tải thông tin người dùng: $e')),
        );
      }
    }
  }

  Future<void> _deleteTask(String id) async {
    try {
      await _firestoreService.deleteTask(id);
    } catch (e) {
      throw Exception('Lỗi khi xóa công việc: $e');
    }
  }

  Future<void> _handleDelete() async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
        await _deleteTask(widget.task.id);
        widget.onUpdate();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa công việc thành công!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi khi xóa công việc: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Future<void> _handleEdit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskFormScreen(task: widget.task, onSave: widget.onUpdate),
      ),
    );
    if (result == true && mounted) {
      widget.onUpdate();
    }
  }

  Future<void> _handleToggleComplete() async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: Text(
          widget.task.status == 'Done' ? 'Xác nhận hủy hoàn thành' : 'Xác nhận hoàn thành',
          style: TextStyle(color: Colors.blue[700]),
        ),
        content: Text(
            widget.task.status == 'Done'
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

    if (confirm == true && mounted) {
      setState(() => _isLoading = true);
      try {
        String newStatus = widget.task.status == 'Done' ? 'To do' : 'Done';
        DateTime? newCompletedAt = newStatus == 'Done' ? DateTime.now() : null;

        await _firestoreService.updateTask(
          widget.task.copyWith(
            status: newStatus,
            updatedAt: DateTime.now(),
            completedAt: newCompletedAt,
          ),
        );

        widget.onUpdate();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  newStatus == 'Done' ? 'Đã đánh dấu hoàn thành!' : 'Đã hủy trạng thái hoàn thành!'),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi khi cập nhật trạng thái: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic>? categoryStyle;
    if (widget.task.category != null) {
      categoryStyle = _categoryTags.firstWhere(
            (tag) => tag['name'] == widget.task.category,
        orElse: () => {'color': Colors.grey[200], 'textColor': Colors.black87},
      );
    }

    final canEditOrDelete = _currentUserId != null &&
        (widget.task.createdBy == _currentUserId || (widget.task.groupId == null && widget.task.assignedTo == _currentUserId));
    print('Task ${widget.task.id} canEditOrDelete: $canEditOrDelete, isPersonal: ${widget.task.groupId == null}, createdBy: ${widget.task.createdBy}, assignedTo: ${widget.task.assignedTo}');

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TaskDetailScreen(task: widget.task, onUpdate: widget.onUpdate),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    widget.task.status == 'Cancelled' ? Icons.cancel : Icons.circle_outlined,
                    color: widget.task.status == 'Cancelled' ? Colors.red : Colors.grey[400],
                    size: 24,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.task.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'Ưu tiên: ${widget.task.priority == 1 ? 'Thấp' : widget.task.priority == 2 ? 'Trung bình' : 'Cao'}',
                              style: const TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'Hạn: ${widget.task.dueDate?.toString().substring(0, 10) ?? 'Không có'}',
                              style: const TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ],
                        ),
                        if (widget.task.category != null) ...[
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: categoryStyle!['color'],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              widget.task.category!,
                              style: TextStyle(
                                fontSize: 12,
                                color: categoryStyle['textColor'],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      IconButton(
                        icon: Icon(
                          widget.task.status == 'Done' ? Icons.check_circle : Icons.check_circle_outline,
                          color: widget.task.status == 'Cancelled' ? Colors.grey : widget.task.status == 'Done' ? Colors.green : Colors.grey,
                          size: 20,
                        ),
                        onPressed: widget.task.status == 'Cancelled' || _isLoading ? null : _handleToggleComplete,
                      ),
                      if (canEditOrDelete) ...[
                        IconButton(
                          icon: Icon(
                            Icons.edit,
                            color: widget.task.status == 'Cancelled' ? Colors.grey : Colors.blue[700],
                          ),
                          onPressed: widget.task.status == 'Cancelled' || _isLoading ? null : _handleEdit,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: _isLoading ? null : _handleDelete,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(child: CircularProgressIndicator(color: Colors.blue[700])),
              ),
            ),
        ],
      ),
    );
  }
}