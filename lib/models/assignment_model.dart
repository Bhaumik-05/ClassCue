// assignment_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
class AssignmentModel {
  final String id;
  final String title;
  final String subject;
  final DateTime deadline;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  AssignmentModel({
    required this.id,
    required this.title,
    required this.subject,
    required this.deadline,
    required this.isCompleted,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AssignmentModel.fromMap(Map<String, dynamic> map, String id) {
    return AssignmentModel(
      id: id,
      title: map['title'] ?? '',
      subject: map['subject'] ?? '',
      deadline: (map['deadline'] as Timestamp).toDate(),
      isCompleted: map['is_completed'] ?? false,
      createdAt: (map['created_at'] as Timestamp).toDate(),
      updatedAt: (map['updated_at'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subject': subject,
      'deadline': deadline,
      'is_completed': isCompleted,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}