import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/group.dart';
import '../models/group_request.dart';
import '../services/firestore_service.dart';

class GroupManagementScreen extends StatefulWidget {
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
  List<GroupRequest> _requests = [];

  @override
  void initState() {
    super.initState();
    _loadCurrentUserInfo();
  }

  Future<void> _loadCurrentUserInfo() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        setState(() {
          _currentUserId = user.uid;
        });
        final role = await _firestoreService.getUserRoleById(user.uid);
        setState(() {
          _currentUserRole = role ?? 'user';
        });
        await _loadGroups();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải thông tin người dùng: $e')),
      );
    }
  }

  Future<void> _loadGroups() async {
    if (_currentUserId == null) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final groups = await _firestoreService.getUserGroups(_currentUserId!);
      setState(() {
        _groups = groups;
        _isLoading = false;
      });
      for (var group in _groups) {
        if (group.adminId == _currentUserId) {
          _firestoreService.getGroupRequests(group.id).listen((requests) {
            setState(() {
              _requests = requests;
            });
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải danh sách nhóm: $e')),
      );
    }
  }

  Future<void> _createGroup() async {
    if (_groupNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng nhập tên nhóm')),
      );
      return;
    }
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không tìm thấy thông tin người dùng')),
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      final group = Group(
        id: Uuid().v4(),
        name: _groupNameController.text.trim(),
        code: Uuid().v4().substring(0, 8),
        adminId: _currentUserId!,
        members: [_currentUserId!],
        createdAt: DateTime.now(),
      );
      await _firestoreService.createGroup(group);
      _groupNameController.clear();
      await _loadGroups();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã tạo nhóm thành công')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tạo nhóm: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _joinGroup() async {
    if (_groupCodeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng nhập mã nhóm')),
      );
      return;
    }
    if (_currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không tìm thấy thông tin người dùng')),
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      final group = await _firestoreService.getGroupByCode(_groupCodeController.text.trim());
      if (group == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mã nhóm không hợp lệ')),
        );
        return;
      }
      if (group.members.contains(_currentUserId)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Bạn đã là thành viên của nhóm này')),
        );
        return;
      }
      final request = GroupRequest(
        id: Uuid().v4(),
        groupId: group.id,
        userId: _currentUserId!,
        status: 'pending',
        createdAt: DateTime.now(),
      );
      await _firestoreService.createGroupRequest(request);
      _groupCodeController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã gửi yêu cầu tham gia nhóm')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi gửi yêu cầu: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleRequest(GroupRequest request, bool accept) async {
    setState(() {
      _isLoading = true;
    });
    try {
      if (accept) {
        final group = await _firestoreService.getGroup(request.groupId);
        if (group != null) {
          final updatedMembers = List<String>.from(group.members)..add(request.userId);
          await _firestoreService.updateGroup(
            Group(
              id: group.id,
              name: group.name,
              code: group.code,
              adminId: group.adminId,
              members: updatedMembers,
              createdAt: group.createdAt,
            ),
          );
        }
      }
      await _firestoreService.updateGroupRequest(
        GroupRequest(
          id: request.id,
          groupId: request.groupId,
          userId: request.userId,
          status: accept ? 'accepted' : 'rejected',
          createdAt: request.createdAt,
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(accept ? 'Đã chấp nhận yêu cầu' : 'Đã từ chối yêu cầu')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi xử lý yêu cầu: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
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
              Container(
                padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
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
              DefaultTabController(
                length: _currentUserRole == 'admin' ? 3 : 2,
                child: Column(
                  children: [
                    TabBar(
                      labelColor: Colors.blue[700],
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Colors.blue[700],
                      tabs: [
                        Tab(text: 'Nhóm của bạn'),
                        Tab(text: 'Tham gia nhóm'),
                        if (_currentUserRole == 'admin') Tab(text: 'Yêu cầu tham gia'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _isLoading
                              ? Center(child: CircularProgressIndicator(color: Colors.blue[700]))
                              : _groups.isEmpty
                              ? Center(
                            child: Text(
                              'Bạn chưa tham gia nhóm nào',
                              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                            ),
                          )
                              : ListView.builder(
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            itemCount: _groups.length,
                            itemBuilder: (context, index) {
                              final group = _groups[index];
                              return Card(
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)),
                                child: ListTile(
                                  title: Text(
                                    group.name,
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue[700]),
                                  ),
                                  subtitle: Text(
                                    'Mã nhóm: ${group.code}',
                                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                  ),
                                  trailing: group.adminId == _currentUserId
                                      ? Icon(Icons.admin_panel_settings,
                                      color: Colors.blue[700])
                                      : null,
                                ),
                              );
                            },
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                            child: Column(
                              children: [
                                Card(
                                  elevation: 3,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20)),
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: TextField(
                                      controller: _groupCodeController,
                                      decoration: InputDecoration(
                                        labelText: 'Nhập mã nhóm',
                                        labelStyle: TextStyle(color: Colors.blue[700]),
                                        border: InputBorder.none,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 16),
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
                                      padding: EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    child: _isLoading
                                        ? CircularProgressIndicator(color: Colors.white)
                                        : Text(
                                      'Tham gia',
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
                          if (_currentUserRole == 'admin')
                            _isLoading
                                ? Center(child: CircularProgressIndicator(color: Colors.blue[700]))
                                : _requests.isEmpty
                                ? Center(
                              child: Text(
                                'Không có yêu cầu tham gia',
                                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                              ),
                            )
                                : ListView.builder(
                              padding:
                              EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              itemCount: _requests.length,
                              itemBuilder: (context, index) {
                                final request = _requests[index];
                                return Card(
                                  elevation: 3,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20)),
                                  child: ListTile(
                                    title: FutureBuilder<String?>(
                                      future: _firestoreService
                                          .getUsernameById(request.userId),
                                      builder: (context, snapshot) {
                                        return Text(
                                          snapshot.data ?? 'Người dùng',
                                          style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue[700]),
                                        );
                                      },
                                    ),
                                    subtitle: Text(
                                      'Yêu cầu tham gia nhóm',
                                      style: TextStyle(
                                          fontSize: 14, color: Colors.grey[600]),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.check,
                                              color: Colors.green),
                                          onPressed: () =>
                                              _handleRequest(request, true),
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.close, color: Colors.red),
                                          onPressed: () =>
                                              _handleRequest(request, false),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
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
      ),
      floatingActionButton: _currentUserRole == 'admin'
          ? FloatingActionButton(
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
                  child: Text('Hủy', style: TextStyle(color: Colors.grey)),
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
        child: Icon(Icons.add, color: Colors.white),
      )
          : null,
    );
  }

  @override
  void dispose() {
    _groupNameController.dispose();
    _groupCodeController.dispose();
    super.dispose();
  }
}