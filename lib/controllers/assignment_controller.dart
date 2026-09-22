import '../models/assignment_model.dart';
import '../services/assignment_service.dart';

class AssignmentController {
  final AssignmentService _service;

  AssignmentController({
    AssignmentService? service,
  }) : _service = service ?? AssignmentService();

  String? errorMessage;

  // ============================================================
  // WATCH ASSIGNMENTS
  // ============================================================

  Stream<List<AssignmentModel>> watchAssignments() =>
      _service.watchAssignments();

  // ============================================================
  // PENDING ASSIGNMENTS
  // ============================================================

  List<AssignmentModel> pending(
      List<AssignmentModel> all,
      ) =>
      all.where((a) => !a.isCompleted).toList()
        ..sort(
              (a, b) => a.deadline.compareTo(b.deadline),
        );

  // ============================================================
  // COMPLETED ASSIGNMENTS
  // ============================================================

  List<AssignmentModel> completed(
      List<AssignmentModel> all,
      ) =>
      all.where((a) => a.isCompleted).toList()
        ..sort(
              (a, b) => b.deadline.compareTo(a.deadline),
        );

  // ============================================================
  // VALIDATION
  // ============================================================

  String? _validate(
      String title,
      String subject,
      DateTime? deadline,
      ) {
    if (title.trim().isEmpty) {
      return 'Assignment title is required.';
    }

    if (subject.trim().isEmpty) {
      return 'Subject is required.';
    }

    if (deadline == null) {
      return 'Please select a deadline date and time.';
    }

    return null;
  }

  // ============================================================
  // ADD ASSIGNMENT
  // ============================================================

  Future<bool> addAssignment({
    required String title,
    required String subject,
    required DateTime? deadline,
  }) async {
    errorMessage = _validate(
      title,
      subject,
      deadline,
    );

    if (errorMessage != null) {
      return false;
    }

    if (!deadline!.isAfter(DateTime.now())) {
      errorMessage = 'Deadline must be in the future.';
      return false;
    }

    try {
      await _service.addAssignment(
        title: title.trim(),
        subject: subject.trim(),
        deadline: deadline,
      );

      errorMessage = null;

      return true;
    } catch (e) {
      print('ERROR adding assignment: $e');

      errorMessage =
      'Could not add assignment. Please try again.';

      return false;
    }
  }

  // ============================================================
  // UPDATE ASSIGNMENT
  // ============================================================

  Future<bool> updateAssignment({
    required String id,
    required String title,
    required String subject,
    required DateTime? deadline,
  }) async {
    errorMessage = _validate(
      title,
      subject,
      deadline,
    );

    if (errorMessage != null) {
      return false;
    }

    if (!deadline!.isAfter(DateTime.now())) {
      errorMessage = 'Deadline must be in the future.';
      return false;
    }

    try {
      await _service.updateAssignment(
        id: id,
        title: title.trim(),
        subject: subject.trim(),
        deadline: deadline,
      );

      errorMessage = null;

      return true;
    } catch (e) {
      print('ERROR updating assignment: $e');

      errorMessage =
      'Could not update assignment. Please try again.';

      return false;
    }
  }

  // ============================================================
  // COMPLETE / UNCOMPLETE
  // ============================================================

  Future<bool> setCompleted(
      String id,
      bool value,
      ) async {
    try {
      errorMessage = null;

      await _service.setCompleted(
        id,
        value,
      );

      return true;
    } catch (e) {
      print('ERROR updating assignment status: $e');

      errorMessage =
      'Could not update assignment status.';

      return false;
    }
  }

  // ============================================================
  // DELETE
  // ============================================================

  Future<bool> deleteAssignment(
      String id,
      ) async {
    try {
      errorMessage = null;

      await _service.deleteAssignment(id);

      return true;
    } catch (e) {
      print('ERROR deleting assignment: $e');

      errorMessage =
      'Could not delete assignment. Please try again.';

      return false;
    }
  }

  /// Re-creates reminders for pending assignments. Never throws.
  Future<void> rescheduleReminders() async {
    try {
      await _service.rescheduleReminders();
    } catch (_) {}
  }
}
