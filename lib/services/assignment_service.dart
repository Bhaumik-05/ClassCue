import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/assignment_model.dart';

class AssignmentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String get _uid {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');
    return user.uid;
  }

  // users/{uid}/assignments -> only the signed-in user's data (FR4.9)
  CollectionReference<Map<String, dynamic>> get _ref {
    return _db.collection('users').doc(_uid).collection('assignments');
  }

  /// All assignments ordered by deadline (ascending).
  /// Split into pending/completed on the client (no composite index needed).
  Stream<List<AssignmentModel>> watchAssignments() {
    return _ref.orderBy('deadline').snapshots().map(
          (snap) => snap.docs
          .map((d) => AssignmentModel.fromMap(d.data(), d.id))
          .toList(),
    );
  }

  Future<List<AssignmentModel>> getAssignments() async {
    final snap = await _ref.orderBy('deadline').get();
    return snap.docs
        .map((d) => AssignmentModel.fromMap(d.data(), d.id))
        .toList();
  }

  /// Returns the new document id (needed later to schedule notifications).
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
    return doc.id;
  }

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
  }

  Future<void> setCompleted(String id, bool isCompleted) async {
    await _ref.doc(id).update({
      'is_completed': isCompleted,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteAssignment(String id) async {
    await _ref.doc(id).delete();
  }
}