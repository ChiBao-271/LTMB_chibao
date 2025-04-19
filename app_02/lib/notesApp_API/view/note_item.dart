// lib/widgets/note_item.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../model/note.dart';
import '../view/note_detail_screen.dart';

class NoteItem extends StatelessWidget {
  final Note note;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const NoteItem({
    super.key,
    required this.note,
    required this.onDelete,
    required this.onEdit,
  });

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: note.color != null ? Color(int.parse('0xFF${note.color!.replaceAll("#", "")}')) : null,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NoteDetailScreen(note: note),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      note.title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    color: _getPriorityColor(note.priority),
                    child: Text(
                      note.priority == 1 ? 'Thấp' : note.priority == 2 ? 'Trung bình' : 'Cao',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                note.content.length > 50 ? '${note.content.substring(0, 50)}...' : note.content,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                'Cập nhật lần cuối: ${DateFormat('dd/MM/yyyy HH:mm').format(note.modifiedAt)}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              if (note.tags != null && note.tags!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4.0,
                  children: note.tags!.map((tag) => Chip(label: Text(tag, style: const TextStyle(fontSize: 12)))).toList(),
                ),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: onEdit,
                    tooltip: 'Chỉnh sửa',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Xóa Ghi chú'),
                          content: const Text('Bạn có chắc chắn muốn xóa ghi chú này không?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Hủy'),
                            ),
                            TextButton(
                              onPressed: () {
                                onDelete();
                                Navigator.pop(context);
                              },
                              child: const Text('Xóa', style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                    },
                    tooltip: 'Xóa',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}