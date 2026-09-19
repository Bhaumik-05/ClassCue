import '../models/class_model.dart';
import '../services/class_service.dart';

class ClassController {
  /// "HH:mm" strings: true only if end is later than start on the same day.
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

  final ClassService _classService;

  ClassController({ClassService? classService})
      : _classService = classService ?? ClassService();

  String? errorMessage;

  // =========================
  // WATCH CLASSES (for a given day, live)
  // =========================

  Stream<List<ClassModel>> watchClasses({String? dayOfWeek}) {
    return _classService.watchClasses(dayOfWeek: dayOfWeek);
  }

  // =========================
  // GET CLASSES (one-off fetch)
  // =========================

  Future<List<ClassModel>> getClasses({String? dayOfWeek}) async {
    try {
      errorMessage = null;
      return await _classService.getClasses(dayOfWeek: dayOfWeek);
    } catch (e) {
      errorMessage = 'Could not load classes. Please try again.';
      return [];
    }
  }

  // =========================
  // ADD CLASS
  // =========================

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

      await _classService.addClass(
        subjectName: subjectName.trim(),
        startTime: startTime,
        endTime: endTime,
        dayOfWeek: dayOfWeek,
      );

      return true;
    } catch (e) {
      errorMessage = 'Could not add class. Please try again.';
      // print('addClass error: $e');   // TEMP
      return false;
    }
  }

  // =========================
  // UPDATE CLASS
  // =========================

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

      await _classService.updateClass(
        id: id,
        subjectName: subjectName.trim(),
        startTime: startTime,
        endTime: endTime,
        dayOfWeek: dayOfWeek,
      );

      return true;
    } catch (e) {
      errorMessage = 'Could not update class. Please try again.';
      return false;
    }
  }

  // =========================
  // DELETE CLASS
  // =========================

  Future<bool> deleteClass(String id) async {
    try {
      errorMessage = null;
      await _classService.deleteClass(id);
      return true;
    } catch (e) {
      errorMessage = 'Could not delete class. Please try again.';
      return false;
    }
  }
}