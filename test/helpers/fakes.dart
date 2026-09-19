import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_project/models/assignment_model.dart';
import 'package:flutter_project/services/assignment_service.dart';
import 'package:flutter_project/services/auth_service.dart';
import 'package:flutter_project/services/class_service.dart';

/// `Fake implements X` never runs X's constructor, so no Firebase is needed.

class FakeUserCredential extends Fake implements UserCredential {}

class FakeAuthService extends Fake implements AuthService {
  Object? error; // thrown by every call when set
  int loginCalls = 0;
  int signupCalls = 0;
  int resetCalls = 0;
  String? lastEmail;
  String? lastName;

  @override
  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    loginCalls++;
    lastEmail = email;
    if (error != null) throw error!;
    return FakeUserCredential();
  }

  @override
  Future<UserCredential> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    signupCalls++;
    lastName = name;
    lastEmail = email;
    if (error != null) throw error!;
    return FakeUserCredential();
  }

  @override
  Future<void> resetPassword({required String email}) async {
    resetCalls++;
    lastEmail = email;
    if (error != null) throw error!;
  }
}

class FakeAssignmentService extends Fake implements AssignmentService {
  bool fail = false;
  int addCalls = 0;
  int updateCalls = 0;
  int deleteCalls = 0;
  String? lastTitle;
  String? lastSubject;
  DateTime? lastDeadline;
  bool? lastCompleted;

  @override
  Stream<List<AssignmentModel>> watchAssignments() => Stream.value([]);

  @override
  Future<String> addAssignment({
    required String title,
    required String subject,
    required DateTime deadline,
  }) async {
    addCalls++;
    lastTitle = title;
    lastSubject = subject;
    lastDeadline = deadline;
    if (fail) throw Exception('boom');
    return 'id-1';
  }

  @override
  Future<void> updateAssignment({
    required String id,
    required String title,
    required String subject,
    required DateTime deadline,
  }) async {
    updateCalls++;
    lastTitle = title;
    lastSubject = subject;
    lastDeadline = deadline;
    if (fail) throw Exception('boom');
  }

  @override
  Future<void> setCompleted(String id, bool isCompleted) async {
    lastCompleted = isCompleted;
    if (fail) throw Exception('boom');
  }

  @override
  Future<void> deleteAssignment(String id) async {
    deleteCalls++;
    if (fail) throw Exception('boom');
  }
}

class FakeClassService extends Fake implements ClassService {
  bool fail = false;
  int addCalls = 0;
  int updateCalls = 0;
  int deleteCalls = 0;
  String? lastSubject;
  String? lastStart;
  String? lastEnd;
  String? lastDay;

  @override
  Future<void> addClass({
    required String subjectName,
    required String startTime,
    required String endTime,
    required String dayOfWeek,
  }) async {
    addCalls++;
    lastSubject = subjectName;
    lastStart = startTime;
    lastEnd = endTime;
    lastDay = dayOfWeek;
    if (fail) throw Exception('boom');
  }

  @override
  Future<void> updateClass({
    required String id,
    required String subjectName,
    required String startTime,
    required String endTime,
    required String dayOfWeek,
  }) async {
    updateCalls++;
    lastSubject = subjectName;
    if (fail) throw Exception('boom');
  }

  @override
  Future<void> deleteClass(String id) async {
    deleteCalls++;
    if (fail) throw Exception('boom');
  }
}