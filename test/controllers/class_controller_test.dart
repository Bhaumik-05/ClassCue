import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_project/controllers/class_controller.dart';
import 'package:flutter_project/models/class_model.dart';

import '../helpers/fakes.dart';

void main() {
  late FakeClassService service;
  late FakeNotificationService notificationService;
  late ClassController controller;

  setUp(() {
    service = FakeClassService();
    notificationService = FakeNotificationService();

    controller = ClassController(
      classService: service,
      notificationService: notificationService,
    );
  });

  Future<bool> add({
    String subject = 'Maths',
    String start = '09:00',
    String end = '10:00',
  }) =>
      controller.addClass(
        subjectName: subject,
        startTime: start,
        endTime: end,
        dayOfWeek: 'MONDAY',
      );

  group('addClass (FR3.2, FR3.4)', () {
    test('saves a valid class with trimmed subject', () async {
      expect(await add(subject: '  Maths  '), isTrue);
      expect(service.addCalls, 1);
      expect(service.lastSubject, 'Maths');
      expect(service.lastStart, '09:00');
      expect(service.lastEnd, '10:00');
      expect(service.lastDay, 'MONDAY');
    });

    test('rejects empty subject', () async {
      expect(await add(subject: '   '), isFalse);
      expect(controller.errorMessage, 'Subject name is required.');
      expect(service.addCalls, 0);
    });

    test('rejects end time before start time (12:00 -> 11:00)', () async {
      expect(await add(start: '12:00', end: '11:00'), isFalse);
      expect(controller.errorMessage, 'End time must be after start time.');
      expect(service.addCalls, 0);
    });

    test('rejects equal start and end time', () async {
      expect(await add(start: '10:00', end: '10:00'), isFalse);
      expect(controller.errorMessage, 'End time must be after start time.');
    });

    test('compares numerically, not as text', () async {
      // "9:00" vs "10:00" would be wrong as strings; HH:mm parsing must win.
      expect(await add(start: '09:30', end: '10:15'), isTrue);
    });

    test('rejects malformed times', () async {
      expect(await add(start: '', end: ''), isFalse);
      expect(controller.errorMessage, 'End time must be after start time.');
    });

    test('service failure gives friendly message', () async {
      service.fail = true;
      expect(await add(), isFalse);
      expect(controller.errorMessage,
          'Could not add class. Please try again.');
    });
  });

  group('updateClass (FR3.3)', () {
    test('saves a valid edit', () async {
      final ok = await controller.updateClass(
        id: 'c1',
        subjectName: 'Physics',
        startTime: '11:00',
        endTime: '12:00',
        dayOfWeek: 'TUESDAY',
      );
      expect(ok, isTrue);
      expect(service.updateCalls, 1);
    });

    test('rejects end before start', () async {
      final ok = await controller.updateClass(
        id: 'c1',
        subjectName: 'Physics',
        startTime: '12:00',
        endTime: '11:00',
        dayOfWeek: 'TUESDAY',
      );
      expect(ok, isFalse);
      expect(service.updateCalls, 0);
    });
  });

  group('deleteClass', () {
    test('success', () async {
      expect(await controller.deleteClass('c1'), isTrue);
      expect(service.deleteCalls, 1);
    });

    test('failure', () async {
      service.fail = true;
      expect(await controller.deleteClass('c1'), isFalse);
      expect(controller.errorMessage,
          'Could not delete class. Please try again.');
    });
  });

  group('class reminders (FR6)', () {
    test('adding a class schedules its reminder with the new id', () async {
      expect(await add(subject: '  Maths '), isTrue);
      expect(notificationService.scheduleCalls, 1);
      expect(notificationService.lastClassId, 'class-id-1');
      expect(notificationService.lastSubject, 'Maths');
      expect(notificationService.lastStart, '09:00');
      expect(notificationService.lastDay, 'MONDAY');
    });

    test('invalid class schedules nothing', () async {
      await add(subject: '');
      await add(start: '12:00', end: '11:00');
      expect(notificationService.scheduleCalls, 0);
    });

    test('failed save schedules nothing', () async {
      service.fail = true;
      await add();
      expect(notificationService.scheduleCalls, 0);
    });

    test('editing cancels the old reminder and schedules the new one',
            () async {
          final ok = await controller.updateClass(
            id: 'c1',
            subjectName: 'Physics',
            startTime: '11:00',
            endTime: '12:00',
            dayOfWeek: 'TUESDAY',
          );
          expect(ok, isTrue);
          expect(notificationService.cancelledIds, ['c1']);
          expect(notificationService.scheduleCalls, 1);
          expect(notificationService.lastClassId, 'c1');
          expect(notificationService.lastDay, 'TUESDAY');
          expect(notificationService.lastStart, '11:00');
        });

    test('invalid edit leaves the existing reminder untouched', () async {
      await controller.updateClass(
        id: 'c1',
        subjectName: 'Physics',
        startTime: '12:00',
        endTime: '11:00',
        dayOfWeek: 'TUESDAY',
      );
      expect(notificationService.cancelCalls, 0);
      expect(notificationService.scheduleCalls, 0);
    });

    test('deleting a class cancels its reminder', () async {
      expect(await controller.deleteClass('c1'), isTrue);
      expect(notificationService.cancelledIds, ['c1']);
    });

    test('failed delete keeps the reminder', () async {
      service.fail = true;
      await controller.deleteClass('c1');
      expect(notificationService.cancelCalls, 0);
    });
  });

  group('rescheduleReminders (after login / reinstall)', () {
    ClassModel cls(String id, String subject, String start, String day) {
      final now = DateTime.now();
      return ClassModel(
        id: id,
        subjectName: subject,
        startTime: start,
        endTime: '23:00',
        dayOfWeek: day,
        createdAt: now,
        updatedAt: now,
      );
    }

    test('schedules a reminder for every saved class', () async {
      service.classes = [
        cls('c1', 'Maths', '09:00', 'MONDAY'),
        cls('c2', 'Physics', '11:00', 'TUESDAY'),
      ];
      await controller.rescheduleReminders();
      expect(notificationService.scheduleCalls, 2);
      expect(notificationService.lastClassId, 'c2');
      expect(notificationService.lastDay, 'TUESDAY');
    });

    test('does nothing when there are no classes', () async {
      await controller.rescheduleReminders();
      expect(notificationService.scheduleCalls, 0);
    });

    test('never throws when loading classes fails', () async {
      service.fail = true;
      await expectLater(controller.rescheduleReminders(), completes);
      expect(notificationService.scheduleCalls, 0);
    });
  });


  group('faculty name and class type (CRUD passthrough)', () {
    test('addClass saves trimmed faculty name and type', () async {
      final ok = await controller.addClass(
        subjectName: 'Maths',
        facultyName: '  Dr. Rao  ',
        classType: ClassType.lab,
        startTime: '09:00',
        endTime: '10:00',
        dayOfWeek: 'MONDAY',
      );
      expect(ok, isTrue);
      expect(service.lastFaculty, 'Dr. Rao');
      expect(service.lastType, ClassType.lab);
    });

    test('updateClass saves trimmed faculty name and type', () async {
      final ok = await controller.updateClass(
        id: 'c1',
        subjectName: 'Physics',
        facultyName: ' Prof. Shah ',
        classType: ClassType.lab,
        startTime: '11:00',
        endTime: '12:00',
        dayOfWeek: 'TUESDAY',
      );
      expect(ok, isTrue);
      expect(service.lastFaculty, 'Prof. Shah');
      expect(service.lastType, ClassType.lab);
    });

    test('facultyName and classType default when omitted', () async {
      await add();
      expect(service.lastFaculty, '');
      expect(service.lastType, ClassType.lecture);
    });
  });

  group('overlapping time slots (inclusive)', () {
    ClassModel existing(String id, String start, String end, {String day = 'MONDAY'}) {
      final now = DateTime.now();
      return ClassModel(
        id: id,
        subjectName: 'Existing',
        startTime: start,
        endTime: end,
        dayOfWeek: day,
        createdAt: now,
        updatedAt: now,
      );
    }

    test('rejects an identical time slot on the same day', () async {
      service.classes = [existing('c1', '10:00', '12:00')];
      final ok = await add(start: '10:00', end: '12:00');
      expect(ok, isFalse);
      expect(controller.errorMessage,
          'This overlaps with another class on that day.');
      expect(service.addCalls, 0);
    });

    test('rejects a slot that partially overlaps (11:00-12:00 inside 10-12)',
            () async {
          service.classes = [existing('c1', '10:00', '12:00')];
          final ok = await add(start: '11:00', end: '12:00');
          expect(ok, isFalse);
          expect(service.addCalls, 0);
        });

    test('rejects a slot that starts earlier but still overlaps', () async {
      service.classes = [existing('c1', '10:00', '12:00')];
      final ok = await add(start: '09:00', end: '11:00');
      expect(ok, isFalse);
    });

    test('allows a slot that starts exactly when the other ends', () async {
      service.classes = [existing('c1', '09:00', '10:00')];
      final ok = await add(start: '10:00', end: '11:00');
      expect(ok, isTrue);
      expect(service.addCalls, 1);
    });

    test('allows the same time slot on a different day', () async {
      service.classes = [existing('c1', '10:00', '12:00', day: 'TUESDAY')];
      final ok = await add(start: '10:00', end: '12:00');
      expect(ok, isTrue);
    });

    test('editing a class ignores its own existing slot', () async {
      service.classes = [existing('c1', '10:00', '12:00')];
      final ok = await controller.updateClass(
        id: 'c1',
        subjectName: 'Maths',
        startTime: '10:30',
        endTime: '12:00',
        dayOfWeek: 'MONDAY',
      );
      expect(ok, isTrue);
      expect(service.updateCalls, 1);
    });

    test('editing into another class\'s slot is still rejected', () async {
      service.classes = [
        existing('c1', '09:00', '10:00'),
        existing('c2', '10:00', '11:00'),
      ];
      final ok = await controller.updateClass(
        id: 'c1',
        subjectName: 'Maths',
        startTime: '09:30',
        endTime: '10:30',
        dayOfWeek: 'MONDAY',
      );
      expect(ok, isFalse);
      expect(service.updateCalls, 0);
    });

    test('a failed conflict lookup blocks the save with a friendly error',
            () async {
          service.fail = true;
          final ok = await add();
          expect(ok, isFalse);
          expect(controller.errorMessage,
              'Could not add class. Please try again.');
        });
  });
}
