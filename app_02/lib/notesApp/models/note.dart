import 'package:flutter/material.dart';

class Note {
  final int? id;
  final String userId; // Thêm userId để liên kết với user
  final String title;
  final String content;
  final int priority;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final List<String>? tags;
  final String? color;
  final bool isCompleted;

  Note({
    this.id,
    required this.userId, // Thêm userId vào constructor
    required this.title,
    required this.content,
    required this.priority,
    required this.createdAt,
    required this.modifiedAt,
    this.tags,
    this.color,
    required this.isCompleted,
  });

  Note.fromMap(Map<String, dynamic> map)
      : id = map['id'],
        userId = map['userId'], // Thêm userId vào fromMap
        title = map['title'],
        content = map['content'],
        priority = map['priority'],
        createdAt = DateTime.parse(map['createdAt']),
        modifiedAt = DateTime.parse(map['modifiedAt']),
        tags = map['tags'] != null ? List<String>.from(map['tags'].split(',')) : null,
        color = map['color'],
        isCompleted = map['isCompleted'] == 1;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId, // Thêm userId vào toMap
      'title': title,
      'content': content,
      'priority': priority,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt.toIso8601String(),
      'tags': tags?.join(','),
      'color': color,
      'isCompleted': isCompleted ? 1 : 0,
    };
  }

  Note copyWith({
    int? id,
    String? userId, // Thêm userId vào copyWith
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
      userId: userId ?? this.userId, // Thêm userId vào copyWith
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
    return 'Note(id: $id, userId: $userId, title: $title, priority: $priority, createdAt: $createdAt, isCompleted: $isCompleted)';
  }
}