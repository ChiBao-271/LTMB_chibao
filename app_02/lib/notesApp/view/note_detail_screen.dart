import 'package:flutter/material.dart';
import '../models/note.dart';
import 'note_form_screen.dart';
import '../db/note_database_helper.dart';

class NoteDetailScreen extends StatelessWidget {
  final Note note;

  const NoteDetailScreen({Key? key, required this.note}) : super(key: key);

  String _getPriorityText(int priority) {
    switch (priority) {
      case 1:
        return 'Thấp';
      case 2:
        return 'Trung Bình';
      case 3:
        return 'Cao';
      default:
        return 'Không Xác Định';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return dateTime.toString().split('.').first;
  }

  // Hàm ánh xạ nhãn (tag) thành màu
  Color _getTagColor(String tag) {
    switch (tag) {
      case 'Công Việc':
        return Colors.blue.shade100;
      case 'Học Tập':
        return Colors.green.shade100;
      case 'Cá Nhân':
        return Colors.purple.shade100;
      case 'Mua Sắm':
        return Colors.orange.shade100;
      case 'Gia Đình':
        return Colors.red.shade100;
      case 'Khác':
        return Colors.grey.shade200;
      default:
        return Colors.grey.shade200;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi Tiết Ghi Chú'),
        actions: [
          // Nút chỉnh sửa
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => NoteForm(note: note)),
            ),
          ),
          // Nút xóa
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Xác Nhận Xóa'),
                  content: const Text('Bạn có chắc muốn xóa ghi chú này?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Hủy'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Xóa'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await NoteDatabaseHelper.instance.deleteNote(note.id!);
                Navigator.pop(context); // Quay lại màn hình danh sách
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Tiêu đề
            Text(
              note.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            // 2. Mức độ ưu tiên
            Text('Ưu Tiên: ${_getPriorityText(note.priority)}'),
            const SizedBox(height: 8),
            // 3. Nhãn "Nội dung" và nội dung đã nhập
            const Text(
              'Nội dung',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(note.content),
            const SizedBox(height: 8),
            // 4. Ngày giờ tạo
            Text('Thời Gian Tạo: ${_formatDateTime(note.createdAt)}'),
            const SizedBox(height: 8),
            // 5. Ngày giờ cập nhật
            Text('Thời Gian Sửa: ${_formatDateTime(note.modifiedAt)}'),
            const SizedBox(height: 8),
            // 6. Tags (nhãn) nếu có
            if (note.tags != null && note.tags!.isNotEmpty) ...[
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: note.tags!
                    .where((tag) => tag.isNotEmpty) // Loại bỏ chuỗi rỗng
                    .map((tag) {
                  return Chip(
                    label: Text(
                      tag,
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: _getTagColor(tag), // Áp dụng màu cho tag
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
            ],
            // 7. Trạng thái hoàn thành
            Text(
              'Trạng thái: ${note.isCompleted ?? false ? 'Hoàn thành' : 'Chưa hoàn thành'}',
              style: TextStyle(
                color: note.isCompleted ?? false ? Colors.green : Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}