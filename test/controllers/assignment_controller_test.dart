import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_project/controllers/assignment_controller.dart';
import 'package:flutter_project/models/assignment_model.dart';

import '../helpers/fakes.dart';

AssignmentModel item(String id, Duration fromNow, {bool done = false}) {
  final now = DateTime.now();
  return AssignmentModel(
    id: id,
    title: id,
    subject: 'S',
    deadline: now.add(fromNow),
    isCompleted: done,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late FakeAssignmentService service;
  late AssignmentController controller;
  final future = DateTime.now().add(const Duration(days: 2));

  setUp(() {
    service = FakeAssignmentService();
    controller = AssignmentController(service: service);
  });

  group('addAssignment (FR4.1, FR4.2)', () {
    test('rejects empty title', () async {
      final ok = await controller.addAssignment(
          title: '  ', subject: 'Maths', deadline: future);
      expect(ok, isFalse);
      expect(controller.errorMessage, 'Assignment title is required.');
      expect(service.addCalls, 0);
    });

    test('rejects empty subject', () async {
      final ok = await controller.addAssignment(
          title: 'HW', subject: '', deadline: future);
      expect(ok, isFalse);
      expect(controller.errorMessage, 'Subject is required.');
    });

    test('rejects missing deadline', () async {
      final ok = await controller.addAssignment(
          title: 'HW', subject: 'Maths', deadline: null);
      expect(ok, isFalse);
      expect(controller.errorMessage,
          'Please select a deadline date and time.');
    });

    test('rejects deadline in the past', () async {
      final ok = await controller.addAssignment(
        title: 'HW',
        subject: 'Maths',
        deadline: DateTime.now().subtract(const Duration(hours: 1)),
      );
      expect(ok, isFalse);
      expect(controller.errorMessage, 'Deadline must be in the future.');
      expect(service.addCalls, 0);
    });

    test('saves valid input with trimmed text', () async {
      final ok = await controller.addAssignment(
          title: '  HW 1 ', subject: ' Maths ', deadline: future);
      expect(ok, isTrue);
      expect(service.addCalls, 1);
      expect(service.lastTitle, 'HW 1');
      expect(service.lastSubject, 'Maths');
      expect(service.lastDeadline, future);
    });

    test('reports a friendly error when the service fails', () async {
      service.fail = true;
      final ok = await controller.addAssignment(
          title: 'HW', subject: 'Maths', deadline: future);
      expect(ok, isFalse);
      expect(controller.errorMessage,
          'Could not add assignment. Please try again.');
    });
  });

  group('updateAssignment (FR4.3)', () {
    test('validates required fields', () async {
      final ok = await controller.updateAssignment(
          id: 'a', title: '', subject: 'S', deadline: future);
      expect(ok, isFalse);
      expect(service.updateCalls, 0);
    });

    test('rejects a deadline in the past when editing', () async {
      final ok = await controller.updateAssignment(
        id: 'a',
        title: 'HW',
        subject: 'S',
        deadline: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(ok, isFalse);
      expect(controller.errorMessage, 'Deadline must be in the future.');
      expect(service.updateCalls, 0);
    });

    test('service failure gives error message', () async {
      service.fail = true;
      final ok = await controller.updateAssignment(
          id: 'a', title: 'HW', subject: 'S', deadline: future);
      expect(ok, isFalse);
      expect(controller.errorMessage,
          'Could not update assignment. Please try again.');
    });
  });

  group('complete / delete (FR4.4)', () {
    test('setCompleted passes the value through', () async {
      expect(await controller.setCompleted('a', true), isTrue);
      expect(service.lastCompleted, isTrue);
    });

    test('setCompleted failure', () async {
      service.fail = true;
      expect(await controller.setCompleted('a', true), isFalse);
      expect(controller.errorMessage, 'Could not update assignment status.');
    });

    test('delete success and failure', () async {
      expect(await controller.deleteAssignment('a'), isTrue);
      expect(service.deleteCalls, 1);

      service.fail = true;
      expect(await controller.deleteAssignment('a'), isFalse);
      expect(controller.errorMessage,
          'Could not delete assignment. Please try again.');
    });
  });

  group('sorting (FR4.5, FR4.6)', () {
    final all = [
      item('late', const Duration(days: 5)),
      item('soon', const Duration(days: 1)),
      item('done-old', const Duration(days: -3), done: true),
      item('done-new', const Duration(days: -1), done: true),
      item('mid', const Duration(days: 3)),
    ];

    test('pending excludes completed and is soonest first', () {
      final ids = controller.pending(all).map((a) => a.id).toList();
      expect(ids, ['soon', 'mid', 'late']);
    });

    test('completed excludes pending, most recent deadline first', () {
      final ids = controller.completed(all).map((a) => a.id).toList();
      expect(ids, ['done-new', 'done-old']);
    });

    test('overdue pending items come first', () {
      final list = [
        item('future', const Duration(days: 1)),
        item('overdue', const Duration(days: -1)),
      ];
      expect(controller.pending(list).first.id, 'overdue');
    });
  });
}