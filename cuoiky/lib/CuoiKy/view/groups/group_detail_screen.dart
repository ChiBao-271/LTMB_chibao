import 'package:flutter/material.dart';
import '../../models/group.dart';
import '../../models/group_request.dart';
import '../../models/task.dart';
import '../../services/firestore_service.dart';

class GroupDetailScreen extends StatefulWidget {
  final Group group;
  final String currentUserId;

  const GroupDetailScreen({
    super.key,
    required this.group,
    required this.currentUserId,
  });

  @override
  _GroupDetailScreenState createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  List<String> _members = [];
  List<GroupRequest> _requests = [];
  bool _isLoading = false;
  String? _errorMessage;
  final Map<String, String> _usernameCache = {};

  @override
  void initState() {
    super.initState();
    _loadMembers();
    if (widget.group.adminId == widget.currentUserId) {
      _loadRequests();
    }
  }

  Future<void> _loadMembers() async {
    setState(() => _isLoading = true);
    try {
      _members = widget.group.members;
      for (var memberId in _members) {
        if (!_usernameCache.containsKey(memberId)) {
          final username = await _firestoreService.getUsernameById(memberId);
          _usernameCache[memberId] = username ?? 'Người dùng không xác định';
        }
      }
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi khi tải danh sách thành viên: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRequests() async {
    try {
      _firestoreService.getGroupRequests(widget.group.id).listen((requests) {
        if (mounted) {
          setState(() => _requests = requests);
          for (var request in requests) {
            if (!_usernameCache.containsKey(request.userId)) {
              _firestoreService.getUsernameById(request.userId).then((username) {
                setState(() {
                  _usernameCache[request.userId] = username ?? 'Người dùng không xác định';
                });
              });
            }
          }
        }
      });
    } catch (e) {
      setState(() => _errorMessage = 'Lỗi khi tải danh sách yêu cầu: $e');
    }
  }

  Future<void> _handleRequest(GroupRequest request, bool accept) async {
    setState(() => _isLoading = true);
    try {
      if (accept) {
        final updatedMembers = List<String>.from(widget.group.members)..add(request.userId);
        await _firestoreService.updateGroup(
          Group(
            id: widget.group.id,
            name: widget.group.name,
            code: widget.group.code,
            adminId: widget.group.adminId,
            members: updatedMembers,
            createdAt: widget.group.createdAt,
          ),
        );
        setState(() => _members = updatedMembers);
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
        SnackBar(
          content: Text(accept ? 'Đã chấp nhận yêu cầu!' : 'Đã từ chối yêu cầu!'),
        ),
      );
    } catch (e) {
      setState(() => _errorMessage = 'Lỗi khi xử lý yêu cầu: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removeMember(String memberId) async {
    if (memberId == widget.group.adminId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không thể xóa admin!')),
      );
      return;
    }
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: Text('Xác nhận xóa', style: TextStyle(color: Colors.blue[700])),
        content: Text('Bạn có chắc chắn muốn xóa ${_usernameCache[memberId]} khỏi nhóm?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        print('Xóa thành viên $memberId khỏi nhóm ${widget.group.id}');
        // Cập nhật tasks có assignedTo là memberId trước
        final tasksSnapshot = await _firestoreService
            .getTasks(groupId: widget.group.id, userId: memberId)
            .first;
        for (var task in tasksSnapshot) {
          print('Cập nhật task ${task.id}: reset assignedTo từ $memberId về null');
          await _firestoreService.updateTask(
            task.copyWith(assignedTo: null, updatedAt: DateTime.now()),
          );
        }
        // Đợi Firestore đồng bộ
        await Future.delayed(Duration(seconds: 1));

        // Xóa thành viên khỏi nhóm
        final updatedMembers = List<String>.from(widget.group.members)..remove(memberId);
        await _firestoreService.updateGroup(
          Group(
            id: widget.group.id,
            name: widget.group.name,
            code: widget.group.code,
            adminId: widget.group.adminId,
            members: updatedMembers,
            createdAt: widget.group.createdAt,
          ),
        );

        setState(() => _members = updatedMembers);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã xóa thành viên khỏi nhóm!')),
        );
      } catch (e) {
        print('Lỗi khi xóa thành viên $memberId: $e');
        setState(() => _errorMessage = 'Lỗi khi xóa thành viên: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showTasksForMember(String memberId, String memberName) async {
    setState(() => _isLoading = true);
    try {
      final tasksStream = _firestoreService.getTasks(
        userId: memberId,
        groupId: widget.group.id,
      );
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          builder: (context, scrollController) => Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Công việc của $memberName',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: StreamBuilder<List<Task>>(
                    stream: tasksStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Text(
                          'Lỗi khi tải công việc: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                        );
                      }
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final tasks = snapshot.data!;
                      if (tasks.isEmpty) {
                        return const Center(
                          child: Text(
                            'Không có công việc nào!',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        );
                      }
                      return ListView.builder(
                        controller: scrollController,
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final task = tasks[index];
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              title: Text(
                                task.title,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                ),
                              ),
                              subtitle: Text(
                                'Trạng thái: ${task.status}\nHạn: ${task.dueDate?.toString().substring(0, 10) ?? 'Không có'}\nDanh mục: ${task.category ?? 'Không có'}',
                                style: const TextStyle(fontSize: 14, color: Colors.grey),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      setState(() => _errorMessage = 'Lỗi khi tải công việc: $e');
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
                      widget.group.name,
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
              else
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Thành viên (${_members.length})',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                        const SizedBox(height: 10),
                        AnimatedList(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          initialItemCount: _members.length,
                          itemBuilder: (context, index, animation) {
                            final memberId = _members[index];
                            return SizeTransition(
                              sizeFactor: animation,
                              child: Card(
                                elevation: 3,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.blue[100],
                                    child: Text(
                                      _usernameCache[memberId]![0].toUpperCase(),
                                      style: TextStyle(color: Colors.blue[700]),
                                    ),
                                  ),
                                  title: Text(
                                    _usernameCache[memberId] ?? 'Người dùng không xác định',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                  subtitle: Text(
                                    memberId == widget.group.adminId ? 'Admin' : 'Thành viên',
                                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                                  ),
                                  trailing: widget.group.adminId == widget.currentUserId &&
                                      memberId != widget.currentUserId
                                      ? IconButton(
                                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                                    onPressed: () => _removeMember(memberId),
                                  )
                                      : null,
                                  onTap: () => _showTasksForMember(memberId, _usernameCache[memberId]!),
                                ),
                              ),
                            );
                          },
                        ),
                        if (widget.group.adminId == widget.currentUserId) ...[
                          const SizedBox(height: 20),
                          Text(
                            'Yêu cầu tham gia (${_requests.length})',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                          const SizedBox(height: 10),
                          _requests.isEmpty
                              ? const Center(
                            child: Text(
                              'Không có yêu cầu tham gia nào!',
                              style: TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                          )
                              : AnimatedList(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            initialItemCount: _requests.length,
                            itemBuilder: (context, index, animation) {
                              final request = _requests[index];
                              return SizeTransition(
                                sizeFactor: animation,
                                child: Card(
                                  elevation: 3,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: Colors.blue[100],
                                      child: Text(
                                        _usernameCache[request.userId]?[0].toUpperCase() ?? '?',
                                        style: TextStyle(color: Colors.blue[700]),
                                      ),
                                    ),
                                    title: Text(
                                      _usernameCache[request.userId] ?? 'Người dùng không xác định',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue[700],
                                      ),
                                    ),
                                    subtitle: const Text(
                                      'Yêu cầu tham gia nhóm',
                                      style: TextStyle(fontSize: 14, color: Colors.grey),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.check, color: Colors.green),
                                          onPressed: () => _handleRequest(request, true),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.close, color: Colors.red),
                                          onPressed: () => _handleRequest(request, false),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}