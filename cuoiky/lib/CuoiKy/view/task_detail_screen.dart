import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../services/firestore_service.dart';
import './task_form_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  final Task task;
  final VoidCallback onUpdate;

  TaskDetailScreen({required this.task, required this.onUpdate});

  @override
  _TaskDetailScreenState createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  bool _isLoading = false;
  final FirestoreService _firestoreService = FirestoreService();
  String? _currentUserRole;
  String? _groupName;
  bool _isAdminOfGroup = false;
  String? _currentUserId;
  String? _assignedToUsername;

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
    if (widget.task.groupId != null) {
      _loadGroupName();
    }
    if (widget.task.assignedTo != null) {
      _loadAssignedToUsername();
    }
  }

  Future<void> _loadCurrentUserInfo() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        setState(() => _currentUserId = user.uid);
        final role = await _firestoreService.getUserRoleById(user.uid);
        setState(() => _currentUserRole = role ?? 'user');
        if (widget.task.groupId != null) {
          final group = await _firestoreService.getGroup(widget.task.groupId!);
          if (group != null && group.adminId == user.uid) {
            setState(() => _isAdminOfGroup = true);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi tải thông tin người dùng: $e')),
        );
      }
    }
  }

  Future<void> _loadGroupName() async {
    try {
      final group = await _firestoreService.getGroup(widget.task.groupId!);
      if (mounted) {
        setState(() => _groupName = group?.name);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi tải thông tin nhóm: $e')),
        );
      }
    }
  }

  Future<void> _loadAssignedToUsername() async {
    try {
      final username = await _firestoreService.getUsernameById(widget.task.assignedTo!);
      if (mounted) {
        setState(() => _assignedToUsername = username ?? 'Không xác định');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi tải tên người được giao: $e')),
        );
      }
    }
  }

  Future<void> _updateTask(Task task) async {
    try {
      await _firestoreService.updateTask(task);
    } catch (e) {
      throw Exception('Lỗi khi cập nhật công việc: $e');
    }
  }

  Future<void> _deleteTask() async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: Text('Xác nhận xóa', style: TextStyle(color: Colors.blue[700])),
        content: Text('Bạn có chắc chắn muốn xóa công việc "${widget.task.title}" không?'),
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
        await _firestoreService.deleteTask(widget.task.id);
        widget.onUpdate();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa công việc thành công!')),
          );
          Navigator.pop(context);
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

  Future<void> _handleToggleComplete() async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: Text(
          widget.task.status == 'Done' ? 'Xác nhận hủy hoàn thành' : 'Xác nhận hoàn thành',
          style: TextStyle(color: Colors.blue[700]),
        ),
        content: Text(widget.task.status == 'Done'
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

        await _updateTask(
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
              content: Text(newStatus == 'Done' ? 'Đã đánh dấu hoàn thành!' : 'Đã hủy trạng thái hoàn thành!'),
            ),
          );
          Navigator.pop(context);
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

  Future<void> _handleEdit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskFormScreen(task: widget.task, onSave: widget.onUpdate),
      ),
    );
    if (result == true && mounted) {
      widget.onUpdate();
      Navigator.pop(context);
    }
  }

  Future<void> _updateTaskStatus(String newStatus) async {
    if (newStatus == widget.task.status) return;

    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: Text('Xác nhận cập nhật trạng thái', style: TextStyle(color: Colors.blue[700])),
        content: Text('Bạn có muốn cập nhật trạng thái thành "${_statusDisplay[newStatus]}" không?'),
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
        DateTime? newCompletedAt = newStatus == 'Done' ? DateTime.now() : null;

        await _updateTask(
          widget.task.copyWith(
            status: newStatus,
            updatedAt: DateTime.now(),
            completedAt: newCompletedAt,
          ),
        );
        widget.onUpdate();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đã cập nhật trạng thái thành "${_statusDisplay[newStatus]}"')),
          );
          Navigator.pop(context);
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

    String dueDateDisplay;
    if (widget.task.status == 'Done' && widget.task.dueDate != null && widget.task.completedAt != null) {
      bool hasTime = widget.task.dueDate!.hour != 0 ||
          widget.task.dueDate!.minute != 0 ||
          widget.task.dueDate!.second != 0;
      if (hasTime) {
        dueDateDisplay =
        '${DateFormat.yMd().format(widget.task.dueDate!)} lúc ${DateFormat.Hm().format(widget.task.dueDate!)} phút, hoàn thành lúc ${DateFormat.Hm().format(widget.task.completedAt!)} phút';
      } else {
        dueDateDisplay =
        '${DateFormat.yMd().format(widget.task.dueDate!)} lúc ${DateFormat.Hm().format(widget.task.completedAt!)} phút';
      }
    } else if (widget.task.dueDate != null) {
      dueDateDisplay = DateFormat.yMd().format(widget.task.dueDate!);
    } else {
      dueDateDisplay = 'Chưa thiết lập';
    }

    final canEditOrDelete = _currentUserId != null &&
        ((widget.task.createdBy == _currentUserId || _isAdminOfGroup) ||
            (widget.task.groupId == null && widget.task.assignedTo == _currentUserId)) &&
        (widget.task.status != 'Cancelled' || widget.task.createdBy == _currentUserId);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Chi tiết công việc',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                      Row(
                        children: [
                          if (canEditOrDelete)
                            IconButton(
                              icon: Icon(
                                Icons.check_circle,
                                color: widget.task.status == 'Cancelled' && widget.task.createdBy != _currentUserId
                                    ? Colors.grey
                                    : Colors.green,
                                size: 18,
                              ),
                              onPressed: widget.task.status == 'Cancelled' && widget.task.createdBy != _currentUserId
                                  ? null
                                  : _handleToggleComplete,
                              tooltip: widget.task.status == 'Done' ? 'Hủy hoàn thành' : 'Hoàn thành',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          if (canEditOrDelete)
                            PopupMenuButton<String>(
                              icon: Icon(
                                Icons.swap_horiz,
                                color: widget.task.status == 'Cancelled' && widget.task.createdBy != _currentUserId
                                    ? Colors.grey
                                    : Colors.blue[700],
                                size: 18,
                              ),
                              enabled: widget.task.status != 'Cancelled' || widget.task.createdBy == _currentUserId,
                              onSelected: (String newStatus) {
                                _updateTaskStatus(newStatus);
                              },
                              itemBuilder: (BuildContext context) => [
                                const PopupMenuItem<String>(
                                  value: 'To do',
                                  child: Text('Cần làm'),
                                ),
                                const PopupMenuItem<String>(
                                  value: 'In progress',
                                  child: Text('Đang làm'),
                                ),
                                const PopupMenuItem<String>(
                                  value: 'Done',
                                  child: Text('Đã hoàn thành'),
                                ),
                                const PopupMenuItem<String>(
                                  value: 'Cancelled',
                                  child: Text('Đã hủy'),
                                ),
                              ],
                              tooltip: 'Đổi trạng thái',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          if (canEditOrDelete)
                            IconButton(
                              icon: Icon(
                                Icons.edit,
                                color: widget.task.status == 'Cancelled' && widget.task.createdBy != _currentUserId
                                    ? Colors.grey
                                    : Colors.blue[700],
                                size: 18,
                              ),
                              onPressed: (widget.task.status == 'Cancelled' && widget.task.createdBy != _currentUserId) || _isLoading
                                  ? null
                                  : _handleEdit,
                              tooltip: 'Chỉnh sửa',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          if (canEditOrDelete)
                            IconButton(
                              icon: Icon(
                                Icons.delete,
                                color: widget.task.status == 'Cancelled' && widget.task.createdBy != _currentUserId
                                    ? Colors.grey
                                    : Colors.red,
                                size: 18,
                              ),
                              onPressed: (widget.task.status == 'Cancelled' && widget.task.createdBy != _currentUserId) || _isLoading
                                  ? null
                                  : _deleteTask,
                              tooltip: 'Xóa',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          IconButton(
                            icon: Icon(
                              Icons.arrow_back,
                              color: Colors.blue[700],
                              size: 18,
                            ),
                            onPressed: () => Navigator.pop(context),
                            tooltip: 'Quay lại',
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tiêu đề',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 16, top: 8),
                          child: Text(
                            widget.task.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Divider(color: Colors.grey[300], thickness: 1),
                        const SizedBox(height: 20),
                        Text(
                          'Mô tả',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 16, top: 8),
                          child: Text(
                            widget.task.description,
                            style: const TextStyle(fontSize: 16, color: Colors.black87),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Divider(color: Colors.grey[300], thickness: 1),
                        const SizedBox(height: 20),
                        Text(
                          'Thông tin chi tiết',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 16, top: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDetailRow('Trạng thái: ', _statusDisplay[widget.task.status] ?? widget.task.status),
                              _buildDetailRow('Độ ưu tiên: ',
                                  widget.task.priority == 1 ? 'Thấp' : widget.task.priority == 2 ? 'Trung bình' : 'Cao'),
                              _buildDetailRow('Hạn hoàn thành: ', dueDateDisplay),
                              if (widget.task.category != null)
                                Row(
                                  children: [
                                    Text(
                                      'Danh mục: ',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue[700],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: categoryStyle!['color'],
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        widget.task.category!,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: categoryStyle['textColor'],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              _buildDetailRow('Giao cho: ', _assignedToUsername ?? 'Không có'),
                              if (_groupName != null) _buildDetailRow('Nhóm: ', _groupName!),
                              _buildDetailRow('Tạo ngày: ',
                                  '${DateFormat.yMd().format(widget.task.createdAt)} lúc ${DateFormat.Hm().format(widget.task.createdAt)} phút'),
                              _buildDetailRow('Cập nhật ngày: ',
                                  '${DateFormat.yMd().format(widget.task.updatedAt)} lúc ${DateFormat.Hm().format(widget.task.updatedAt)} phút'),
                              if (widget.task.completedAt != null)
                                _buildDetailRow('Hoàn thành: ',
                                    '${DateFormat.yMd().format(widget.task.completedAt!)} lúc ${DateFormat.Hm().format(widget.task.completedAt!)} phút'),
                              if (widget.task.attachments != null && widget.task.attachments!.isNotEmpty) ...[
                                const SizedBox(height: 20),
                                Divider(color: Colors.grey[300], thickness: 1),
                                const SizedBox(height: 20),
                                Text(
                                  'Tệp đính kèm',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[700],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 16, top: 8),
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: widget.task.attachments!
                                        .map((file) => Chip(
                                      label: Text(file.split('/').last),
                                      backgroundColor: Colors.blue[50],
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ))
                                        .toList(),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: widget.task.status == 'Cancelled'
                                  ? [Colors.grey, Colors.grey]
                                  : [Colors.blue[700]!, Colors.blue[500]!],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ElevatedButton(
                            onPressed: widget.task.status == 'Cancelled' || _isLoading
                                ? null
                                : _handleToggleComplete,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
                                : Text(
                              widget.task.status == 'Done' ? 'Hủy hoàn thành' : 'Hoàn thành',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: Center(child: CircularProgressIndicator(color: Colors.blue[700])),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.blue[700],
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}