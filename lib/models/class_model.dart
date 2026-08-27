// class_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
class ClassModel {
  final String id;
  final String subjectName;
  final String startTime; // "HH:mm"
  final String endTime;   // "HH:mm"
  final String dayOfWeek; // "MONDAY", etc.
  final DateTime createdAt;
  final DateTime updatedAt;

  ClassModel({
    required this.id,
    required this.subjectName,
    required this.startTime,
    required this.endTime,
    required this.dayOfWeek,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ClassModel.fromMap(Map<String, dynamic> map, String id) {
    return ClassModel(
      id: id,
      subjectName: map['subject_name'] ?? '',
      startTime: map['start_time'] ?? '',
      endTime: map['end_time'] ?? '',
      dayOfWeek: map['day_of_week'] ?? '',
      createdAt: (map['created_at'] as Timestamp).toDate(),
      updatedAt: (map['updated_at'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subject_name': subjectName,
      'start_time': startTime,
      'end_time': endTime,
      'day_of_week': dayOfWeek,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}