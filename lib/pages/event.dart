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
  TimeOfDay _time  = TimeOfDay.now();

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await context.read<AppProvider>().addTask(
          title: _titleCtrl.text.trim(),
          time:  _formatTime(_time),
        );
    if (!mounted) return;
    _titleCtrl.clear();
    setState(() => _time = TimeOfDay.now());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Task added and synced to watch ✓'),
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
            Text(
              'New Task',
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Added tasks are immediately synced to your watch.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 32),

            // ── Task title ─────────────────────────────────────────────────
            TextFormField(
              controller:      _titleCtrl,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                labelText:  'What do you need to do?',
                prefixIcon: Icon(Icons.task_alt_outlined),
                border:     OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter a task name' : null,
            ),
            const SizedBox(height: 20),

            // ── Time picker ────────────────────────────────────────────────
            InkWell(
              onTap:         _pickTime,
              borderRadius:  BorderRadius.circular(8),
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText:  'Time',
                  prefixIcon: Icon(Icons.access_time_outlined),
                  border:     OutlineInputBorder(),
                ),
                child: Text(
                  _time.format(context),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 36),

            // ── Submit ─────────────────────────────────────────────────────
            FilledButton.icon(
              onPressed: provider.isLoading ? null : _submit,
              icon:  const Icon(Icons.add),
              label: provider.isLoading
                  ? const SizedBox(
                      height: 20,
                      width:  20,
                      child:  CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Add Task', style: TextStyle(fontSize: 16)),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            const SizedBox(height: 40),

            // ── Today's quick summary ──────────────────────────────────────
            _TodayTasksSummary(),
          ],
        ),
      ),
    );
  }
}

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
        Text(
          "Today's Tasks (${tasks.length})",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 10),
        ...tasks.map(
          (t) => ListTile(
            dense:   true,
            leading: Icon(
              t.isDone ? Icons.check_circle : Icons.radio_button_unchecked,
              color: t.isDone ? Colors.green : Colors.grey,
            ),
            title: Text(
              t.title,
              style: TextStyle(
                decoration: t.isDone ? TextDecoration.lineThrough : null,
                color:      t.isDone ? Colors.grey : null,
              ),
            ),
            trailing: Text(t.time,
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ),
        ),
      ],
    );
  }
}