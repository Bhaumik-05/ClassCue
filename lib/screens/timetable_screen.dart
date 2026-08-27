import 'package:flutter/material.dart';

import '../controllers/class_controller.dart';
import '../models/class_model.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  static const List<String> _days = [
    'MONDAY',
    'TUESDAY',
    'WEDNESDAY',
    'THURSDAY',
    'FRIDAY',
    'SATURDAY',
    'SUNDAY',
  ];

  final ClassController _controller = ClassController();
  late String _selectedDay;
  late Stream<List<ClassModel>> _classesStream;

  @override
  void initState() {
    super.initState();
    final todayIndex = DateTime.now().weekday - 1; // Mon=0..Sun=6
    _selectedDay = _days[todayIndex];
    _classesStream = _controller.watchClasses(dayOfWeek: _selectedDay);
  }

  void _selectDay(String day) {
    setState(() {
      _selectedDay = day;
      _classesStream = _controller.watchClasses(dayOfWeek: day);
    });
  }

  String _dayLabel(String day) {
    final s = day.substring(0, 1) + day.substring(1).toLowerCase();
    return s.substring(0, 3);
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
                Icons.calendar_month_rounded,
                color: scheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Timetable',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openClassForm(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add class'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            _DaySelector(
              days: _days,
              selectedDay: _selectedDay,
              dayLabel: _dayLabel,
              onSelected: _selectDay,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<List<ClassModel>>(
                stream: _classesStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Error:\n${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.error,
                          ),
                        ),
                      ),
                    );
                  }

                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final classes = snapshot.data!;

                  if (classes.isEmpty) {
                    return _EmptyState(
                      onAddClass: () => _openClassForm(context),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                    itemCount: classes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final c = classes[index];
                      return _ClassCard(
                        classModel: c,
                        onTap: () => _openClassForm(context, existing: c),
                        onDelete: () => _deleteClass(c.id),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteClass(String id) async {
    final success = await _controller.deleteClass(id);

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_controller.errorMessage ?? 'Delete failed')),
      );
    }
  }

  void _openClassForm(BuildContext context, {ClassModel? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ClassFormSheet(
        controller: _controller,
        initialDay: _selectedDay,
        days: _days,
        dayLabel: _dayLabel,
        existing: existing,
      ),
    );
  }
}

class _DaySelector extends StatelessWidget {
  final List<String> days;
  final String selectedDay;
  final String Function(String) dayLabel;
  final ValueChanged<String> onSelected;

  const _DaySelector({
    required this.days,
    required this.selectedDay,
    required this.dayLabel,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 64,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final day = days[index];
          final isSelected = day == selectedDay;

          return InkWell(
            onTap: () => onSelected(day),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 56,
              decoration: BoxDecoration(
                color: isSelected
                    ? scheme.primaryContainer
                    : scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.center,
              child: Text(
                dayLabel(day),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? scheme.onPrimaryContainer
                      : scheme.onSurfaceVariant,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  final ClassModel classModel;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ClassCard({
    required this.classModel,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
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
                Icons.menu_book_rounded,
                color: scheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    classModel.subjectName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${classModel.startTime} - ${classModel.endTime}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
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

class _EmptyState extends StatelessWidget {
  final VoidCallback onAddClass;

  const _EmptyState({required this.onAddClass});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 96,
              width: 96,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.event_available_rounded,
                size: 44,
                color: scheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No classes yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap "Add class" to build your timetable',
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

class _ClassFormSheet extends StatefulWidget {
  final ClassController controller;
  final String initialDay;
  final List<String> days;
  final String Function(String) dayLabel;
  final ClassModel? existing;

  const _ClassFormSheet({
    required this.controller,
    required this.initialDay,
    required this.days,
    required this.dayLabel,
    this.existing,
  });

  @override
  State<_ClassFormSheet> createState() => _ClassFormSheetState();
}

class _ClassFormSheetState extends State<_ClassFormSheet> {
  late final TextEditingController _subjectController;
  late String _selectedDay;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isSaving = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _subjectController =
        TextEditingController(text: existing?.subjectName ?? '');
    _selectedDay = existing?.dayOfWeek ?? widget.initialDay;
    _startTime = existing != null ? _parseTime(existing.startTime) : null;
    _endTime = existing != null ? _parseTime(existing.endTime) : null;
  }

  TimeOfDay _parseTime(String value) {
    final parts = value.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTime(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  @override
  void dispose() {
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: (isStart ? _startTime : _endTime) ?? TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    final subject = _subjectController.text.trim();

    if (subject.isEmpty || _startTime == null || _endTime == null) {
      setState(() => _errorText = 'Please fill in all fields');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorText = null;
    });

    final isEditing = widget.existing != null;

    final success = isEditing
        ? await widget.controller.updateClass(
      id: widget.existing!.id,
      subjectName: subject,
      startTime: _formatTime(_startTime!),
      endTime: _formatTime(_endTime!),
      dayOfWeek: _selectedDay,
    )
        : await widget.controller.addClass(
      subjectName: subject,
      startTime: _formatTime(_startTime!),
      endTime: _formatTime(_endTime!),
      dayOfWeek: _selectedDay,
    );

    if (!mounted) return;

    if (success) {
      Navigator.pop(context);
    } else {
      setState(() {
        _isSaving = false;
        _errorText = widget.controller.errorMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isEditing = widget.existing != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isEditing ? 'Edit class' : 'Add class',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _subjectController,
              decoration: const InputDecoration(
                labelText: 'Subject name',
                prefixIcon: Icon(Icons.menu_book_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickTime(isStart: true),
                    icon: const Icon(Icons.schedule_rounded),
                    label: Text(
                      _startTime == null
                          ? 'Start time'
                          : _formatTime(_startTime!),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickTime(isStart: false),
                    icon: const Icon(Icons.schedule_rounded),
                    label: Text(
                      _endTime == null ? 'End time' : _formatTime(_endTime!),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.days.map((day) {
                final isSelected = day == _selectedDay;
                return ChoiceChip(
                  label: Text(widget.dayLabel(day)),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedDay = day),
                );
              }).toList(),
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorText!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.error,
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              height: 52,
              child: FilledButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const CircularProgressIndicator()
                    : Text(isEditing ? 'Save changes' : 'Add class'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}