import 'package:flutter/material.dart';

import '../controllers/assignment_controller.dart';
import '../models/assignment_model.dart';
import '../widgets/custom_snackbar.dart';

// ---------------------------------------------------------------
// Date helpers (no intl dependency)
// ---------------------------------------------------------------
const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

const _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

String _formatDateTime(DateTime d) {
  final hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final minute = d.minute.toString().padLeft(2, '0');
  final period = d.hour >= 12 ? 'PM' : 'AM';
  return '${_weekdays[d.weekday - 1]}, ${d.day} ${_months[d.month - 1]} '
      '${d.year} • $hour12:$minute $period';
}

// ---------------------------------------------------------------
// Screen
// ---------------------------------------------------------------
class AssignmentsScreen extends StatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  State<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

enum _ListView { day, pending, completed }

class _AssignmentsScreenState extends State<AssignmentsScreen> {
  final AssignmentController _controller = AssignmentController();
  late final Stream<List<AssignmentModel>> _stream;

  late DateTime _visibleMonth;
  late DateTime _selectedDay;
  _ListView _view = _ListView.day;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDay = _dateOnly(now);
    _visibleMonth = DateTime(now.year, now.month);
    _stream = _controller.watchAssignments();
  }

  void _changeMonth(int delta) {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + delta);
    });
  }

  void _selectDay(DateTime day) {
    setState(() {
      _selectedDay = day;
      _view = _ListView.day;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
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
                Icons.assignment_rounded,
                color: scheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Assignments',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add assignment'),
      ),
      body: SafeArea(
        child: StreamBuilder<List<AssignmentModel>>(
          stream: _stream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Could not load assignments.\n${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.error),
                  ),
                ),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            return _buildContent(snapshot.data!);
          },
        ),
      ),
    );
  }

  Widget _buildContent(List<AssignmentModel> all) {
    final theme = Theme.of(context);
    final pending = _controller.pending(all);
    final completed = _controller.completed(all);

    // Group by calendar day for the markers
    final byDay = <DateTime, List<AssignmentModel>>{};
    for (final a in all) {
      byDay.putIfAbsent(_dateOnly(a.deadline), () => []).add(a);
    }

    final dayItems = List<AssignmentModel>.from(byDay[_selectedDay] ?? [])
      ..sort((a, b) => a.deadline.compareTo(b.deadline));

    final List<AssignmentModel> items;
    final String emptyTitle;
    final String emptyMessage;
    final IconData emptyIcon;

    switch (_view) {
      case _ListView.day:
        items = dayItems;
        emptyIcon = Icons.event_available_rounded;
        emptyTitle = 'No deadlines on this day';
        emptyMessage = 'Tap "Add assignment" to add one for this date.';
        break;
      case _ListView.pending:
        items = pending;
        emptyIcon = Icons.task_alt_rounded;
        emptyTitle = 'No pending assignments';
        emptyMessage = 'You are all caught up.';
        break;
      case _ListView.completed:
        items = completed;
        emptyIcon = Icons.inbox_rounded;
        emptyTitle = 'Nothing completed yet';
        emptyMessage = 'Assignments you finish will show up here.';
        break;
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: ListView(
          padding: const EdgeInsets.only(bottom: 100),
          children: [
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: _MonthCalendar(
                month: _visibleMonth,
                selected: _selectedDay,
                byDay: byDay,
                onSelect: _selectDay,
                onPrev: () => _changeMonth(-1),
                onNext: () => _changeMonth(1),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<_ListView>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: _ListView.day,
                      label: Text(
                        '${_selectedDay.day} ${_months[_selectedDay.month - 1]}',
                      ),
                    ),
                    ButtonSegment(
                      value: _ListView.pending,
                      label: Text('Pending (${pending.length})'),
                    ),
                    ButtonSegment(
                      value: _ListView.completed,
                      label: Text('Done (${completed.length})'),
                    ),
                  ],
                  selected: {_view},
                  onSelectionChanged: (s) => setState(() => _view = s.first),
                ),
              ),
            ),
            if (_view == _ListView.day) ...[
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${_weekdays[_selectedDay.weekday - 1]}, '
                        '${_selectedDay.day} ${_months[_selectedDay.month - 1]} '
                        '${_selectedDay.year}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
            _AssignmentList(
              items: items,
              emptyIcon: emptyIcon,
              emptyTitle: emptyTitle,
              emptyMessage: emptyMessage,
              onToggle: _toggle,
              onEdit: (a) => _openForm(context, existing: a),
              onDelete: _confirmDelete,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggle(AssignmentModel a) async {
    final ok = await _controller.setCompleted(a.id, !a.isCompleted);
    if (!ok) {
      CustomSnackbar.error(
        title: 'Update failed',
        message: _controller.errorMessage ?? 'Please try again.',
      );
    }
  }

  Future<void> _confirmDelete(AssignmentModel a) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete assignment?'),
        content: Text('"${a.title}" will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final ok = await _controller.deleteAssignment(a.id);
    if (!ok) {
      CustomSnackbar.error(
        title: 'Delete failed',
        message: _controller.errorMessage ?? 'Please try again.',
      );
    }
  }

  void _openForm(BuildContext context, {AssignmentModel? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AssignmentFormSheet(
        controller: _controller,
        existing: existing,
        initialDate: _selectedDay,
      ),
    );
  }
}

// ---------------------------------------------------------------
// Month calendar with deadline markers
// ---------------------------------------------------------------
class _MonthCalendar extends StatelessWidget {
  final DateTime month; // first day of the visible month
  final DateTime selected;
  final Map<DateTime, List<AssignmentModel>> byDay;
  final ValueChanged<DateTime> onSelect;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _MonthCalendar({
    required this.month,
    required this.selected,
    required this.byDay,
    required this.onSelect,
    required this.onPrev,
    required this.onNext,
  });

  Color? _dotColor(List<AssignmentModel> items, ColorScheme scheme) {
    if (items.isEmpty) return null;
    final pending = items.where((a) => !a.isCompleted).toList();
    if (pending.isEmpty) return scheme.outline; // only completed
    if (pending.any((a) => a.isOverdue || a.isUrgent)) return scheme.error;
    if (pending.any((a) => a.isDueSoon)) return Colors.amber;
    return scheme.primary;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final offset = DateTime(month.year, month.month, 1).weekday - 1; // Mon=0
    final cellCount = ((offset + daysInMonth + 6) ~/ 7) * 7;
    final today = _dateOnly(DateTime.now());

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: onPrev,
              ),
              Expanded(
                child: Center(
                  child: Text(
                    '${_monthNames[month.month - 1]} ${month.year}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: onNext,
              ),
            ],
          ),
          Row(
            children: [
              for (final d in const ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
                Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          LayoutBuilder(
            builder: (context, constraints) => GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: (constraints.maxWidth / 7) / 44,
              children: List.generate(cellCount, (i) {
                final dayNum = i - offset + 1;
                if (dayNum < 1 || dayNum > daysInMonth) {
                  return const SizedBox.shrink();
                }

                final date = DateTime(month.year, month.month, dayNum);
                final isSelected = date == selected;
                final isToday = date == today;
                final dot = _dotColor(byDay[date] ?? const [], scheme);

                return InkWell(
                  onTap: () => onSelect(date),
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 28,
                        width: 28,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? scheme.primary : null,
                          border: isToday && !isSelected
                              ? Border.all(color: scheme.primary)
                              : null,
                        ),
                        child: Text(
                          '$dayNum',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isSelected ? scheme.onPrimary : null,
                            fontWeight:
                            isSelected || isToday ? FontWeight.bold : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Container(
                        height: 5,
                        width: 5,
                        decoration: BoxDecoration(
                          color: dot ?? Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------
// List
// ---------------------------------------------------------------
class _AssignmentList extends StatelessWidget {
  final List<AssignmentModel> items;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptyMessage;
  final Future<void> Function(AssignmentModel) onToggle;
  final void Function(AssignmentModel) onEdit;
  final Future<void> Function(AssignmentModel) onDelete;

  const _AssignmentList({
    required this.items,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _EmptyState(
        icon: emptyIcon,
        title: emptyTitle,
        message: emptyMessage,
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        children: [
          for (final a in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _AssignmentCard(
                assignment: a,
                onToggle: () => onToggle(a),
                onEdit: () => onEdit(a),
                onDelete: () => onDelete(a),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------
// Card
// ---------------------------------------------------------------
class _AssignmentCard extends StatelessWidget {
  final AssignmentModel assignment;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AssignmentCard({
    required this.assignment,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final a = assignment;

    // Highlight state (FR4.7): overdue/urgent -> red, < 7 days -> amber
    Color? accent;
    if (a.isOverdue || a.isUrgent) {
      accent = scheme.error;
    } else if (a.isDueSoon) {
      accent = Colors.amber;
    }

    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 14, 8, 14),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: accent != null
              ? Border.all(color: accent, width: 1.5)
              : null,
        ),
        child: Row(
          children: [
            Checkbox(
              value: a.isCompleted,
              onChanged: (_) => onToggle(),
              shape: const CircleBorder(),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    a.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      decoration:
                      a.isCompleted ? TextDecoration.lineThrough : null,
                      color: a.isCompleted ? scheme.onSurfaceVariant : null,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    a.subject,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 14,
                        color: scheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          _formatDateTime(a.deadline),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!a.isCompleted) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: (accent ?? scheme.primary)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        a.remainingLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: accent ?? scheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: Icon(Icons.delete_outline_rounded, color: scheme.error),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: scheme.onPrimaryContainer),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------
// Add / Edit form
// ---------------------------------------------------------------
class _AssignmentFormSheet extends StatefulWidget {
  final AssignmentController controller;
  final AssignmentModel? existing;
  final DateTime? initialDate;

  const _AssignmentFormSheet({
    required this.controller,
    this.existing,
    this.initialDate,
  });

  @override
  State<_AssignmentFormSheet> createState() => _AssignmentFormSheetState();
}

class _AssignmentFormSheetState extends State<_AssignmentFormSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _subjectController;
  DateTime? _deadline;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleController = TextEditingController(text: e?.title ?? '');
    _subjectController = TextEditingController(text: e?.subject ?? '');
    _deadline = e?.deadline ?? _defaultDeadline(widget.initialDate);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  /// Pre-fill the selected calendar day at 11:59 PM (if still in the future).
  DateTime? _defaultDeadline(DateTime? day) {
    if (day == null) return null;
    final d = DateTime(day.year, day.month, day.day, 23, 59);
    return d.isAfter(DateTime.now()) ? d : null;
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final initial = _deadline ?? now.add(const Duration(days: 1));

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: _isEdit && initial.isBefore(now) ? initial : now,
      lastDate: now.add(const Duration(days: 365 * 3)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return;

    setState(() {
      _deadline = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    final bool ok;
    if (_isEdit) {
      ok = await widget.controller.updateAssignment(
        id: widget.existing!.id,
        title: _titleController.text,
        subject: _subjectController.text,
        deadline: _deadline,
      );
    } else {
      ok = await widget.controller.addAssignment(
        title: _titleController.text,
        subject: _subjectController.text,
        deadline: _deadline,
      );
    }

    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      Navigator.pop(context);
      CustomSnackbar.success(
        title: _isEdit ? 'Assignment updated' : 'Assignment added',
        message: _titleController.text.trim(),
      );
    } else {
      CustomSnackbar.error(
        title: 'Could not save',
        message: widget.controller.errorMessage ?? 'Please try again.',
      );
    }
  }

  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _isEdit ? 'Edit assignment' : 'New assignment',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              decoration: _decoration('Assignment title', Icons.title_rounded),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _subjectController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              decoration:
              _decoration('Subject / course', Icons.menu_book_rounded),
            ),
            const SizedBox(height: 14),
            InkWell(
              onTap: _pickDeadline,
              borderRadius: BorderRadius.circular(14),
              child: InputDecorator(
                decoration: _decoration('Deadline', Icons.event_rounded),
                child: Text(
                  _deadline == null
                      ? 'Select date & time'
                      : _formatDateTime(_deadline!),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: _deadline == null ? scheme.onSurfaceVariant : null,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                )
                    : Text(_isEdit ? 'Save changes' : 'Add assignment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}