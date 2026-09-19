import '../models/assignment_model.dart';
import '../services/assignment_service.dart';

class AssignmentController {
  final AssignmentService _service = AssignmentService();

  String? errorMessage;

  Stream<List<AssignmentModel>> watchAssignments() =>
      _service.watchAssignments();

  /// Pending: ascending by deadline (FR4.6).
  List<AssignmentModel> pending(List<AssignmentModel> all) =>
      all.where((a) => !a.isCompleted).toList()
        ..sort((a, b) => a.deadline.compareTo(b.deadline));

  /// Completed: most recent deadline first.
  List<AssignmentModel> completed(List<AssignmentModel> all) =>
      all.where((a) => a.isCompleted).toList()
        ..sort((a, b) => b.deadline.compareTo(a.deadline));

  String? _validate(String title, String subject, DateTime? deadline) {
    if (title.trim().isEmpty) return 'Assignment title is required.';
    if (subject.trim().isEmpty) return 'Subject is required.';
    if (deadline == null) return 'Please select a deadline date and time.';
    return null;
  }

  Future<bool> addAssignment({
    required String title,
    required String subject,
    required DateTime? deadline,
  }) async {
    errorMessage = _validate(title, subject, deadline);
    if (errorMessage != null) return false;

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
      return true;
    } catch (_) {
      errorMessage = 'Could not add assignment. Please try again.';
      return false;
    }
  }

  Future<bool> updateAssignment({
    required String id,
    required String title,
    required String subject,
    required DateTime? deadline,
  }) async {
    errorMessage = _validate(title, subject, deadline);
    if (errorMessage != null) return false;

    try {
      await _service.updateAssignment(
        id: id,
        title: title.trim(),
        subject: subject.trim(),
        deadline: deadline!,
      );
      return true;
    } catch (_) {
      errorMessage = 'Could not update assignment. Please try again.';
      return false;
    }
  }

  Future<bool> setCompleted(String id, bool value) async {
    try {
      errorMessage = null;
      await _service.setCompleted(id, value);
      return true;
    } catch (_) {
      errorMessage = 'Could not update assignment status.';
      return false;
    }
  }

  Future<bool> deleteAssignment(String id) async {
    try {
      errorMessage = null;
      await _service.deleteAssignment(id);
      return true;
    } catch (_) {
      errorMessage = 'Could not delete assignment. Please try again.';
      return false;
    }
  }
}