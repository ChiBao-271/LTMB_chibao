import 'package:flutter/material.dart';
import '../db/note_database_helper.dart';
import '../models/note.dart';

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
  bool _showColorPicker = false;

  // Danh sách 12 màu mix
  final List<Map<String, dynamic>> _colorOptions = [
    {'hex': '#CFF4D2', 'name': 'Xanh Bạc Hà Nhạt'},
    {'hex': '#FFD1DC', 'name': 'Hồng Phấn Nhạt'},
    {'hex': '#E6D7F5', 'name': 'Tím Pastel Nhẹ'},
    {'hex': '#FFE8B5', 'name': 'Vàng Mơ Nhạt'},
    {'hex': '#C9E4F6', 'name': 'Xanh Lam Nhẹ'},
    {'hex': '#FFDAB9', 'name': 'Cam Đào Nhạt'},
    {'hex': '#E0F7E9', 'name': 'Xanh Lá Nhạt'},
    {'hex': '#E8DAEF', 'name': 'Tím Oải Hương Nhạt'},
    {'hex': '#D6EAF8', 'name': 'Xanh Ngọc Bích Nhạt'},
    {'hex': '#FFE4E1', 'name': 'Hồng Anh Đào Nhạt'},
    {'hex': '#D6E4E5', 'name': 'Xanh Phấn Nhạt'},
    {'hex': '#FFF5E4', 'name': 'Vàng Kem Nhạt'},
  ];

  // Danh sách nhãn có sẵn
  final List<String> _availableTags = [
    'Công Việc',
    'Học Tập',
    'Cá Nhân',
    'Mua Sắm',
    'Gia Đình',
    'Khác',
  ];

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

  // Hàm làm đậm màu khi tag được chọn
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
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    if (_formKey.currentState!.validate()) {
      final note = Note(
        id: widget.note?.id,
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
        } else {
          await NoteDatabaseHelper.instance.updateNote(note);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã cập nhật thành công'),
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
              // Nút để hiển thị/ẩn các ô màu
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showColorPicker = !_showColorPicker;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Chọn Màu Sắc',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Icon(
                        _showColorPicker ? Icons.expand_less : Icons.expand_more,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
              // Hiển thị các ô màu khi _showColorPicker là true
              if (_showColorPicker) ...[
                const SizedBox(height: 8),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 6,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemCount: _colorOptions.length,
                  itemBuilder: (context, index) {
                    final colorOption = _colorOptions[index];
                    final colorHex = colorOption['hex'] as String;
                    final isSelected = _color == colorHex;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _color = colorHex;
                          _showColorPicker = false;
                        });
                      },
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Color(int.parse('0xFF${colorHex.substring(1)}')),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? Colors.black : Colors.grey.withOpacity(0.3),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: isSelected
                              ? const Icon(
                            Icons.check,
                            color: Colors.black,
                            size: 16,
                          )
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              ],
              // Chọn nhãn từ danh sách có sẵn
              const SizedBox(height: 16),
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
                    selectedColor: _darkenColor(_getTagColor(tag)), // Màu khi được chọn
                    backgroundColor: _getTagColor(tag), // Màu khi không được chọn
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
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