import 'package:flutter/material.dart';
import '../db/auth_api.dart';
import '../db/note_database_helper.dart';
import '../models/note.dart';
import '../widgets/color_picker.dart';

class NoteForm extends StatefulWidget {
  final Note? note;

  const NoteForm({Key? key, this.note}) : super(key: key);

  @override
  _NoteFormState createState() => _NoteFormState();
}

class _NoteFormState extends State<NoteForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  late int _priority;
  late List<String> _tags;
  late String? _color;
  String? userId;

  final List<String> _availableTags = [
    'Công Việc',
    'Học Tập',
    'Cá Nhân',
    'Mua Sắm',
    'Gia Đình',
    'Khác',
  ];

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

  Color _darkenColor(Color color) {
    return Color.fromRGBO(
      (color.red * 0.8).round(),
      (color.green * 0.8).round(),
      (color.blue * 0.8).round(),
      1,
    );
  }

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');
    _priority = widget.note?.priority ?? 1;
    _tags = widget.note?.tags ?? [];
    _color = widget.note?.color;
    _initUser();
  }

  Future<void> _initUser() async {
    final user = AuthApi().getCurrentUser();
    if (user != null) {
      setState(() {
        userId = user.uid;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    if (_formKey.currentState!.validate() && userId != null) {
      final note = Note(
        id: widget.note?.id,
        userId: userId!,
        title: _titleController.text,
        content: _contentController.text,
        priority: _priority,
        createdAt: widget.note?.createdAt ?? DateTime.now(),
        modifiedAt: DateTime.now(),
        tags: _tags,
        color: _color,
        isCompleted: widget.note?.isCompleted ?? false,
      );

      try {
        if (widget.note == null) {
          await NoteDatabaseHelper.instance.insertNote(note);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Thêm ghi chú thành công'),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          await NoteDatabaseHelper.instance.updateNote(note);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cập nhật ghi chú thành công'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi lưu ghi chú: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng kiểm tra thông tin')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note == null ? 'Thêm Ghi Chú' : 'Chỉnh Sửa Ghi Chú'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Tiêu đề
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Tiêu Đề'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập tiêu đề';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Nội dung
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(labelText: 'Nội Dung'),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập nội dung';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Chọn mức độ ưu tiên
              DropdownButtonFormField<int>(
                value: _priority,
                decoration: const InputDecoration(labelText: 'Ưu Tiên'),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Thấp')),
                  DropdownMenuItem(value: 2, child: Text('Trung Bình')),
                  DropdownMenuItem(value: 3, child: Text('Cao')),
                ],
                onChanged: (value) {
                  setState(() {
                    _priority = value!;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Chọn màu sắc
              ColorPicker(
                selectedColor: _color,
                onColorChanged: (color) {
                  setState(() {
                    _color = color;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Chọn nhãn
              const Text(
                'Chọn Nhãn',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: _availableTags.map((tag) {
                  final isSelected = _tags.contains(tag);
                  return ChoiceChip(
                    label: Text(tag),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _tags.add(tag);
                        } else {
                          _tags.remove(tag);
                        }
                      });
                    },
                    selectedColor: _darkenColor(_getTagColor(tag)),
                    backgroundColor: _getTagColor(tag),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Nút lưu/cập nhật
              ElevatedButton(
                onPressed: _saveNote,
                child: Text(widget.note == null ? 'Lưu' : 'Cập Nhật'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}