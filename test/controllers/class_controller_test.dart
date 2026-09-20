import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_project/controllers/class_controller.dart';

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
}