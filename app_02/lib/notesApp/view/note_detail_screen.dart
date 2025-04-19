// lib/screens/note_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../model/note.dart';
import 'note_form_screen.dart';

class NoteDetailScreen extends StatelessWidget {
  final Note note;

  const NoteDetailScreen({super.key, required this.note});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết Ghi chú'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NoteFormScreen(note: note),
                ),
              );
            },
            tooltip: 'Chỉnh sửa',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              note.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Ưu tiên: ${note.priority == 1 ? 'Thấp' : note.priority == 2 ? 'Trung bình' : 'Cao'}',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              note.content,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Text(
              'Ngày tạo: ${DateFormat('dd/MM/yyyy HH:mm').format(note.createdAt)}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            Text(
              'Cập nhật lần cuối: ${DateFormat('dd/MM/yyyy HH:mm').format(note.modifiedAt)}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            if (note.tags != null && note.tags!.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Nhãn:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Wrap(
                spacing: 8.0,
                children: note.tags!.map((tag) => Chip(label: Text(tag))).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}