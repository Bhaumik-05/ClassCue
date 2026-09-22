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

  int _toMinutes(String t) {
    final p = t.split(':');
    return int.parse(p[0]) * 60 + int.parse(p[1]);
  }

  bool _endAfterStart(String start, String end) {
    try {
      return _toMinutes(end) > _toMinutes(start);
    } catch (_) {
      return false;
    }
  }

  /// True if [aStart, aEnd) overlaps [bStart, bEnd) on the same day.
  /// Back-to-back classes (one ending exactly when the other starts) do
  /// not count as overlapping.
  bool _rangesOverlap(String aStart, String aEnd, String bStart, String bEnd) {
    try {
      final aS = _toMinutes(aStart), aE = _toMinutes(aEnd);
      final bS = _toMinutes(bStart), bE = _toMinutes(bEnd);
      return aS < bE && bS < aE;
    } catch (_) {
      return false;
    }
  }

  /// Checks the given time range against every other class already
  /// scheduled on [dayOfWeek]. [excludeId] is the class being edited, so
  /// it does not conflict with itself.
  Future<bool> _hasConflict({
    required String dayOfWeek,
    required String startTime,
    required String endTime,
    String? excludeId,
  }) async {
    final sameDay = await _classService.getClasses(dayOfWeek: dayOfWeek);
    return sameDay.any((c) =>
    c.id != excludeId &&
        _rangesOverlap(startTime, endTime, c.startTime, c.endTime));
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
    String facultyName = '',
    ClassType classType = ClassType.lecture,
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
      if (await _hasConflict(
        dayOfWeek: dayOfWeek,
        startTime: startTime,
        endTime: endTime,
      )) {
        errorMessage = 'This overlaps with another class on that day.';
        return false;
      }

      errorMessage = null;

      // Add class to Firestore.
      final classId = await _classService.addClass(
        subjectName: subjectName.trim(),
        facultyName: facultyName.trim(),
        classType: classType,
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
    String facultyName = '',
    ClassType classType = ClassType.lecture,
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
      if (await _hasConflict(
        dayOfWeek: dayOfWeek,
        startTime: startTime,
        endTime: endTime,
        excludeId: id,
      )) {
        errorMessage = 'This overlaps with another class on that day.';
        return false;
      }

      errorMessage = null;

      // Update Firestore.
      await _classService.updateClass(
        id: id,
        subjectName: subjectName.trim(),
        facultyName: facultyName.trim(),
        classType: classType,
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

  /// Re-creates every class reminder (after login / reinstall). Never throws.
  Future<void> rescheduleReminders() async {
    try {
      final classes = await _classService.getClasses();
      for (final c in classes) {
        await _notificationService.scheduleClassReminder(
          classId: c.id,
          subjectName: c.subjectName,
          startTime: c.startTime,
          dayOfWeek: c.dayOfWeek,
        );
      }
    } catch (_) {}
  }
}
