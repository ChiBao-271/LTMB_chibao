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
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Color _getPriorityColor(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    switch (note.priority) {
      case 1:
        return isDarkMode ? Colors.green[300]! : Colors.green;
      case 2:
        return isDarkMode ? Colors.blue[300]! : Colors.blueAccent;
      case 3:
        return isDarkMode ? Colors.red[300]! : Colors.red;
      default:
        return isDarkMode ? Colors.grey[400]! : Colors.grey;
    }
  }

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
        return Icons.tag;
    }
  }

  Color _getTagColor(BuildContext context, String tag) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    switch (tag) {
      case 'Công Việc':
        return isDarkMode ? Colors.blue.shade300 : Colors.blue.shade100;
      case 'Học Tập':
        return isDarkMode ? Colors.green.shade300 : Colors.green.shade100;
      case 'Cá Nhân':
        return isDarkMode ? Colors.purple.shade300 : Colors.purple.shade100;
      case 'Mua Sắm':
        return isDarkMode ? Colors.orange.shade300 : Colors.orange.shade100;
      case 'Gia Đình':
        return isDarkMode ? Colors.red.shade300 : Colors.red.shade100;
      case 'Khác':
        return isDarkMode ? Colors.grey.shade600 : Colors.grey.shade200;
      default:
        return isDarkMode ? Colors.grey.shade600 : Colors.grey.shade200;
    }
  }

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
          : Theme.of(context).cardColor,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      note.title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodyLarge!.color,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(context).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _getPriorityText(note.priority),
                      style: TextStyle(
                        color: _getPriorityColor(context),
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                note.content,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodyMedium!.color,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _formatDateTime(note.createdAt),
                style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).textTheme.bodyMedium!.color,
                ),
              ),
              const SizedBox(height: 6),
              if (note.tags != null && note.tags!.isNotEmpty && note.tags!.first.isNotEmpty)
                Row(
                  children: [
                    Icon(
                      _getTagIcon(note.tags!.first),
                      size: 14,
                      color: Theme.of(context).textTheme.bodyMedium!.color,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        note.tags!.first,
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).textTheme.bodyMedium!.color,
                        ),
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      note.isCompleted ?? false
                          ? Icons.check_circle
                          : Icons.check_circle_outline,
                      size: 16,
                      color: note.isCompleted ?? false
                          ? Colors.green
                          : Theme.of(context).textTheme.bodyMedium!.color,
                    ),
                    onPressed: () => _toggleCompleted(context),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.edit,
                          size: 16,
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
                          size: 16,
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
                                .deleteNote(note.id!, note.userId);
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
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Theme.of(context).textTheme.titleLarge!.color,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                note.content,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).textTheme.bodyMedium!.color,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: _getPriorityColor(context).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Mức độ ưu tiên ${_getPriorityText(note.priority)}',
                  style: TextStyle(
                    color: _getPriorityColor(context),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Thời Gian Tạo: ${_formatDateTime(note.createdAt)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodyMedium!.color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Thời Gian Sửa: ${_formatDateTime(note.modifiedAt)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodyMedium!.color,
                ),
              ),
              const SizedBox(height: 8),
              if (note.tags != null && note.tags!.isNotEmpty) ...[
                Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: note.tags!
                      .where((tag) => tag.isNotEmpty)
                      .map((tag) {
                    return Chip(
                      label: Text(
                        tag,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodyMedium!.color,
                        ),
                      ),
                      backgroundColor: _getTagColor(context, tag),
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
              IconButton(
                icon: Icon(
                  note.isCompleted ?? false
                      ? Icons.check_circle
                      : Icons.check_circle_outline,
                  size: 24,
                  color: note.isCompleted ?? false
                      ? Colors.green
                      : Theme.of(context).textTheme.bodyMedium!.color,
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
                    await NoteDatabaseHelper.instance
                        .deleteNote(note.id!, note.userId);
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