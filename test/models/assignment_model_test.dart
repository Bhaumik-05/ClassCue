import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_project/models/assignment_model.dart';

AssignmentModel make(Duration fromNow, {bool completed = false}) {
  final now = DateTime.now();
  return AssignmentModel(
    id: 'a1',
    title: 'Essay',
    subject: 'English',
    deadline: now.add(fromNow),
    isCompleted: completed,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('deadline flags (FR4.7 / FR4.8)', () {
    test('overdue pending assignment', () {
      final a = make(const Duration(hours: -2));
      expect(a.isOverdue, isTrue);
      expect(a.isUrgent, isFalse);
      expect(a.isDueSoon, isFalse);
    });

    test('due in 12 hours is urgent and due soon', () {
      final a = make(const Duration(hours: 12));
      expect(a.isUrgent, isTrue);
      expect(a.isDueSoon, isTrue);
      expect(a.isOverdue, isFalse);
    });

    test('due in 25 hours is due soon but not urgent', () {
      final a = make(const Duration(hours: 25));
      expect(a.isUrgent, isFalse);
      expect(a.isDueSoon, isTrue);
    });

    test('due in 6 days is due soon, in 8 days is not', () {
      expect(make(const Duration(days: 6)).isDueSoon, isTrue);
      expect(make(const Duration(days: 8)).isDueSoon, isFalse);
    });

    test('completed assignments are never flagged', () {
      final a = make(const Duration(hours: -5), completed: true);
      expect(a.isOverdue, isFalse);
      expect(make(const Duration(hours: 3), completed: true).isUrgent, isFalse);
      expect(make(const Duration(days: 2), completed: true).isDueSoon, isFalse);
    });
  });

  group('remainingLabel', () {
    test('days and hours', () {
      final a = make(const Duration(days: 2, hours: 3, minutes: 30));
      expect(a.remainingLabel, 'Due in 2d 3h');
    });

    test('hours and minutes', () {
      final a = make(const Duration(hours: 5, minutes: 30, seconds: 30));
      expect(a.remainingLabel, 'Due in 5h 30m');
    });

    test('minutes only', () {
      final a = make(const Duration(minutes: 10, seconds: 30));
      expect(a.remainingLabel, 'Due in 10m');
    });

    test('under one minute shows 1m', () {
      expect(make(const Duration(seconds: 20)).remainingLabel, 'Due in 1m');
    });

    test('overdue label', () {
      final a = make(const Duration(hours: -3, seconds: -30));
      expect(a.remainingLabel, startsWith('Overdue by 3h'));
    });
  });

  group('serialization', () {
    test('toMap uses Firestore field names and Timestamps', () {
      final a = make(const Duration(days: 1));
      final map = a.toMap();
      expect(map['title'], 'Essay');
      expect(map['subject'], 'English');
      expect(map['is_completed'], false);
      expect(map['deadline'], isA<Timestamp>());
    });

    test('fromMap round-trips', () {
      final a = make(const Duration(days: 1));
      final b = AssignmentModel.fromMap(a.toMap(), 'a1');
      expect(b.title, a.title);
      expect(b.subject, a.subject);
      expect(b.isCompleted, a.isCompleted);
      expect(
        b.deadline.millisecondsSinceEpoch,
        a.deadline.millisecondsSinceEpoch,
      );
    });

    test('fromMap applies defaults for missing fields', () {
      final b = AssignmentModel.fromMap({}, 'x');
      expect(b.id, 'x');
      expect(b.title, '');
      expect(b.subject, '');
      expect(b.isCompleted, false);
    });
  });
}