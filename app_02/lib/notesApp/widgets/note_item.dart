import 'package:flutter/material.dart';
import '../models/note.dart';
import '../view/note_detail_screen.dart';
import '../db/note_database_helper.dart';
import '../view/note_form_screen.dart';

class NoteItem extends StatelessWidget {
  final Note note;
  final VoidCallback onRefresh;
  final bool isGridView;

  const NoteItem({
    Key? key,
    required this.note,
    required this.onRefresh,
    required this.isGridView,
  }) : super(key: key);

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

  Color _getPriorityColor() {
    switch (note.priority) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.blueAccent;
      case 3:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Hàm ánh xạ nhãn (tag) thành icon
  IconData _getTagIcon(String tag) {
    switch (tag) {
      case 'Công Việc':
        return Icons.work;
      case 'Học Tập':
        return Icons.school;
      case 'Cá Nhân':
        return Icons.person;
      case 'Mua Sắm':
        return Icons.shopping_cart;
      case 'Gia Đình':
        return Icons.family_restroom;
      case 'Khác':
        return Icons.tag;
      default:
        return Icons.tag; // Icon mặc định cho các nhãn không xác định
    }
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

  // Hàm cập nhật trạng thái hoàn thành
  Future<void> _toggleCompleted(BuildContext context) async {
    final updatedNote = note.copyWith(
      isCompleted: !(note.isCompleted ?? false),
      modifiedAt: DateTime.now(),
    );
    await NoteDatabaseHelper.instance.updateNote(updatedNote);
    onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: note.color != null
          ? Color(int.parse('0xFF${note.color!.substring(1)}'))
          : Colors.white,
      child: isGridView
          ? GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NoteDetailScreen(note: note),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tiêu đề và mức độ ưu tiên
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Tiêu đề
                  Expanded(
                    child: Text(
                      note.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Mức độ ưu tiên
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getPriorityColor().withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _getPriorityText(note.priority),
                      style: TextStyle(
                        color: _getPriorityColor(),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Nội dung
              Flexible(
                child: Text(
                  note.content.length > 50
                      ? '${note.content.substring(0, 50)}...'
                      : note.content,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 8),
              // Ngày tạo
              Text(
                _formatDateTime(note.createdAt),
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              // Nhãn (hiển thị dưới dạng icon nếu có, không hiển thị nếu nhãn rỗng)
              if (note.tags != null && note.tags!.isNotEmpty && note.tags!.first.isNotEmpty) ...[
                Icon(
                  _getTagIcon(note.tags!.first),
                  size: 20,
                  color: Colors.grey[600],
                ),
                const SizedBox(height: 8),
              ],
              const Spacer(),
              // Nút hoàn thành và nút xóa/sửa (góc dưới)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Nút hoàn thành (góc dưới bên trái)
                  IconButton(
                    icon: Icon(
                      note.isCompleted ?? false
                          ? Icons.check_circle
                          : Icons.check_circle_outline,
                      size: 18,
                      color: note.isCompleted ?? false
                          ? Colors.green
                          : Colors.grey,
                    ),
                    onPressed: () => _toggleCompleted(context),
                  ),
                  // Nút xóa/sửa (góc dưới bên phải)
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.edit,
                          size: 18,
                          color: Colors.blue,
                        ),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => NoteForm(note: note),
                          ),
                        ).then((_) => onRefresh()),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          size: 18,
                          color: Colors.red,
                        ),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Xác Nhận Xóa'),
                              content: const Text(
                                'Bạn có chắc muốn xóa ghi chú này?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(
                                    context,
                                    false,
                                  ),
                                  child: const Text('Hủy'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(
                                    context,
                                    true,
                                  ),
                                  child: const Text('Xóa'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await NoteDatabaseHelper.instance
                                .deleteNote(note.id!);
                            onRefresh();
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      )
          : Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 16,
        ),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            note.title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                note.content.length > 50
                    ? '${note.content.substring(0, 50)}...'
                    : note.content,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: _getPriorityColor().withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Mức độ ưu tiên ${_getPriorityText(note.priority)}',
                  style: TextStyle(
                    color: _getPriorityColor(),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Thời Gian Tạo: ${_formatDateTime(note.createdAt)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Thời Gian Sửa: ${_formatDateTime(note.modifiedAt)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 0,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Nút hoàn thành (góc trên bên phải, trên cùng)
              IconButton(
                icon: Icon(
                  note.isCompleted ?? false
                      ? Icons.check_circle
                      : Icons.check_circle_outline,
                  size: 24,
                  color: note.isCompleted ?? false
                      ? Colors.green
                      : Colors.grey,
                ),
                onPressed: () => _toggleCompleted(context),
              ),
              IconButton(
                icon: const Icon(
                  Icons.edit,
                  size: 24,
                  color: Colors.blue,
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NoteForm(note: note),
                  ),
                ).then((_) => onRefresh()),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(
                  Icons.delete,
                  size: 24,
                  color: Colors.red,
                ),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Xác Nhận Xóa'),
                      content: const Text(
                        'Bạn có chắc muốn xóa ghi chú này?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(
                            context,
                            false,
                          ),
                          child: const Text('Hủy'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(
                            context,
                            true,
                          ),
                          child: const Text('Xóa'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await NoteDatabaseHelper.instance.deleteNote(
                      note.id!,
                    );
                    onRefresh();
                  }
                },
              ),
            ],
          ),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NoteDetailScreen(note: note),
            ),
          ),
        ),
      ),
    );
  }
}