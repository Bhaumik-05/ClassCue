import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/assignment_model.dart';
import 'notification_service.dart';

class AssignmentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final NotificationService _notificationService =
  NotificationService();

  String get _uid {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('No authenticated user');
    }

    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _ref {
    return _db
        .collection('users')
        .doc(_uid)
        .collection('assignments');
  }

  // ============================================================
  // WATCH ASSIGNMENTS
  // ============================================================

  Stream<List<AssignmentModel>> watchAssignments() {
    return _ref.orderBy('deadline').snapshots().map(
          (snap) => snap.docs
          .map(
            (d) => AssignmentModel.fromMap(
          d.data(),
          d.id,
        ),
      )
          .toList(),
    );
  }

  // ============================================================
  // GET ASSIGNMENTS
  // ============================================================

  Future<List<AssignmentModel>> getAssignments() async {
    final snap = await _ref.orderBy('deadline').get();

    return snap.docs
        .map(
          (d) => AssignmentModel.fromMap(
        d.data(),
        d.id,
      ),
    )
        .toList();
  }

  // ============================================================
  // ADD ASSIGNMENT
  // ============================================================

  Future<String> addAssignment({
    required String title,
    required String subject,
    required DateTime deadline,
  }) async {
    final now = FieldValue.serverTimestamp();

    final doc = await _ref.add({
      'title': title,
      'subject': subject,
      'deadline': Timestamp.fromDate(deadline),
      'is_completed': false,
      'created_at': now,
      'updated_at': now,
    });

    // Schedule local deadline reminder.
    await _notificationService.scheduleAssignmentReminder(
      assignmentId: doc.id,
      title: title,
      subject: subject,
      deadline: deadline,
    );

    return doc.id;
  }

  // ============================================================
  // UPDATE ASSIGNMENT
  // ============================================================

  Future<void> updateAssignment({
    required String id,
    required String title,
    required String subject,
    required DateTime deadline,
  }) async {
    await _ref.doc(id).update({
      'title': title,
      'subject': subject,
      'deadline': Timestamp.fromDate(deadline),
      'updated_at': FieldValue.serverTimestamp(),
    });

    // Cancel old reminder and create a new one.
    await _notificationService.scheduleAssignmentReminder(
      assignmentId: id,
      title: title,
      subject: subject,
      deadline: deadline,
    );
  }

  // ============================================================
  // COMPLETE / UNCOMPLETE ASSIGNMENT
  // ============================================================

  Future<void> setCompleted(
      String id,
      bool isCompleted,
      ) async {
    await _ref.doc(id).update({
      'is_completed': isCompleted,
      'updated_at': FieldValue.serverTimestamp(),
    });

    if (isCompleted) {
      // Assignment completed → no reminder needed.
      await _notificationService.cancelAssignmentReminder(id);

      print(
        'Assignment completed. Reminder cancelled.',
      );
    } else {
      // Assignment marked incomplete again.
      // Fetch it and schedule its reminder again.

      final doc = await _ref.doc(id).get();

      if (!doc.exists) {
        return;
      }

      final assignment = AssignmentModel.fromMap(
        doc.data()!,
        doc.id,
      );

      await _notificationService.scheduleAssignmentReminder(
        assignmentId: assignment.id,
        title: assignment.title,
        subject: assignment.subject,
        deadline: assignment.deadline,
      );

      print(
        'Assignment marked incomplete. Reminder scheduled again.',
      );
    }
  }

  // ============================================================
  // DELETE ASSIGNMENT
  // ============================================================

  Future<void> deleteAssignment(String id) async {
    // Cancel notification first.
    await _notificationService.cancelAssignmentReminder(id);

    // Delete Firestore document.
    await _ref.doc(id).delete();

    print(
      'Assignment deleted and reminder cancelled.',
    );
  }

  /// Re-creates deadline reminders for pending assignments (after login /
  /// reinstall). Does not pop an immediate alert for ones already inside 24h.
  Future<void> rescheduleReminders() async {
    final all = await getAssignments();
    for (final a in all.where((a) => !a.isCompleted)) {
      await _notificationService.scheduleAssignmentReminder(
        assignmentId: a.id,
        title: a.title,
        subject: a.subject,
        deadline: a.deadline,
        notifyIfDue: false,
      );
    }
  }
}
