import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../models/group.dart';
import '../../models/group_request.dart';
import '../../services/firestore_service.dart';
import '../login_screen.dart';
import './group_detail_screen.dart';

class GroupManagementScreen extends StatefulWidget {
  const GroupManagementScreen({super.key});

  @override
  _GroupManagementScreenState createState() => _GroupManagementScreenState();
}

class _GroupManagementScreenState extends State<GroupManagementScreen> {
  final _groupNameController = TextEditingController();
  final _groupCodeController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;
  String? _currentUserId;
  String? _currentUserRole;
  List<Group> _groups = [];
  String? _errorMessage;
  final Map<String, Group> _groupCache = {};

  @override
  void initState() {
    super.initState();
    _loadCurrentUserInfo();
  }

  Future<void> _loadCurrentUserInfo() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
                (Route<dynamic> route) => false,
          );
        }
        return;
      }
      setState(() => _currentUserId = user.uid);
      final role = await _firestoreService.getUserRoleById(user.uid);
      setState(() {
        _currentUserRole = role ?? 'user';
        _isLoading = false;
      });
      await _loadGroups();
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi khi tải thông tin người dùng: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadGroups() async {
    if (_currentUserId == null) {
      setState(() {
        _errorMessage = 'Không tìm thấy thông tin người dùng, không thể tải danh sách nhóm!';
        _isLoading = false;
      });
      return;
    }
    setState(() => _isLoading = true);
    try {
      final groups = await _firestoreService.getUserGroups(_currentUserId!);
      setState(() {
        _groups = groups;
        for (var group in groups) {
          _groupCache[group.id] = group;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi khi tải danh sách nhóm: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _createGroup() async {
    final groupName = _groupNameController.text.trim();
    if (groupName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập tên nhóm!')),
      );
      return;
    }
    if (_currentUserId == null) {
      setState(() => _errorMessage = 'Không tìm thấy thông tin người dùng, không thể tạo nhóm!');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final group = Group(
        id: const Uuid().v4(),
        name: groupName,
        code: const Uuid().v4().substring(0, 8).toUpperCase(),
        adminId: _currentUserId!,
        members: [_currentUserId!],
        createdAt: DateTime.now(),
      );
      await _firestoreService.createGroup(group);
      _groupNameController.clear();
      await _loadGroups();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã tạo nhóm thành công!')),
      );
    } catch (e) {
      setState(() => _errorMessage = 'Lỗi khi tạo nhóm: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _joinGroup() async {
    final groupCode = _groupCodeController.text.trim().toUpperCase();
    if (groupCode.isEmpty || groupCode.length != 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mã nhóm phải là 8 ký tự!')),
      );
      return;
    }
    if (_currentUserId == null) {
      setState(() => _errorMessage = 'Không tìm thấy thông tin người dùng, không thể tham gia nhóm!');
      return;
    }
    setState(() => _isLoading = true);
    try {
      final group = await _firestoreService.getGroupByCode(groupCode);
      if (group == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mã nhóm không hợp lệ!')),
        );
        return;
      }
      if (group.members.contains(_currentUserId)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bạn đã ở trong nhóm này!')),
        );
        return;
      }
      final request = GroupRequest(
        id: const Uuid().v4(),
        groupId: group.id,
        userId: _currentUserId!,
        status: 'pending',
        createdAt: DateTime.now(),
      );
      await _firestoreService.createGroupRequest(request);
      _groupCodeController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã gửi yêu cầu tham gia nhóm!')),
      );
    } catch (e) {
      setState(() => _errorMessage = 'Lỗi khi gửi yêu cầu tham gia nhóm: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[50]!, Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Quản lý nhóm',
                      style: TextStyle(
                        fontSize: 24,
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
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                  ),
                ),
              if (_isLoading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator(color: Colors.blue)),
                )
              else if (_currentUserId != null)
                Expanded(
                  child: DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        TabBar(
                          labelColor: Colors.blue[700],
                          unselectedLabelColor: Colors.grey,
                          indicatorColor: Colors.blue[700],
                          tabs: const [
                            Tab(text: 'Nhóm của bạn'),
                            Tab(text: 'Tham gia nhóm'),
                          ],
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              _groups.isEmpty
                                  ? const Center(
                                child: Text(
                                  'Bạn chưa tham gia nhóm nào!',
                                  style: TextStyle(fontSize: 18, color: Colors.grey),
                                ),
                              )
                                  : ListView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                itemCount: _groups.length,
                                itemBuilder: (context, index) {
                                  final group = _groups[index];
                                  return Card(
                                    elevation: 3,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: Colors.blue[100],
                                        child: Text(
                                          group.name[0].toUpperCase(),
                                          style: TextStyle(color: Colors.blue[700]),
                                        ),
                                      ),
                                      title: Text(
                                        group.name,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue[700],
                                        ),
                                      ),
                                      subtitle: Text(
                                        'Mã nhóm: ${group.code}',
                                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                                      ),
                                      trailing: group.adminId == _currentUserId
                                          ? Icon(Icons.admin_panel_settings, color: Colors.blue[700])
                                          : null,
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => GroupDetailScreen(
                                              group: group,
                                              currentUserId: _currentUserId!,
                                            ),
                                          ),
                                        ).then((_) => _loadGroups());
                                      },
                                    ),
                                  );
                                },
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                                child: Column(
                                  children: [
                                    Card(
                                      elevation: 3,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: TextField(
                                          controller: _groupCodeController,
                                          decoration: InputDecoration(
                                            labelText: 'Nhập mã nhóm (8 ký tự)',
                                            labelStyle: TextStyle(color: Colors.blue[700]),
                                            border: InputBorder.none,
                                          ),
                                          textCapitalization: TextCapitalization.characters,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Container(
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [Colors.blue[700]!, Colors.blue[500]!],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: ElevatedButton(
                                        onPressed: _isLoading ? null : _joinGroup,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          padding: const EdgeInsets.symmetric(vertical: 16),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                        ),
                                        child: _isLoading
                                            ? const CircularProgressIndicator(color: Colors.white)
                                            : const Text(
                                          'Tham gia nhóm',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                const Expanded(
                  child: Center(
                    child: Text(
                      'Không tìm thấy thông tin người dùng!',
                      style: TextStyle(fontSize: 18, color: Colors.red),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue[700],
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('Tạo nhóm mới', style: TextStyle(color: Colors.blue[700])),
              content: TextField(
                controller: _groupNameController,
                decoration: InputDecoration(
                  labelText: 'Tên nhóm',
                  labelStyle: TextStyle(color: Colors.blue[700]),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: () {
                    _createGroup();
                    Navigator.pop(context);
                  },
                  child: Text('Tạo', style: TextStyle(color: Colors.blue[700])),
                ),
              ],
            ),
          );
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _groupCodeController.dispose();
    super.dispose();
  }
}