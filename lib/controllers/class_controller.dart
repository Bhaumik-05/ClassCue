import '../models/class_model.dart';
import '../services/class_service.dart';
import '../services/notification_service.dart';

class ClassController {
  final ClassService _classService;
  final NotificationService _notificationService;

  ClassController({
    ClassService? classService,
    NotificationService? notificationService,
  })  : _classService = classService ?? ClassService(),
        _notificationService =
            notificationService ?? NotificationService();

  String? errorMessage;

  // ============================================================
  // VALIDATE TIME
  // ============================================================

  bool _endAfterStart(String start, String end) {
    int toMinutes(String t) {
      final p = t.split(':');

      return int.parse(p[0]) * 60 + int.parse(p[1]);
    }

    try {
      return toMinutes(end) > toMinutes(start);
    } catch (_) {
      return false;
    }
  }

  // ============================================================
  // WATCH CLASSES
  // ============================================================

  Stream<List<ClassModel>> watchClasses({
    String? dayOfWeek,
  }) {
    return _classService.watchClasses(
      dayOfWeek: dayOfWeek,
    );
  }

  // ============================================================
  // GET CLASSES
  // ============================================================

  Future<List<ClassModel>> getClasses({
    String? dayOfWeek,
  }) async {
    try {
      errorMessage = null;

      return await _classService.getClasses(
        dayOfWeek: dayOfWeek,
      );
    } catch (e) {
      errorMessage =
      'Could not load classes. Please try again.';

      return [];
    }
  }

  // ============================================================
  // ADD CLASS
  // ============================================================

  Future<bool> addClass({
    required String subjectName,
    required String startTime,
    required String endTime,
    required String dayOfWeek,
  }) async {
    if (subjectName.trim().isEmpty) {
      errorMessage = 'Subject name is required.';
      return false;
    }

    if (!_endAfterStart(startTime, endTime)) {
      errorMessage = 'End time must be after start time.';
      return false;
    }

    try {
      errorMessage = null;

      // Add class to Firestore.
      final classId = await _classService.addClass(
        subjectName: subjectName.trim(),
        startTime: startTime,
        endTime: endTime,
        dayOfWeek: dayOfWeek,
      );

      // Schedule notification only after Firestore succeeds.
      await _notificationService.scheduleClassReminder(
        classId: classId,
        subjectName: subjectName.trim(),
        startTime: startTime,
        dayOfWeek: dayOfWeek,
      );

      return true;
    } catch (e) {
      print('ERROR adding class: $e');

      errorMessage =
      'Could not add class. Please try again.';

      return false;
    }
  }

  // ============================================================
  // UPDATE CLASS
  // ============================================================

  Future<bool> updateClass({
    required String id,
    required String subjectName,
    required String startTime,
    required String endTime,
    required String dayOfWeek,
  }) async {
    if (subjectName.trim().isEmpty) {
      errorMessage = 'Subject name is required.';
      return false;
    }

    if (!_endAfterStart(startTime, endTime)) {
      errorMessage = 'End time must be after start time.';
      return false;
    }

    try {
      errorMessage = null;

      // Update Firestore.
      await _classService.updateClass(
        id: id,
        subjectName: subjectName.trim(),
        startTime: startTime,
        endTime: endTime,
        dayOfWeek: dayOfWeek,
      );

      // Cancel old reminder and schedule new one.
      await _notificationService.cancelClassReminder(id);

      await _notificationService.scheduleClassReminder(
        classId: id,
        subjectName: subjectName.trim(),
        startTime: startTime,
        dayOfWeek: dayOfWeek,
      );

      return true;
    } catch (e) {
      print('ERROR updating class: $e');

      errorMessage =
      'Could not update class. Please try again.';

      return false;
    }
  }

  // ============================================================
  // DELETE CLASS
  // ============================================================

  Future<bool> deleteClass(String id) async {
    try {
      errorMessage = null;

      // Delete from Firestore.
      await _classService.deleteClass(id);

      // Cancel scheduled notification.
      await _notificationService.cancelClassReminder(id);

      return true;
    } catch (e) {
      print('ERROR deleting class: $e');

      errorMessage =
      'Could not delete class. Please try again.';

      return false;
    }
  }
}