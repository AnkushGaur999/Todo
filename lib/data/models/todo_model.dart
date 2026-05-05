import 'dart:math';
import 'package:hive/hive.dart';

part 'todo_model.g.dart';

@HiveType(typeId: 0)
class TodoModel extends HiveObject {
  @HiveField(0)
  final int id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final bool completed;

  @HiveField(3)
  final bool isSynced;

  @HiveField(4)
  final String? localId;

  @HiveField(5)
  final String pendingAction;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final DateTime updatedAt;

  @HiveField(8)
  final DateTime? deletedAt;

  TodoModel({
    required this.id,
    required this.title,
    required this.completed,
    this.isSynced = true,
    this.localId,
    this.pendingAction = 'none',
    DateTime? createdAt,
    DateTime? updatedAt,
    this.deletedAt,
  })  : createdAt = createdAt ?? _generateRandomDate(),
        updatedAt = updatedAt ?? _generateRandomDate();

  static DateTime _generateRandomDate() {
    final random = Random();
    return DateTime.now().subtract(Duration(
      days: random.nextInt(30),
      hours: random.nextInt(24),
      minutes: random.nextInt(60),
    ));
  }

  TodoModel copyWith({
    int? id,
    String? title,
    bool? completed,
    bool? isSynced,
    String? localId,
    String? pendingAction,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) =>
      TodoModel(
        id: id ?? this.id,
        title: title ?? this.title,
        completed: completed ?? this.completed,
        isSynced: isSynced ?? this.isSynced,
        localId: localId ?? this.localId,
        pendingAction: pendingAction ?? this.pendingAction,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: deletedAt ?? this.deletedAt,
      );

  factory TodoModel.fromJson(Map<String, dynamic> json) => TodoModel(
        id: json['id'] as int,
        title: json['title'] as String,
        completed: json['completed'] as bool,
        isSynced: true,
        pendingAction: 'none',
        createdAt: json['createdAt'] != null 
            ? DateTime.parse(json['createdAt'] as String) 
            : null,
        updatedAt: json['updatedAt'] != null 
            ? DateTime.parse(json['updatedAt'] as String) 
            : null,
        deletedAt: json['deletedAt'] != null 
            ? DateTime.parse(json['deletedAt'] as String) 
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'completed': completed,
        'userId': 1,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'deletedAt': deletedAt?.toIso8601String(),
      };

  @override
  String get key => localId ?? id.toString();

  @override
  String toString() =>
      'TodoModel(id: $id, title: $title, completed: $completed, isSynced: $isSynced, pendingAction: $pendingAction, createdAt: $createdAt, updatedAt: $updatedAt)';
}
