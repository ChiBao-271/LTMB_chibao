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
        content: Text('Bạn có chắc chắn muốn xóa công việc này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });
      try {
        await _deleteTask(widget.task.id);
        widget.onUpdate();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã xóa công việc thành công')),
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
  }

  Future<void> _handleEdit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskFormScreen(task: widget.task, onSave: widget.onUpdate),
      ),
    );
    if (result == true) {
      widget.onUpdate();
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

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
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
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    widget.task.status == 'Cancelled' ? Icons.cancel : Icons.circle_outlined,
                    color: widget.task.status == 'Cancelled' ? Colors.red : Colors.grey[400],
                    size: 24,
                  ),
                  SizedBox(width: 16),
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
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'Ưu tiên: ${widget.task.priority == 1 ? 'Thấp' : widget.task.priority == 2 ? 'Trung bình' : 'Cao'}',
                              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                            ),
                            SizedBox(width: 16),
                            Text(
                              'Hạn: ${widget.task.dueDate?.toString().substring(0, 10) ?? 'Không có'}',
                              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        if (widget.task.category != null) ...[
                          SizedBox(height: 4),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                          Icons.edit,
                          color: widget.task.status == 'Cancelled' ? Colors.grey : Colors.blue[700],
                        ),
                        onPressed: widget.task.status == 'Cancelled' || _isLoading ? null : _handleEdit,
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: _isLoading ? null : _handleDelete,
                      ),
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