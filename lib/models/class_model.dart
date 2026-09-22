// class_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum ClassType {
  lecture,
  lab;

  static ClassType fromValue(String? value) {
    return value == 'LAB' ? ClassType.lab : ClassType.lecture;
  }

  String get value => this == ClassType.lab ? 'LAB' : 'LECTURE';

  String get label => this == ClassType.lab ? 'Lab / Practical' : 'Lecture';
}

class ClassModel {
  final String id;
  final String subjectName;
  final String facultyName;
  final ClassType classType;
  final String startTime; // "HH:mm"
  final String endTime;   // "HH:mm"
  final String dayOfWeek; // "MONDAY", etc.
  final DateTime createdAt;
  final DateTime updatedAt;

  ClassModel({
    required this.id,
    required this.subjectName,
    this.facultyName = '',
    this.classType = ClassType.lecture,
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
      facultyName: map['faculty_name'] ?? '',
      classType: ClassType.fromValue(map['class_type'] as String?),
      startTime: map['start_time'] ?? '',
      endTime: map['end_time'] ?? '',
      dayOfWeek: map['day_of_week'] ?? '',
      // created_at/updated_at are null on the locally-cached snapshot
      // that fires before FieldValue.serverTimestamp() is acknowledged
      // by the server. Fall back to now() instead of crashing the cast.
      createdAt: (map['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subject_name': subjectName,
      'faculty_name': facultyName,
      'class_type': classType.value,
      'start_time': startTime,
      'end_time': endTime,
      'day_of_week': dayOfWeek,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
