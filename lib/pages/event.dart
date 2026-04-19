import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
 
class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});
 
  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}
 
class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
 
  TimeOfDay _startTime  = TimeOfDay.now();
  TimeOfDay _endTime    = TimeOfDay(
    hour:   (TimeOfDay.now().hour + 1) % 24,
    minute: TimeOfDay.now().minute,
  );
  bool    _isRecurring = false;
  String  _frequency   = 'daily';
 
  static const _frequencies = [
    ('daily',    'Daily'),
    ('weekdays', 'Weekdays'),
    ('weekly',   'Weekly'),
    ('monthly',  'Monthly'),
  ];
 
  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }
 
  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
 
  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context:     context,
      initialTime: isStart ? _startTime : _endTime,
      helpText:    isStart ? 'Select start time' : 'Select end time',
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startTime = picked;
        // Auto-advance end time if it's now before start
        final startMinutes = picked.hour * 60 + picked.minute;
        final endMinutes   = _endTime.hour * 60 + _endTime.minute;
        if (endMinutes <= startMinutes) {
          final newEnd = startMinutes + 60;
          _endTime = TimeOfDay(hour: (newEnd ~/ 60) % 24, minute: newEnd % 60);
        }
      } else {
        _endTime = picked;
      }
    });
  }
 
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
 
    final startMin = _startTime.hour * 60 + _startTime.minute;
    final endMin   = _endTime.hour * 60 + _endTime.minute;
    if (endMin <= startMin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time.')),
      );
      return;
    }
 
    await context.read<AppProvider>().addTask(
          title:       _titleCtrl.text.trim(),
          startTime:   _fmt(_startTime),
          endTime:     _fmt(_endTime),
          isRecurring: _isRecurring,
          frequency:   _isRecurring ? _frequency : null,
        );
 
    if (!mounted) return;
    _titleCtrl.clear();
    setState(() {
      _startTime   = TimeOfDay.now();
      _endTime     = TimeOfDay(hour: (TimeOfDay.now().hour + 1) % 24, minute: TimeOfDay.now().minute);
      _isRecurring = false;
      _frequency   = 'daily';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:  Text('Task added and synced ✓'),
        duration: Duration(seconds: 2),
      ),
    );
  }
 
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final theme    = Theme.of(context);
 
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('New Task',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Added tasks are synced to your linked devices.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: Colors.grey.shade600)),
            const SizedBox(height: 28),
 
            // ── Task title ────────────────────────────────────────────────
            TextFormField(
              controller:         _titleCtrl,
              textCapitalization: TextCapitalization.sentences,
              textInputAction:    TextInputAction.done,
              onFieldSubmitted:   (_) => _submit(),
              decoration: const InputDecoration(
                labelText:  'Task name',
                prefixIcon: Icon(Icons.task_alt_outlined),
                border:     OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter a task name' : null,
            ),
            const SizedBox(height: 16),
 
            // ── Start / End time row ──────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _TimePicker(
                    label:   'Start time',
                    icon:    Icons.play_circle_outline,
                    time:    _startTime,
                    onTap:   () => _pickTime(true),
                    context: context,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TimePicker(
                    label:   'End time',
                    icon:    Icons.stop_circle_outlined,
                    time:    _endTime,
                    onTap:   () => _pickTime(false),
                    context: context,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
 
            // ── Recurring toggle ──────────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                border:       Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                secondary: const Icon(Icons.repeat),
                title:    const Text('Recurring task'),
                subtitle: const Text('Repeat this task on a schedule'),
                value:    _isRecurring,
                onChanged: (val) => setState(() => _isRecurring = val),
              ),
            ),
 
            // ── Frequency picker (animated) ───────────────────────────────
            AnimatedCrossFade(
              duration:     const Duration(milliseconds: 250),
              firstChild:   const SizedBox.shrink(),
              secondChild:  Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Frequency',
                        style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _frequencies.map((entry) {
                        final (value, label) = entry;
                        final selected = _frequency == value;
                        return ChoiceChip(
                          label:    Text(label),
                          selected: selected,
                          onSelected: (_) =>
                              setState(() => _frequency = value),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              crossFadeState: _isRecurring
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
            ),
 
            const SizedBox(height: 28),
 
            // ── Submit ────────────────────────────────────────────────────
            FilledButton.icon(
              onPressed: provider.isLoading ? null : _submit,
              icon:  const Icon(Icons.add),
              label: provider.isLoading
                  ? const SizedBox(
                      height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Add Task', style: TextStyle(fontSize: 16)),
              style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
 
            const SizedBox(height: 32),
            _TodayTasksSummary(),
          ],
        ),
      ),
    );
  }
}
 
// ── Time picker widget ─────────────────────────────────────────────────────────
 
class _TimePicker extends StatelessWidget {
  final String    label;
  final IconData  icon;
  final TimeOfDay time;
  final VoidCallback onTap;
  final BuildContext context;
 
  const _TimePicker({
    required this.label,
    required this.icon,
    required this.time,
    required this.onTap,
    required this.context,
  });
 
  @override
  Widget build(BuildContext _) {
    return InkWell(
      onTap:        onTap,
      borderRadius: BorderRadius.circular(8),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText:  label,
          prefixIcon: Icon(icon),
          border:     const OutlineInputBorder(),
        ),
        child: Text(
          time.format(context),
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
 
// ── Today's summary ────────────────────────────────────────────────────────────
 
class _TodayTasksSummary extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tasks = context.watch<AppProvider>().tasks;
    if (tasks.isEmpty) return const SizedBox.shrink();
 
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 12),
        Text("Today's Tasks (${tasks.length})",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),
        ...tasks.map((t) => ListTile(
              dense:   true,
              leading: Icon(
                t.isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                color: t.isDone ? Colors.green : Colors.grey,
              ),
              title: Text(t.title,
                  style: TextStyle(
                    decoration: t.isDone ? TextDecoration.lineThrough : null,
                    color:      t.isDone ? Colors.grey : null,
                  )),
              trailing: Text('${t.startTime}–${t.endTime}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12)),
            )),
      ],
    );
  }
}