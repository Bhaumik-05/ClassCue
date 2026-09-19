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
      deadline: (map['deadline'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isCompleted: map['is_completed'] ?? false,
      createdAt: (map['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'subject': subject,
      'deadline': Timestamp.fromDate(deadline),
      'is_completed': isCompleted,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  // ---------- Deadline helpers (FR4.7 / FR4.8) ----------

  Duration get timeRemaining => deadline.difference(DateTime.now());

  bool get isOverdue => !isCompleted && timeRemaining.isNegative;

  /// Pending, not overdue, and 24 hours or less remaining (FR4.8).
  bool get isUrgent =>
      !isCompleted &&
          !timeRemaining.isNegative &&
          timeRemaining <= const Duration(hours: 24);

  /// Pending, not overdue, and less than 7 days remaining (FR4.7).
  bool get isDueSoon =>
      !isCompleted &&
          !timeRemaining.isNegative &&
          timeRemaining < const Duration(days: 7);

  String get remainingLabel {
    final r = timeRemaining;
    final abs = r.abs();
    final String span;
    if (abs.inDays > 0) {
      span = '${abs.inDays}d ${abs.inHours % 24}h';
    } else if (abs.inHours > 0) {
      span = '${abs.inHours}h ${abs.inMinutes % 60}m';
    } else {
      span = '${abs.inMinutes < 1 ? 1 : abs.inMinutes}m';
    }
    return r.isNegative ? 'Overdue by $span' : 'Due in $span';
  }
}