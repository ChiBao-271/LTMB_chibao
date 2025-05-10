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
  bool _isDataLoading = true;
  bool _isGroupMembersLoaded = false;
  final FirestoreService _firestoreService = FirestoreService();
  String? _currentUserRole;
  String? _currentUserId;
  List<Group> _groups = [];
  bool _isAdminOfGroup = false;
  List<String> _groupMembers = [];
  Map<String, String> _usernameCache = {};

  final List<Map<String, dynamic>> _categoryTags = [
    {'name': 'Công việc hàng ngày', 'color': Color(0xFFBBDEFB), 'textColor': Color(0xFF1976D2), 'defaultTextColor': Color(0xFF455A64)},
    {'name': 'Công việc quan trọng', 'color': Color(0xFFFFCDD2), 'textColor': Color(0xFFD32F2F), 'defaultTextColor': Color(0xFF455A64)},
    {'name': 'Công việc nhóm', 'color': Color(0xFFC8E6C9), 'textColor': Color(0xFF388E3C), 'defaultTextColor': Color(0xFF455A64)},
    {'name': 'Công việc cá nhân', 'color': Color(0xFFE1BEE7), 'textColor': Color(0xFF7B1FA2), 'defaultTextColor': Color(0xFF455A64)},
    {'name': 'Công việc dài hạn', 'color': Color(0xFFFFE0B2), 'textColor': Color(0xFFF57C00), 'defaultTextColor': Color(0xFF455A64)},
    {'name': 'Công việc khẩn cấp', 'color': Color(0xFFB2EBF2), 'textColor': Color(0xFF0097A7), 'defaultTextColor': Color(0xFF455A64)},
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
      _attachments = widget.task!.attachments ?? [];
    }
  }

  Future<void> _loadCurrentUserInfo() async {
    setState(() => _isDataLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không tìm thấy thông tin người dùng!')),
          );
        }
        setState(() => _isDataLoading = false);
        return;
      }
      setState(() => _currentUserId = user.uid);
      print('Current user ID: $_currentUserId');
      final role = await _firestoreService.getUserRoleById(user.uid);
      final groups = await _firestoreService.getUserGroups(user.uid);

      for (var group in groups) {
        for (var memberId in group.members) {
          if (!_usernameCache.containsKey(memberId)) {
            try {
              final username = await _firestoreService.getUsernameById(memberId);
              _usernameCache[memberId] = username ?? 'Người dùng không xác định';
              print('Loaded username for $memberId: ${_usernameCache[memberId]}');
            } catch (e) {
              print('Error loading username for $memberId: $e');
              _usernameCache[memberId] = 'Người dùng không xác định';
            }
          }
        }
      }

      if (mounted) {
        setState(() {
          _currentUserRole = role ?? 'user';
          _groups = groups;
          if (widget.task == null) {
            _groupId = null;
            _assignedTo = _currentUserId;
          }
        });
      }

      if (widget.task?.groupId != null) {
        final taskGroupId = widget.task!.groupId!;
        print('Task groupId: $taskGroupId, Available groups: ${_groups.map((g) => g.id).toList()}');
        if (_groups.any((group) => group.id == taskGroupId)) {
          _groupId = taskGroupId;
          await _loadGroupMembers(taskGroupId);
          if (widget.task?.assignedTo != null && _groupMembers.isNotEmpty) {
            final taskAssignedTo = widget.task!.assignedTo!;
            print('Task assignedTo: $taskAssignedTo, Group members: $_groupMembers');
            if (_groupMembers.contains(taskAssignedTo)) {
              _assignedTo = taskAssignedTo;
            } else {
              print('AssignedTo $taskAssignedTo không hợp lệ, reset về null');
              _assignedTo = null;
            }
          } else {
            print('AssignedTo không được set vì _groupMembers rỗng hoặc task.assignedTo null');
            _assignedTo = null;
          }
        } else {
          print('GroupId $taskGroupId không hợp lệ, reset về null');
          _groupId = null;
          _assignedTo = null;
        }
      }

      if (_groupId != null) {
        final group = await _firestoreService.getGroup(_groupId!);
        if (group != null && group.adminId == _currentUserId) {
          if (mounted) {
            setState(() => _isAdminOfGroup = true);
          }
        } else {
          if (mounted) {
            setState(() {
              _isAdminOfGroup = false;
              _assignedTo = _currentUserId;
            });
          }
        }
      }
      if (mounted) {
        setState(() => _isDataLoading = false);
      }
    } catch (e) {
      print('Lỗi khi tải thông tin người dùng: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi tải thông tin người dùng: $e')),
        );
        setState(() => _isDataLoading = false);
      }
    }
  }

  Future<void> _loadGroupMembers(String groupId) async {
    if (_isGroupMembersLoaded) {
      print('Group members already loaded for group $groupId: $_groupMembers');
      return;
    }
    try {
      final group = await _firestoreService.getGroup(groupId);
      if (group != null) {
        if (mounted) {
          setState(() {
            _groupMembers = group.members;
            _isGroupMembersLoaded = true;
            print('Loaded group members for group $groupId: $_groupMembers');
            if (_groupMembers.isEmpty) {
              print('Group $groupId không có thành viên, reset assignedTo về null');
              _assignedTo = null;
            } else if (_assignedTo != null && !_groupMembers.contains(_assignedTo)) {
              print('AssignedTo $_assignedTo không còn trong nhóm $groupId, reset về null');
              _assignedTo = null;
            }
          });
        }
      } else {
        print('Nhóm $groupId không tồn tại, reset groupId và assignedTo');
        if (mounted) {
          setState(() {
            _groupMembers = [];
            _groupId = null;
            _assignedTo = null;
            _isGroupMembersLoaded = false;
          });
        }
      }
    } catch (e) {
      print('Lỗi khi tải danh sách thành viên cho nhóm $groupId: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi tải danh sách thành viên: $e')),
        );
        setState(() {
          _groupMembers = [];
          _groupId = null;
          _assignedTo = null;
          _isGroupMembersLoaded = false;
        });
      }
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
    if (picked != null && mounted) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(allowMultiple: true);
      if (result != null && mounted) {
        setState(() {
          _attachments.addAll(result.files
              .map((file) => file.path ?? '')
              .where((path) => path.isNotEmpty)
              .toList());
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi chọn tệp: $e')),
        );
      }
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
              child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Xác nhận', style: TextStyle(color: Colors.blue[700])),
            ),
          ],
        ),
      );

      if (confirm == true && mounted) {
        setState(() => _isLoading = true);
        try {
          if (_titleController.text.trim().isEmpty) {
            throw Exception('Tiêu đề không được để trống!');
          }
          if (_descriptionController.text.trim().isEmpty) {
            throw Exception('Mô tả không được để trống!');
          }
          if (_status.isEmpty) {
            throw Exception('Trạng thái không được để trống!');
          }
          if (_priority < 1 || _priority > 3) {
            throw Exception('Độ ưu tiên không hợp lệ!');
          }
          if (_attachments.any((path) => path.isEmpty)) {
            throw Exception('Một hoặc nhiều tệp đính kèm không hợp lệ!');
          }
          if (_currentUserId == null) {
            throw Exception('Không tìm thấy thông tin người dùng!');
          }
          if (_groupId != null && !_isAdminOfGroup && _assignedTo != _currentUserId) {
            throw Exception('Chỉ admin của nhóm mới được giao công việc!');
          }

          final task = Task(
            id: widget.task?.id ?? const Uuid().v4(),
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
            completed: _status == 'Done',
            groupId: _groupId,
          );

          if (widget.task == null) {
            await _firestoreService.createTask(task);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã tạo công việc thành công!')),
              );
            }
          } else {
            await _firestoreService.updateTask(task);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã cập nhật công việc thành công!')),
              );
            }
          }

          widget.onSave();
          if (mounted) {
            Navigator.pop(context, true);
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Lỗi khi lưu công việc: $e')),
            );
          }
        } finally {
          if (mounted) {
            setState(() => _isLoading = false);
          }
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
            child: _isDataLoading
                ? Center(child: CircularProgressIndicator(color: Colors.blue[700]))
                : Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
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
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                              validator: (value) => value!.trim().isEmpty ? 'Vui lòng nhập tiêu đề!' : null,
                            ),
                          ),
                          const SizedBox(height: 16),
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
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                              maxLines: 3,
                              validator: (value) => value!.trim().isEmpty ? 'Vui lòng nhập mô tả!' : null,
                            ),
                          ),
                          const SizedBox(height: 16),
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
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                              items: widget.task == null
                                  ? [
                                {'value': 'To do', 'label': 'Cần làm'},
                                {'value': 'In progress', 'label': 'Đang làm'},
                              ]
                                  .map((item) => DropdownMenuItem(
                                value: item['value'],
                                child: Text(item['label']!),
                              ))
                                  .toList()
                                  : (_isAdminOfGroup
                                  ? [
                                {'value': 'To do', 'label': 'Cần làm'},
                                {'value': 'In progress', 'label': 'Đang làm'},
                                {'value': 'Done', 'label': 'Đã hoàn thành'},
                                {'value': 'Cancelled', 'label': 'Đã hủy'},
                              ]
                                  : [
                                {'value': 'To do', 'label': 'Cần làm'},
                                {'value': 'Done', 'label': 'Đã hoàn thành'},
                              ])
                                  .map((item) => DropdownMenuItem(
                                value: item['value'],
                                child: Text(item['label']!),
                              ))
                                  .toList(),
                              onChanged: (value) => setState(() => _status = value!),
                              validator: (value) => value == null || value.isEmpty ? 'Vui lòng chọn trạng thái!' : null,
                              isExpanded: true,
                            ),
                          ),
                          const SizedBox(height: 16),
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
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                              items: const [
                                DropdownMenuItem(value: 1, child: Text('Thấp')),
                                DropdownMenuItem(value: 2, child: Text('Trung bình')),
                                DropdownMenuItem(value: 3, child: Text('Cao')),
                              ],
                              onChanged: (value) => setState(() => _priority = value!),
                              validator: (value) => value == null ? 'Vui lòng chọn độ ưu tiên!' : null,
                              isExpanded: true,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              leading: Icon(Icons.calendar_today, color: Colors.blue[700]),
                              title: Text(
                                _dueDate == null ? 'Chọn ngày đến hạn' : 'Hạn: ${DateFormat.yMd().format(_dueDate!)}',
                                style: TextStyle(color: Colors.blue[700]),
                              ),
                              onTap: _pickDate,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Danh mục',
                                  style: TextStyle(fontSize: 16, color: Colors.blue[700]),
                                ),
                                const SizedBox(height: 8),
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
                                          color: isSelected ? tag['textColor'] : tag['defaultTextColor'],
                                        ),
                                      ),
                                      selected: isSelected,
                                      backgroundColor: tag['color'],
                                      selectedColor: tag['color'],
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      onSelected: (selected) {
                                        setState(() => _category = selected ? tag['name'] : null);
                                      },
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
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
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                              items: _groups.isEmpty
                                  ? [const DropdownMenuItem(value: null, child: Text('Cá nhân'), enabled: true)]
                                  : [
                                const DropdownMenuItem(value: null, child: Text('Cá nhân')),
                                ..._groups
                                    .map((group) => DropdownMenuItem(value: group.id, child: Text(group.name)))
                                    .toList(),
                              ],
                              onChanged: (value) async {
                                setState(() {
                                  _groupId = value;
                                  _isAdminOfGroup = false;
                                  _groupMembers = [];
                                  _assignedTo = _groupId == null ? _currentUserId : null;
                                  _isGroupMembersLoaded = false;
                                });
                                if (value != null) {
                                  await _loadGroupMembers(value);
                                  final group = await _firestoreService.getGroup(value);
                                  if (group != null && group.adminId == _currentUserId && mounted) {
                                    setState(() => _isAdminOfGroup = true);
                                  }
                                }
                              },
                              isExpanded: true,
                            ),
                          ),
                          const SizedBox(height: 16),
                          FutureBuilder(
                            key: ValueKey(_groupId),
                            future: _groupId != null ? _loadGroupMembers(_groupId!) : Future.value(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator(color: Colors.blue));
                              }
                              if (snapshot.hasError) {
                                print('FutureBuilder error: ${snapshot.error}');
                                return Text('Lỗi khi tải thành viên: ${snapshot.error}', style: const TextStyle(color: Colors.red));
                              }
                              if (_groupMembers.isEmpty || (_assignedTo != null && !_groupMembers.contains(_assignedTo))) {
                                print('Pre-render check: _assignedTo $_assignedTo không hợp lệ hoặc _groupMembers rỗng, reset về null');
                                _assignedTo = _groupId == null ? _currentUserId : null;
                              }
                              print('Render dropdown _assignedTo: value=$_assignedTo, items=${_groupMembers.isEmpty ? '[null]' : _groupMembers}');
                              return Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: DropdownButtonFormField<String>(
                                  value: _assignedTo,
                                  decoration: InputDecoration(
                                    labelText: 'Giao cho',
                                    labelStyle: TextStyle(color: Colors.blue[700]),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  ),
                                  items: _groupId == null
                                      ? [
                                    DropdownMenuItem(
                                      value: _currentUserId,
                                      child: Text(_usernameCache[_currentUserId] ?? 'Người dùng không xác định'),
                                    )
                                  ]
                                      : _groupMembers.isEmpty
                                      ? [
                                    const DropdownMenuItem(
                                        value: null, child: Text('Không có thành viên'), enabled: false)
                                  ]
                                      : [
                                    const DropdownMenuItem(value: null, child: Text('Không giao cho ai')),
                                    ..._groupMembers
                                        .map((memberId) => DropdownMenuItem(
                                      value: memberId,
                                      child: Text(_usernameCache[memberId] ?? 'Người dùng không xác định'),
                                    ))
                                        .toList(),
                                  ],
                                  onChanged: (_isAdminOfGroup && _groupId != null && _groupMembers.isNotEmpty)
                                      ? (value) => setState(() => _assignedTo = value)
                                      : null,
                                  isExpanded: true,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              title: Text('Tệp đính kèm (${_attachments.length})', style: TextStyle(color: Colors.blue[700])),
                              onTap: _pickFiles,
                            ),
                          ),
                          if (_attachments.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _attachments
                                    .map((file) => Chip(
                                  label: Text(file.split('/').last),
                                  backgroundColor: Colors.blue[50],
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  onDeleted: () => setState(() => _attachments.remove(file)),
                                ))
                                    .toList(),
                              ),
                            ),
                          const SizedBox(height: 24),
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
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(color: Colors.white)
                                  : const Text(
                                'Lưu',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
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
              child: Center(child: CircularProgressIndicator(color: Colors.blue[700])),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}