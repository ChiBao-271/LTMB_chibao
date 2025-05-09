class Group {
  final String id;
  final String name;
  final String code;
  final String adminId;
  final List<String> members;
  final DateTime createdAt;

  Group({
    required this.id,
    required this.name,
    required this.code,
    required this.adminId,
    required this.members,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'adminId': adminId,
      'members': members,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Group.fromMap(Map<String, dynamic> map) {
    return Group(
      id: map['id'],
      name: map['name'],
      code: map['code'],
      adminId: map['adminId'],
      members: List<String>.from(map['members'] ?? []),
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}