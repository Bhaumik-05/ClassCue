import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../controllers/assignment_controller.dart';
import '../models/assignment_model.dart';
import 'assignments_screen.dart';
import 'timetable_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AssignmentController _assignmentController =
  AssignmentController();

  late final Stream<List<AssignmentModel>> _assignmentsStream;

  @override
  void initState() {
    super.initState();
    _assignmentsStream = _assignmentController.watchAssignments();
  }

  void _openAssignments() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AssignmentsScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.userChanges(),
      builder: (context, userSnapshot) {
        final user = userSnapshot.data;

        final userName = user?.displayName?.trim().isNotEmpty == true
            ? user!.displayName!.trim()
            : 'Student';

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
                icon: const Icon(
                  Icons.notifications_none_rounded,
                ),
                onPressed: () {},
              ),

              IconButton(
                icon: const Icon(Icons.logout_rounded),
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                },
              ),
            ],
          ),

          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(24),

              children: [
                Text(
                  'Hello, $userName 👋',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  'Here is what is happening today.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 24),

                // Today's overview
                Container(
                  padding: const EdgeInsets.all(20),

                  decoration: BoxDecoration(
                    color: scheme.primaryContainer,
                    borderRadius: BorderRadius.circular(24),
                  ),

                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 48,
                        color: scheme.onPrimaryContainer,
                      ),

                      const SizedBox(width: 16),

                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,

                          children: [
                            Text(
                              'Today\'s Classes',
                              style: theme
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color:
                                scheme.onPrimaryContainer,
                              ),
                            ),

                            const SizedBox(height: 4),

                            Text(
                              '3 classes scheduled today',
                              style: theme
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                color:
                                scheme.onPrimaryContainer,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 18,
                        color: scheme.onPrimaryContainer,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                Text(
                  'Quick Actions',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _QuickAction(
                        icon: Icons.calendar_month_rounded,
                        label: 'Timetable',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                              const TimetableScreen(),
                            ),
                          );
                        },
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

                    const SizedBox(width: 12),

                    Expanded(
                      child: _QuickAction(
                        icon: Icons.add_alert_rounded,
                        label: 'Reminders',
                        onTap: () {},
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,

                  children: [
                    Text(
                      'Upcoming Deadlines',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    TextButton(
                      onPressed: _openAssignments,
                      child: const Text('View all'),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                _buildUpcoming(context),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Top 7 pending deadlines, soonest first.
  Widget _buildUpcoming(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return StreamBuilder<List<AssignmentModel>>(
      stream: _assignmentsStream,

      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text(
            'Could not load deadlines.',
            style: TextStyle(
              color: scheme.error,
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final top = _assignmentController
            .pending(snapshot.data!)
            .take(7)
            .toList();

        if (top.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),

            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
            ),

            child: Column(
              children: [
                Icon(
                  Icons.task_alt_rounded,
                  size: 36,
                  color: scheme.primary,
                ),

                const SizedBox(height: 10),

                Text(
                  'No pending deadlines',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            for (final a in top)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),

                child: _UpcomingCard(
                  assignment: a,
                  onTap: _openAssignments,
                ),
              ),
          ],
        );
      },
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
        height: 110,

        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),

        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,

          children: [
            Icon(
              icon,
              size: 30,
              color: scheme.primary,
            ),

            const SizedBox(height: 10),

            Text(
              label,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingCard extends StatelessWidget {
  final AssignmentModel assignment;
  final VoidCallback onTap;

  const _UpcomingCard({
    required this.assignment,
    required this.onTap,
  });

  static const _weekdays = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  String _dateLabel(DateTime d) {
    final h = d.hour % 12 == 0
        ? 12
        : d.hour % 12;

    final m = d.minute.toString().padLeft(2, '0');

    final p = d.hour >= 12
        ? 'PM'
        : 'AM';

    return '${_weekdays[d.weekday - 1]}, '
        '${d.day} ${_months[d.month - 1]} '
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
        padding: const EdgeInsets.all(16),

        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),

          border: accent != null
              ? Border.all(
            color: accent,
            width: 1.5,
          )
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
                crossAxisAlignment:
                CrossAxisAlignment.start,

                children: [
                  Text(
                    a.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,

                    style: theme.textTheme.titleSmall
                        ?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    '${a.subject} • '
                        '${_dateLabel(a.deadline)}',

                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,

                    style: theme.textTheme.bodySmall
                        ?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    a.remainingLabel,

                    style: theme.textTheme.bodySmall
                        ?.copyWith(
                      color: accent ?? scheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.chevron_right_rounded,
            ),
          ],
        ),
      ),
    );
  }
}