import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../models/user.dart';
import '../models/task.dart';
import '../models/group.dart';
import '../models/group_request.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // CRUD for User
  Future<void> createUser(User user) async {
    try {
      await _firestore.collection('users').doc(user.id).set(user.toMap());
    } catch (e) {
      throw Exception('Lỗi khi tạo người dùng: $e');
    }
  }

  Future<User?> getUser(String id) async {
    try {
      final doc = await _firestore.collection('users').doc(id).get();
      if (doc.exists) {
        return User.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Lỗi khi lấy người dùng: $e');
    }
  }

  Future<String?> getUsernameById(String id) async {
    try {
      final doc = await _firestore.collection('users').doc(id).get();
      if (doc.exists) {
        return doc.data()!['username'] as String?;
      }
      return null;
    } catch (e) {
      throw Exception('Lỗi khi lấy tên người dùng: $e');
    }
  }

  Future<String?> getUserRoleById(String id) async {
    try {
      final doc = await _firestore.collection('users').doc(id).get();
      if (doc.exists) {
        return doc.data()!['role'] as String?;
      }
      return null;
    } catch (e) {
      throw Exception('Lỗi khi lấy vai trò người dùng: $e');
    }
  }

  Future<void> updateUser(User user) async {
    try {
      await _firestore.collection('users').doc(user.id).update(user.toMap());
    } catch (e) {
      throw Exception('Lỗi khi cập nhật người dùng: $e');
    }
  }

  // CRUD for Task
  Future<void> createTask(Task task) async {
    try {
      await _firestore.collection('tasks').doc(task.id).set(task.toMap());
    } catch (e) {
      throw Exception('Lỗi khi tạo công việc: $e');
    }
  }

  Future<void> updateTask(Task task) async {
    try {
      await _firestore.collection('tasks').doc(task.id).update(task.toMap());
    } catch (e) {
      throw Exception('Lỗi khi cập nhật công việc: $e');
    }
  }

  Future<void> deleteTask(String id) async {
    try {
      await _firestore.collection('tasks').doc(id).delete();
    } catch (e) {
      throw Exception('Lỗi khi xóa công việc: $e');
    }
  }

  Stream<List<Task>> getTasks({String? userId, String? status, String? category, String? groupId}) {
    Query<Map<String, dynamic>> query = _firestore.collection('tasks');
    if (userId != null) {
      query = query.where('assignedTo', isEqualTo: userId);
    }
    if (status != null) {
      query = query.where('status', isEqualTo: status);
    }
    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }
    if (groupId != null) {
      query = query.where('groupId', isEqualTo: groupId);
    }
    return query.snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Task.fromMap(doc.data())).toList());
  }

  // CRUD for Group
  Future<void> createGroup(Group group) async {
    try {
      await _firestore.collection('groups').doc(group.id).set(group.toMap());
    } catch (e) {
      throw Exception('Lỗi khi tạo nhóm: $e');
    }
  }

  Future<Group?> getGroup(String id) async {
    try {
      final doc = await _firestore.collection('groups').doc(id).get();
      if (doc.exists) {
        return Group.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Lỗi khi lấy nhóm: $e');
    }
  }

  Future<Group?> getGroupByCode(String code) async {
    try {
      final snapshot = await _firestore
          .collection('groups')
          .where('code', isEqualTo: code)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        return Group.fromMap(snapshot.docs.first.data());
      }
      return null;
    } catch (e) {
      throw Exception('Lỗi khi tìm nhóm bằng mã: $e');
    }
  }

  Future<List<Group>> getUserGroups(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('groups')
          .where('members', arrayContains: userId)
          .get();
      return snapshot.docs.map((doc) => Group.fromMap(doc.data())).toList();
    } catch (e) {
      throw Exception('Lỗi khi lấy danh sách nhóm của người dùng: $e');
    }
  }

  Future<void> updateGroup(Group group) async {
    try {
      await _firestore.collection('groups').doc(group.id).update(group.toMap());
    } catch (e) {
      throw Exception('Lỗi khi cập nhật nhóm: $e');
    }
  }

  // CRUD for Group Request
  Future<void> createGroupRequest(GroupRequest request) async {
    try {
      await _firestore.collection('group_requests').doc(request.id).set(request.toMap());
    } catch (e) {
      throw Exception('Lỗi khi tạo yêu cầu tham gia nhóm: $e');
    }
  }

  Stream<List<GroupRequest>> getGroupRequests(String groupId) {
    return _firestore
        .collection('group_requests')
        .where('groupId', isEqualTo: groupId)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) =>
        snapshot.docs.map((doc) => GroupRequest.fromMap(doc.data())).toList());
  }

  Future<void> updateGroupRequest(GroupRequest request) async {
    try {
      await _firestore.collection('group_requests').doc(request.id).update(request.toMap());
    } catch (e) {
      throw Exception('Lỗi khi cập nhật yêu cầu tham gia nhóm: $e');
    }
  }
}