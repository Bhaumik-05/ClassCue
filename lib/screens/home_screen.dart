import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../controllers/assignment_controller.dart';
import '../controllers/class_controller.dart';
import '../models/assignment_model.dart';
import '../models/class_model.dart';
import '../widgets/app_animations.dart';
import '../widgets/custom_snackbar.dart';
import 'assignments_screen.dart';
import 'timetable_screen.dart';

// ---------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------
const _dayKeys = [
  'MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY',
  'FRIDAY', 'SATURDAY', 'SUNDAY',
];
const _dayNames = [
  'Monday', 'Tuesday', 'Wednesday', 'Thursday',
  'Friday', 'Saturday', 'Sunday',
];
const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

int _toMinutes(String t) {
  try {
    final p = t.split(':');
    return int.parse(p[0]) * 60 + int.parse(p[1]);
  } catch (_) {
    return 0;
  }
}

String _clock(String t) {
  final m = _toMinutes(t);
  final h = m ~/ 60;
  final mm = (m % 60).toString().padLeft(2, '0');
  final h12 = h % 12 == 0 ? 12 : h % 12;
  return '$h12:$mm ${h >= 12 ? 'PM' : 'AM'}';
}

String _span(int minutes) {
  if (minutes < 1) return 'less than a minute';
  if (minutes < 60) return '$minutes min';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return m == 0 ? '${h}h' : '${h}h ${m}m';
}

// ---------------------------------------------------------------
// Screen
// ---------------------------------------------------------------
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AssignmentController _assignmentController = AssignmentController();
  final ClassController _classController = ClassController();

  late final Stream<List<AssignmentModel>> _assignmentsStream;
  late Stream<List<ClassModel>> _classesStream;
  late String _todayKey;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _assignmentsStream = _assignmentController.watchAssignments();
    _todayKey = _dayKeys[DateTime.now().weekday - 1];
    _classesStream = _classController.watchClasses(dayOfWeek: _todayKey);

    // Keeps "starts in 25 min" / "due in 3h" labels fresh, and rolls the
    // class list over when the day changes.
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      final key = _dayKeys[DateTime.now().weekday - 1];
      setState(() {
        if (key != _todayKey) {
          _todayKey = key;
          _classesStream = _classController.watchClasses(dayOfWeek: key);
        }
      });
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _openAssignments() =>
      Navigator.push(context, AppRoute.push(const AssignmentsScreen()));

  void _openTimetable() =>
      Navigator.push(context, AppRoute.push(const TimetableScreen()));

  Future<void> _complete(AssignmentModel a) async {
    final ok = await _assignmentController.setCompleted(a.id, true);
    if (ok) {
      CustomSnackbar.success(
        title: 'Nice work!',
        message: '"${a.title}" marked as done.',
      );
    } else {
      CustomSnackbar.error(
        title: 'Update failed',
        message: _assignmentController.errorMessage ?? 'Please try again.',
      );
    }
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, userSnapshot) {
        final user = userSnapshot.data;
        final name = user?.displayName?.trim().isNotEmpty == true
            ? user!.displayName!.trim().split(' ').first
            : 'Student';

        final now = DateTime.now();

        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Row(
              children: [
                Container(
                  height: 40,
                  width: 40,
                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.school_rounded,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'ClassCue',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                tooltip: 'Log out',
                icon: const Icon(Icons.logout_rounded),
                onPressed: () async => FirebaseAuth.instance.signOut(),
              ),
            ],
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                  children: [
                    // ---------- Greeting ----------
                    FadeSlideIn(
                      index: 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_dayNames[now.weekday - 1]}, '
                                '${now.day} ${_months[now.month - 1]}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_greeting()}, $name 👋',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ---------- Assignments (highest priority) ----------
                    FadeSlideIn(index: 1, child: _buildAssignments()),
                    const SizedBox(height: 28),

                    // ---------- Today's classes ----------
                    FadeSlideIn(index: 2, child: _buildClasses()),
                    const SizedBox(height: 28),

                    // ---------- Quick access ----------
                    FadeSlideIn(index: 3, child: _buildQuickAccess()),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------
  // Section header
  // -------------------------------------------------------------
  Widget _sectionHeader(String title, String action, VoidCallback onTap) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        TextButton(onPressed: onTap, child: Text(action)),
      ],
    );
  }

  // -------------------------------------------------------------
  // Assignments
  // -------------------------------------------------------------
  Widget _buildAssignments() {
    return StreamBuilder<List<AssignmentModel>>(
      stream: _assignmentsStream,
      builder: (context, snapshot) {
        final Widget body;

        if (snapshot.hasError) {
          body = const _InfoCard(
            icon: Icons.error_outline_rounded,
            title: 'Could not load deadlines',
          );
        } else if (!snapshot.hasData) {
          body = const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        } else {
          final pending = _assignmentController.pending(snapshot.data!);

          if (pending.isEmpty) {
            body = const _InfoCard(
              icon: Icons.task_alt_rounded,
              title: 'You are all caught up',
              subtitle: 'No pending assignments.',
            );
          } else {
            final overdue = pending.where((a) => a.isOverdue).length;
            final urgent = pending.where((a) => a.isUrgent).length;
            final week = pending.where((a) => a.isDueSoon).length;
            final top = pending.take(7).toList();
            final scheme = Theme.of(context).colorScheme;

            body = Column(
              children: [
                Row(
                  children: [
                    _StatTile(
                      count: overdue,
                      label: 'Overdue',
                      color: scheme.error,
                    ),
                    const SizedBox(width: 10),
                    _StatTile(
                      count: urgent,
                      label: 'Next 24h',
                      color: scheme.error,
                    ),
                    const SizedBox(width: 10),
                    _StatTile(
                      count: week,
                      label: 'This week',
                      color: Colors.amber,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                for (final a in top)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _DeadlineCard(
                      assignment: a,
                      onTap: _openAssignments,
                      onComplete: () => _complete(a),
                    ),
                  ),
                if (pending.length > top.length)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _openAssignments,
                      child: Text('+${pending.length - top.length} more'),
                    ),
                  ),
              ],
            );
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('Assignments due', 'View all', _openAssignments),
            const SizedBox(height: 8),
            body,
          ],
        );
      },
    );
  }

  // -------------------------------------------------------------
  // Today's classes
  // -------------------------------------------------------------
  Widget _buildClasses() {
    return StreamBuilder<List<ClassModel>>(
      stream: _classesStream,
      builder: (context, snapshot) {
        final Widget body;

        if (snapshot.hasError) {
          body = const _InfoCard(
            icon: Icons.error_outline_rounded,
            title: 'Could not load classes',
          );
        } else if (!snapshot.hasData) {
          body = const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        } else {
          final classes = List<ClassModel>.of(snapshot.data!)
            ..sort((a, b) =>
                _toMinutes(a.startTime).compareTo(_toMinutes(b.startTime)));

          if (classes.isEmpty) {
            body = _InfoCard(
              icon: Icons.event_available_rounded,
              title: _todayKey == 'SUNDAY'
                  ? 'No classes on Sunday'
                  : 'No classes today',
              subtitle: 'Enjoy the free time.',
            );
          } else {
            final now = DateTime.now();
            final nowMin = now.hour * 60 + now.minute;

            ClassModel? current;
            ClassModel? next;
            for (final c in classes) {
              final s = _toMinutes(c.startTime);
              final e = _toMinutes(c.endTime);
              if (s <= nowMin && nowMin < e) {
                current ??= c;
              } else if (s > nowMin) {
                next ??= c;
              }
            }

            final hero = current ?? next;

            body = Column(
              children: [
                if (hero != null)
                  _ClassHero(
                    cls: hero,
                    inProgress: current != null,
                    minutes: current != null
                        ? _toMinutes(hero.endTime) - nowMin
                        : _toMinutes(hero.startTime) - nowMin,
                  )
                else
                  const _InfoCard(
                    icon: Icons.check_circle_outline_rounded,
                    title: 'All classes done for today',
                    subtitle: 'Nice work!',
                  ),
                const SizedBox(height: 14),
                for (final c in classes)
                  _ClassRow(
                    cls: c,
                    state: c == current
                        ? _ClassState.current
                        : _toMinutes(c.endTime) <= nowMin
                        ? _ClassState.past
                        : _ClassState.upcoming,
                  ),
              ],
            );
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader("Today's classes", 'Timetable', _openTimetable),
            const SizedBox(height: 8),
            body,
          ],
        );
      },
    );
  }

  // -------------------------------------------------------------
  // Quick access
  // -------------------------------------------------------------
  Widget _buildQuickAccess() {
    return Row(
      children: [
        Expanded(
          child: _QuickAction(
            icon: Icons.calendar_month_rounded,
            label: 'Timetable',
            onTap: _openTimetable,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _QuickAction(
            icon: Icons.assignment_rounded,
            label: 'Assignments',
            onTap: _openAssignments,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------
// Small widgets
// ---------------------------------------------------------------
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const _InfoCard({required this.icon, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: scheme.primary),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final int count;
  final String label;
  final Color color;

  const _StatTile({
    required this.count,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final active = count > 0;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: active ? Border.all(color: color, width: 1.5) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$count',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: active ? color : scheme.onSurfaceVariant,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeadlineCard extends StatelessWidget {
  final AssignmentModel assignment;
  final VoidCallback onTap;
  final VoidCallback onComplete;

  const _DeadlineCard({
    required this.assignment,
    required this.onTap,
    required this.onComplete,
  });

  String _dateLabel(DateTime d) {
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    final p = d.hour >= 12 ? 'PM' : 'AM';
    return '${_weekdays[d.weekday - 1]}, ${d.day} ${_months[d.month - 1]} '
        '• $h:$m $p';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final a = assignment;

    Color? accent;
    if (a.isOverdue || a.isUrgent) {
      accent = scheme.error;
    } else if (a.isDueSoon) {
      accent = Colors.amber;
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 6, 14),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: accent != null
              ? Border.all(color: accent, width: 1.5)
              : null,
        ),
        child: Row(
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.assignment_rounded,
                color: scheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    a.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${a.subject} • ${_dateLabel(a.deadline)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    a.remainingLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: accent ?? scheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Mark as done',
              icon: const Icon(Icons.check_circle_outline_rounded),
              onPressed: onComplete,
            ),
          ],
        ),
      ),
    );
  }
}

class _ClassHero extends StatelessWidget {
  final ClassModel cls;
  final bool inProgress;
  final int minutes;

  const _ClassHero({
    required this.cls,
    required this.inProgress,
    required this.minutes,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: scheme.onPrimaryContainer.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    inProgress ? 'IN PROGRESS' : 'NEXT UP',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  cls.subjectName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${_clock(cls.startTime)} – ${_clock(cls.endTime)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      inProgress
                          ? Icons.hourglass_bottom_rounded
                          : Icons.schedule_rounded,
                      size: 16,
                      color: scheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      inProgress
                          ? 'Ends in ${_span(minutes)}'
                          : 'Starts in ${_span(minutes)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Icon(
            Icons.school_rounded,
            size: 48,
            color: scheme.onPrimaryContainer.withValues(alpha: 0.85),
          ),
        ],
      ),
    );
  }
}

enum _ClassState { past, current, upcoming }

class _ClassRow extends StatelessWidget {
  final ClassModel cls;
  final _ClassState state;

  const _ClassRow({required this.cls, required this.state});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final past = state == _ClassState.past;
    final current = state == _ClassState.current;

    return Opacity(
      opacity: past ? 0.5 : 1,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            SizedBox(
              width: 72,
              child: Text(
                _clock(cls.startTime),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  border: current
                      ? Border.all(color: scheme.primary, width: 1.5)
                      : null,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        cls.subjectName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          decoration:
                          past ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'until ${_clock(cls.endTime)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        height: 96,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: scheme.primary),
            const SizedBox(height: 10),
            Text(label, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}