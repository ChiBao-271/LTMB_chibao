import 'package:flutter/material.dart';

class Note {
  final int? id;
  final String title;
  final String content;
  final int priority;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final List<String>? tags;
  final String? color;
  final bool isCompleted; // Thêm trường isCompleted

  Note({
    this.id,
    required this.title,
    required this.content,
    required this.priority,
    required this.createdAt,
    required this.modifiedAt,
    this.tags,
    this.color,
    required this.isCompleted, // Yêu cầu giá trị khi tạo Note
  });

  // Named constructor từ Map
  Note.fromMap(Map<String, dynamic> map)
      : id = map['id'],
        title = map['title'],
        content = map['content'],
        priority = map['priority'],
        createdAt = DateTime.parse(map['createdAt']),
        modifiedAt = DateTime.parse(map['modifiedAt']),
        tags = map['tags'] != null ? List<String>.from(map['tags'].split(',')) : null,
        color = map['color'],
        isCompleted = map['isCompleted'] == 1; // Chuyển từ int (SQLite) sang bool

  // Chuyển đổi thành Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'priority': priority,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt.toIso8601String(),
      'tags': tags?.join(','),
      'color': color,
      'isCompleted': isCompleted ? 1 : 0, // Chuyển bool sang int để lưu vào SQLite
    };
  }

  // Tạo bản sao với các thuộc tính được cập nhật
  Note copyWith({
    int? id,
    String? title,
    String? content,
    int? priority,
    DateTime? createdAt,
    DateTime? modifiedAt,
    List<String>? tags,
    String? color,
    bool? isCompleted,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      priority: priority ?? this.priority,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      tags: tags ?? this.tags,
      color: color ?? this.color,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  @override
  String toString() {
    return 'Note(id: $id, title: $title, priority: $priority, createdAt: $createdAt, isCompleted: $isCompleted)';
  }
}