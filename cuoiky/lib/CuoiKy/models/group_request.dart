class GroupRequest {
  final String id;
  final String groupId;
  final String userId;
  final String status;
  final DateTime createdAt;

  GroupRequest({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'groupId': groupId,
      'userId': userId,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory GroupRequest.fromMap(Map<String, dynamic> map) {
    return GroupRequest(
      id: map['id'],
      groupId: map['groupId'],
      userId: map['userId'],
      status: map['status'],
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}