import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/group.dart';
import '../models/task.dart';
import '../services/firestore_service.dart';

class TaskFormScreen extends StatefulWidget {
  final VoidCallback onSave;
  final Task? task;

  TaskFormScreen({required this.onSave, this.task});

  @override
  _TaskFormScreenState createState() => _TaskFormScreenState();
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _status = 'To do';
  int _priority = 1;
  DateTime? _dueDate;
  String? _category;
  String? _assignedTo;
  String? _groupId;
  List<String> _attachments = [];
  bool _isLoading = false;
  final FirestoreService _firestoreService = FirestoreService();
  String? _currentUserRole;
  String? _currentUserId;
  List<Group> _groups = [];

  final List<Map<String, dynamic>> _categoryTags = [
    {
      'name': 'Công việc hàng ngày',
      'color': Color(0xFFBBDEFB),
      'textColor': Color(0xFF1976D2),
      'defaultTextColor': Color(0xFF455A64),
    },
    {
      'name': 'Công việc quan trọng',
      'color': Color(0xFFFFCDD2),
      'textColor': Color(0xFFD32F2F),
      'defaultTextColor': Color(0xFF455A64),
    },
    {
      'name': 'Công việc nhóm',
      'color': Color(0xFFC8E6C9),
      'textColor': Color(0xFF388E3C),
      'defaultTextColor': Color(0xFF455A64),
    },
    {
      'name': 'Công việc cá nhân',
      'color': Color(0xFFE1BEE7),
      'textColor': Color(0xFF7B1FA2),
      'defaultTextColor': Color(0xFF455A64),
    },
    {
      'name': 'Công việc dài hạn',
      'color': Color(0xFFFFE0B2),
      'textColor': Color(0xFFF57C00),
      'defaultTextColor': Color(0xFF455A64),
    },
    {
      'name': 'Công việc khẩn cấp',
      'color': Color(0xFFB2EBF2),
      'textColor': Color(0xFF0097A7),
      'defaultTextColor': Color(0xFF455A64),
    },
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
    if (widget.task != null) {
      _titleController.text = widget.task!.title;
      _descriptionController.text = widget.task!.description;
      _status = widget.task!.status;
      _priority = widget.task!.priority;
      _dueDate = widget.task!.dueDate;
      _category = widget.task!.category;
      _assignedTo = widget.task!.assignedTo;
      _groupId = widget.task!.groupId;
      _attachments = widget.task!.attachments ?? [];
    }
  }

  Future<void> _loadCurrentUserInfo() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không tìm thấy thông tin người dùng')),
        );
        return;
      }
      setState(() {
        _currentUserId = user.uid;
      });
      final role = await _firestoreService.getUserRoleById(user.uid);
      setState(() {
        _currentUserRole = role ?? 'user';
        if (_currentUserRole != 'admin' && widget.task == null) {
          _assignedTo = _currentUserId;
        }
      });
      final groups = await _firestoreService.getUserGroups(user.uid);
      setState(() {
        _groups = groups;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải thông tin người dùng: $e')),
      );
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue[700]!,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dueDate = picked;
      });
    }
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(allowMultiple: true);
      if (result != null) {
        setState(() {
          _attachments.addAll(result.files
              .map((file) => file.path ?? '')
              .where((path) => path.isNotEmpty)
              .toList());
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi chọn tệp: $e')),
      );
    }
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState!.validate()) {
      bool? confirm = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          title: Text(widget.task == null ? 'Xác nhận tạo' : 'Xác nhận cập nhật',
              style: TextStyle(color: Colors.blue[700])),
          content: Text(widget.task == null
              ? 'Bạn có muốn tạo công việc mới này không?'
              : 'Bạn có muốn cập nhật công việc này không?'),
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
          if (_titleController.text.trim().isEmpty) {
            throw Exception('Tiêu đề không được để trống');
          }
          if (_descriptionController.text.trim().isEmpty) {
            throw Exception('Mô tả không được để trống');
          }
          if (_status.isEmpty) {
            throw Exception('Trạng thái không được để trống');
          }
          if (_priority < 1 || _priority > 3) {
            throw Exception('Độ ưu tiên không hợp lệ');
          }
          if (_attachments.any((path) => path.isEmpty)) {
            throw Exception('Một hoặc nhiều tệp đính kèm không hợp lệ');
          }
          if (_currentUserId == null) {
            throw Exception('Không tìm thấy thông tin người dùng');
          }

          final task = Task(
            id: widget.task?.id ?? Uuid().v4(),
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            status: _status,
            priority: _priority,
            dueDate: _dueDate,
            createdAt: widget.task?.createdAt ?? DateTime.now(),
            updatedAt: DateTime.now(),
            assignedTo: _assignedTo?.trim().isNotEmpty ?? false ? _assignedTo!.trim() : null,
            createdBy: _currentUserId!,
            category: _category,
            attachments: _attachments.isNotEmpty ? _attachments : null,
            completed: false,
            groupId: _groupId,
          );

          if (widget.task == null) {
            await _firestoreService.createTask(task);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Đã tạo công việc thành công')),
            );
          } else {
            await _firestoreService.updateTask(task);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Đã cập nhật công việc thành công')),
            );
          }

          widget.onSave();
          Navigator.pop(context, true);
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi khi lưu: $e')),
          );
        } finally {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
                        widget.task == null ? 'Tạo mới' : 'Chỉnh sửa',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.blue[700]),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: TextFormField(
                              controller: _titleController,
                              decoration: InputDecoration(
                                labelText: 'Tiêu đề',
                                labelStyle: TextStyle(color: Colors.blue[700]),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                              validator: (value) =>
                              value!.trim().isEmpty ? 'Vui lòng nhập tiêu đề' : null,
                            ),
                          ),
                          SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: TextFormField(
                              controller: _descriptionController,
                              decoration: InputDecoration(
                                labelText: 'Mô tả',
                                labelStyle: TextStyle(color: Colors.blue[700]),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                              maxLines: 3,
                              validator: (value) =>
                              value!.trim().isEmpty ? 'Vui lòng nhập mô tả' : null,
                            ),
                          ),
                          SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: DropdownButtonFormField<String>(
                              value: _status,
                              decoration: InputDecoration(
                                labelText: 'Trạng thái',
                                labelStyle: TextStyle(color: Colors.blue[700]),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                              items: (widget.task == null
                                  ? [
                                {'value': 'To do', 'label': 'Cần làm'},
                                {'value': 'In progress', 'label': 'Đang làm'},
                              ]
                                  : [
                                {'value': 'To do', 'label': 'Cần làm'},
                                {'value': 'In progress', 'label': 'Đang làm'},
                                {'value': 'Done', 'label': 'Đã hoàn thành'},
                                {'value': 'Cancelled', 'label': 'Đã hủy'},
                              ])
                                  .map((item) => DropdownMenuItem(
                                value: item['value'],
                                child: Text(item['label']!),
                              ))
                                  .toList(),
                              onChanged: (value) => setState(() => _status = value!),
                              validator: (value) =>
                              value == null || value.isEmpty ? 'Vui lòng chọn trạng thái' : null,
                              isExpanded: true,
                            ),
                          ),
                             SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: DropdownButtonFormField<int>(
                              value: _priority,
                              decoration: InputDecoration(
                                labelText: 'Độ ưu tiên',
                                labelStyle: TextStyle(color: Colors.blue[700]),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                              items: [
                                DropdownMenuItem(value: 1, child: Text('Thấp')),
                                DropdownMenuItem(value: 2, child: Text('Trung bình')),
                                DropdownMenuItem(value: 3, child: Text('Cao')),
                              ],
                              onChanged: (value) => setState(() => _priority = value!),
                              validator: (value) =>
                              value == null ? 'Vui lòng chọn độ ưu tiên' : null,
                              isExpanded: true,
                            ),
                          ),
                          SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              title: Text(
                                _dueDate == null
                                    ? 'Chọn ngày đến hạn'
                                    : 'Hạn: ${DateFormat.yMd().format(_dueDate!)}',
                                style: TextStyle(color: Colors.blue[700]),
                              ),
                              onTap: _pickDate,
                            ),
                          ),
                          SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Danh mục',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.blue[700],
                                  ),
                                ),
                                SizedBox(height: 8),
                                Wrap(
                                  spacing: 8.0,
                                  runSpacing: 8.0,
                                  children: _categoryTags.map((tag) {
                                    final isSelected = _category == tag['name'];
                                    return ChoiceChip(
                                      label: Text(
                                        tag['name'],
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: isSelected
                                              ? tag['textColor']
                                              : tag['defaultTextColor'],
                                        ),
                                      ),
                                      selected: isSelected,
                                      backgroundColor: tag['color'],
                                      selectedColor: tag['color'],
                                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      onSelected: (selected) {
                                        setState(() {
                                          _category = selected ? tag['name'] : null;
                                        });
                                      },
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: TextFormField(
                                decoration: InputDecoration(
                                  labelText: 'Giao cho (ID người dùng)',
                                  labelStyle: TextStyle(color: Colors.blue[700]),
                                  border: InputBorder.none,
                                ),
                                onChanged: _currentUserRole == 'admin'
                                    ? (value) => _assignedTo = value
                                    : null,
                                initialValue: _assignedTo,
                                enabled: _currentUserRole == 'admin',
                                style: TextStyle(
                                  color: _currentUserRole == 'admin' ? Colors.black : Colors.grey[600],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: DropdownButtonFormField<String>(
                              value: _groupId,
                              decoration: InputDecoration(
                                labelText: 'Nhóm',
                                labelStyle: TextStyle(color: Colors.blue[700]),
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                              items: [
                                DropdownMenuItem(value: null, child: Text('Không thuộc nhóm')),
                                ..._groups
                                    .map((group) => DropdownMenuItem(
                                  value: group.id,
                                  child: Text(group.name),
                                ))
                                    .toList(),
                              ],
                              onChanged: (value) => setState(() => _groupId = value),
                              isExpanded: true,
                            ),
                          ),
                          SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              title: Text(
                                'Tệp đính kèm (${_attachments.length})',
                                style: TextStyle(color: Colors.blue[700]),
                              ),
                              onTap: _pickFiles,
                            ),
                          ),
                          if (_attachments.isNotEmpty)
                            Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _attachments
                                    .map((file) => Chip(
                                  label: Text(file.split('/').last),
                                  backgroundColor: Colors.blue[50],
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  onDeleted: () {
                                    setState(() {
                                      _attachments.remove(file);
                                    });
                                  },
                                ))
                                    .toList(),
                              ),
                            ),
                          SizedBox(height: 24),
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.blue[700]!, Colors.blue[500]!],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleSave,
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
                                'Lưu',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 16),
                        ],
                      ),
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
}