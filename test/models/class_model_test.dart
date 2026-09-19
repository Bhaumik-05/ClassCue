import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_project/models/class_model.dart';

void main() {
  test('fromMap reads Firestore field names', () {
    final m = ClassModel.fromMap({
      'subject_name': 'Maths',
      'start_time': '09:00',
      'end_time': '10:00',
      'day_of_week': 'MONDAY',
      'created_at': Timestamp.fromDate(DateTime(2026, 1, 1)),
      'updated_at': Timestamp.fromDate(DateTime(2026, 1, 2)),
    }, 'c1');

    expect(m.id, 'c1');
    expect(m.subjectName, 'Maths');
    expect(m.startTime, '09:00');
    expect(m.endTime, '10:00');
    expect(m.dayOfWeek, 'MONDAY');
    expect(m.createdAt, DateTime(2026, 1, 1));
  });

  test('fromMap applies defaults for missing fields', () {
    final m = ClassModel.fromMap({}, 'c2');
    expect(m.subjectName, '');
    expect(m.startTime, '');
    expect(m.dayOfWeek, '');
  });

  test('toMap writes Firestore field names', () {
    final now = DateTime.now();
    final map = ClassModel(
      id: 'c3',
      subjectName: 'Physics',
      startTime: '11:00',
      endTime: '12:00',
      dayOfWeek: 'FRIDAY',
      createdAt: now,
      updatedAt: now,
    ).toMap();

    expect(map['subject_name'], 'Physics');
    expect(map['start_time'], '11:00');
    expect(map['end_time'], '12:00');
    expect(map['day_of_week'], 'FRIDAY');
  });
}