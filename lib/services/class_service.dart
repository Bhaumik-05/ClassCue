import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/class_model.dart';

class ClassService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String get _uid {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> get _classesRef {
    return _db.collection('users').doc(_uid).collection('classes');
  }

  // =========================
  // GET CLASSES (GET /classes)
  // =========================

  Stream<List<ClassModel>> watchClasses({String? dayOfWeek}) {
    Query<Map<String, dynamic>> query =
    _classesRef.orderBy('start_time');

    if (dayOfWeek != null) {
      query = _classesRef
          .where('day_of_week', isEqualTo: dayOfWeek)
          .orderBy('start_time');
    }

    return query.snapshots().map(
          (snapshot) => snapshot.docs
          .map((doc) => ClassModel.fromMap(doc.data(), doc.id))
          .toList(),
    );
  }

  Future<List<ClassModel>> getClasses({String? dayOfWeek}) async {
    Query<Map<String, dynamic>> query =
    _classesRef.orderBy('start_time');

    if (dayOfWeek != null) {
      query = _classesRef
          .where('day_of_week', isEqualTo: dayOfWeek)
          .orderBy('start_time');
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => ClassModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  // =========================
  // ADD CLASS (POST /classes)
  // =========================

  Future<void> addClass({
    required String subjectName,
    required String startTime,
    required String endTime,
    required String dayOfWeek,
  }) async {
    final now = FieldValue.serverTimestamp();

    await _classesRef.add({
      'subject_name': subjectName,
      'start_time': startTime,
      'end_time': endTime,
      'day_of_week': dayOfWeek,
      'created_at': now,
      'updated_at': now,
    });
  }

  // =========================
  // UPDATE CLASS (PUT /classes/:id)
  // =========================

  Future<void> updateClass({
    required String id,
    required String subjectName,
    required String startTime,
    required String endTime,
    required String dayOfWeek,
  }) async {
    await _classesRef.doc(id).update({
      'subject_name': subjectName,
      'start_time': startTime,
      'end_time': endTime,
      'day_of_week': dayOfWeek,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  // =========================
  // DELETE CLASS (DELETE /classes/:id)
  // =========================

  Future<void> deleteClass(String id) async {
    await _classesRef.doc(id).delete();
  }
}