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

  // Danh sách các tag danh mục với màu sắc riêng
  final List<Map<String, dynamic>> _categoryTags = [
    {'name': 'Công việc hàng ngày', 'color': Colors.blue[100], 'textColor': Colors.blue[800]},
    {'name': 'Công việc quan trọng', 'color': Colors.red[100], 'textColor': Colors.red[800]},
    {'name': 'Công việc nhóm', 'color': Colors.green[100], 'textColor': Colors.green[800]},
    {'name': 'Công việc cá nhân', 'color': Colors.purple[100], 'textColor': Colors.purple[800]},
    {'name': 'Công việc dài hạn', 'color': Colors.orange[100], 'textColor': Colors.orange[800]},
    {'name': 'Công việc khẩn cấp', 'color': Color(0xFFB2EBF2), 'textColor': Color(0xFF0097A7)},
  ];

  // Ánh xạ trạng thái tiếng Anh sang tiếng Việt để hiển thị
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
  }

  Future<void> _loadCurrentUserInfo() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final role = await _firestoreService.getUserRoleById(user.uid);
        setState(() {
          _currentUserRole = role ?? 'user';
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải thông tin người dùng: $e')),
      );
    }
  }

  Future<void> _loadGroupName() async {
    try {
      final group = await _firestoreService.getGroup(widget.task.groupId!);
      setState(() {
        _groupName = group?.name;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải thông tin nhóm: $e')),
      );
    }
  }

  Future<void> _updateTask(Task task) async {
    try {
      await _firestoreService.updateTask(task);
    } catch (e) {
      throw Exception('Lỗi khi cập nhật công việc: $e');
    }
  }

  Future<void> _handleToggleComplete() async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: Text(
            widget.task.status == 'Done' ? 'Xác nhận hủy hoàn thành' : 'Xác nhận hoàn thành',
            style: TextStyle(color: Colors.blue[700])),
        content: Text(widget.task.status == 'Done'
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(newStatus == 'Done'
                  ? 'Đã đánh dấu hoàn thành'
                  : 'Đã hủy trạng thái hoàn thành')),
        );
        Navigator.pop(context);
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

  Future<void> _updateTaskStatus(String newStatus) async {
    if (newStatus == widget.task.status) return;

    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: Text('Xác nhận cập nhật trạng thái',
            style: TextStyle(color: Colors.blue[700])),
        content: Text(
            'Bạn có muốn cập nhật trạng thái thành "${_statusDisplay[newStatus]}" không?'),
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
        DateTime? newCompletedAt = newStatus == 'Done' ? DateTime.now() : null;

        await _updateTask(
          widget.task.copyWith(
            status: newStatus,
            updatedAt: DateTime.now(),
            completedAt: newCompletedAt,
          ),
        );
        widget.onUpdate();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã cập nhật trạng thái thành "${_statusDisplay[newStatus]}"')),
        );
        Navigator.pop(context);
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

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Chi tiết công việc',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                      Row(
                        children: [
                          PopupMenuButton<String>(
                            icon: Icon(
                              Icons.swap_horiz,
                              color: widget.task.status == 'Cancelled' ? Colors.grey : Colors.blue[700],
                            ),
                            enabled: widget.task.status != 'Cancelled',
                            onSelected: (String newStatus) {
                              _updateTaskStatus(newStatus);
                            },
                            itemBuilder: (BuildContext context) => [
                              PopupMenuItem<String>(
                                value: 'To do',
                                child: Text('Cần làm'),
                              ),
                              PopupMenuItem<String>(
                                value: 'In progress',
                                child: Text('Đang làm'),
                              ),
                              PopupMenuItem<String>(
                                value: 'Done',
                                child: Text('Đã hoàn thành'),
                              ),
                              PopupMenuItem<String>(
                                value: 'Cancelled',
                                child: Text('Đã hủy'),
                              ),
                            ],
                            tooltip: 'Cập nhật trạng thái',
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.edit,
                              color: widget.task.status == 'Cancelled' ? Colors.grey : Colors.blue[700],
                            ),
                            onPressed: widget.task.status == 'Cancelled'
                                ? null
                                : () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      TaskFormScreen(task: widget.task, onSave: widget.onUpdate),
                                ),
                              );
                              if (result == true) {
                                widget.onUpdate();
                                Navigator.pop(context);
                              }
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.arrow_back, color: Colors.blue[700]),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.task.title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                        SizedBox(height: 20),
                        Divider(color: Colors.grey[300], thickness: 1),
                        SizedBox(height: 20),
                        Text(
                          'Mô tả',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          widget.task.description,
                          style: TextStyle(fontSize: 16, color: Colors.black87),
                        ),
                        SizedBox(height: 20),
                        Divider(color: Colors.grey[300], thickness: 1),
                        SizedBox(height: 20),
                        Text(
                          'Thông tin chi tiết',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                        SizedBox(height: 8),
                        _buildDetailRow('Trạng thái', _statusDisplay[widget.task.status] ?? widget.task.status),
                        _buildDetailRow('Độ ưu tiên',
                            widget.task.priority == 1 ? 'Thấp' : widget.task.priority == 2 ? 'Trung bình' : 'Cao'),
                        _buildDetailRow('Hạn hoàn thành', dueDateDisplay),
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
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                        _buildDetailRow('Giao cho', widget.task.assignedTo ?? 'Không có'),
                        if (_groupName != null) _buildDetailRow('Nhóm', _groupName!),
                        _buildDetailRow(
                            'Tạo ngày',
                            '${DateFormat.yMd().format(widget.task.createdAt)} lúc ${DateFormat.Hm().format(widget.task.createdAt)} phút'),
                        _buildDetailRow(
                            'Cập nhật ngày',
                            '${DateFormat.yMd().format(widget.task.updatedAt)} lúc ${DateFormat.Hm().format(widget.task.updatedAt)} phút'),
                        if (widget.task.completedAt != null)
                          _buildDetailRow(
                              'Hoàn thành',
                              '${DateFormat.yMd().format(widget.task.completedAt!)} lúc ${DateFormat.Hm().format(widget.task.completedAt!)} phút'),
                        if (widget.task.attachments != null && widget.task.attachments!.isNotEmpty) ...[
                          SizedBox(height: 20),
                          Divider(color: Colors.grey[300], thickness: 1),
                          SizedBox(height: 20),
                          Text(
                            'Tệp đính kèm',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                          SizedBox(height: 8),
                          Wrap(
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
                        ],
                        SizedBox(height: 24),
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
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: _isLoading
                                ? CircularProgressIndicator(color: Colors.white)
                                : Text(
                              widget.task.status == 'Done' ? 'Hủy hoàn thành' : 'Hoàn thành',
                              style: TextStyle(
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
              child: Center(
                child: CircularProgressIndicator(color: Colors.blue[700]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue[700]),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}