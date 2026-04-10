import 'package:calendar_view/calendar_view.dart';
import 'package:flutter/material.dart';

/// Colour palette the user can choose from when creating an event.
const List<Color> _eventColors = [
  Color(0xFF5B8DEF),
  Color(0xFF7B61FF),
  Color(0xFFFF6B6B),
  Color(0xFFFFB347),
  Color(0xFF4CAF50),
  Color(0xFF26C6DA),
  Color(0xFFEF5350),
  Color(0xFFAB47BC),
];

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({super.key});

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = TimeOfDay.now();
  TimeOfDay _endTime = TimeOfDay(
    hour: (TimeOfDay.now().hour + 1) % 24,
    minute: TimeOfDay.now().minute,
  );
  Color _selectedColor = _eventColors.first;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Pickers
  // -------------------------------------------------------------------------

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null) {
      setState(() {
        _startTime = picked;
        // Auto-advance end time by 1 hour if it would overlap
        if (_timeToMinutes(picked) >= _timeToMinutes(_endTime)) {
          _endTime = TimeOfDay(
            hour: (picked.hour + 1) % 24,
            minute: picked.minute,
          );
        }
      });
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (picked != null) setState(() => _endTime = picked);
  }

  int _timeToMinutes(TimeOfDay t) => t.hour * 60 + t.minute;

  String _formatTime(TimeOfDay t) {
    final hour = t.hour;
    final minute = t.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final display = hour % 12 == 0 ? 12 : hour % 12;
    return "$display:$minute $period";
  }

  String _formatDate(DateTime d) =>
      "${d.day.toString().padLeft(2, '0')} / "
      "${d.month.toString().padLeft(2, '0')} / ${d.year}";

  // -------------------------------------------------------------------------
  // Submit
  // -------------------------------------------------------------------------

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (_timeToMinutes(_endTime) <= _timeToMinutes(_startTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("End time must be after start time.")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final startDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _startTime.hour,
      _startTime.minute,
    );
    final endDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _endTime.hour,
      _endTime.minute,
    );

    final event = CalendarEventData(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      date: _selectedDate,
      startTime: startDateTime,
      endTime: endDateTime,
      color: _selectedColor,
    );

    CalendarControllerProvider.of(context).controller.add(event);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Event added & sent to watch ✓"),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Reset form
    _titleController.clear();
    _descriptionController.clear();
    setState(() {
      _selectedDate = DateTime.now();
      _startTime = TimeOfDay.now();
      _endTime = TimeOfDay(
        hour: (TimeOfDay.now().hour + 1) % 24,
        minute: TimeOfDay.now().minute,
      );
      _selectedColor = _eventColors.first;
      _isSubmitting = false;
    });
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            const Text(
              "NEW EVENT",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              "Fill in the details and we'll push it to your watch.",
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),

            const SizedBox(height: 24),

            // ── Title ───────────────────────────────────────────────────────
            _SectionLabel(label: "Event Title"),
            const SizedBox(height: 8),
            TextFormField(
              controller: _titleController,
              decoration: _inputDecoration(
                hint: "e.g. Morning Run",
                icon: Icons.title,
              ),
              textCapitalization: TextCapitalization.sentences,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? "Please enter a title" : null,
            ),

            const SizedBox(height: 20),

            // ── Description ─────────────────────────────────────────────────
            _SectionLabel(label: "Description (optional)"),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descriptionController,
              decoration: _inputDecoration(
                hint: "Add notes for this event…",
                icon: Icons.notes,
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),

            const SizedBox(height: 20),

            // ── Date ────────────────────────────────────────────────────────
            _SectionLabel(label: "Date"),
            const SizedBox(height: 8),
            _TappableField(
              icon: Icons.calendar_today,
              label: _formatDate(_selectedDate),
              onTap: _pickDate,
            ),

            const SizedBox(height: 20),

            // ── Time row ────────────────────────────────────────────────────
            _SectionLabel(label: "Time"),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _TappableField(
                    icon: Icons.access_time,
                    label: _formatTime(_startTime),
                    sublabel: "Start",
                    onTap: _pickStartTime,
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.arrow_forward, color: Colors.grey),
                const SizedBox(width: 12),
                Expanded(
                  child: _TappableField(
                    icon: Icons.access_time_filled,
                    label: _formatTime(_endTime),
                    sublabel: "End",
                    onTap: _pickEndTime,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Colour picker ────────────────────────────────────────────────
            _SectionLabel(label: "Colour"),
            const SizedBox(height: 12),
            _ColourPicker(
              colors: _eventColors,
              selected: _selectedColor,
              onSelected: (c) => setState(() => _selectedColor = c),
            ),

            const SizedBox(height: 32),

            // ── Submit ──────────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: const Icon(Icons.watch_later_outlined),
                label: const Text(
                  "Add Event & Send to Watch",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: Colors.blueGrey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.blueGrey[400]!, width: 1.5),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Small reusable widgets
// ---------------------------------------------------------------------------

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
        color: Colors.black54,
      ),
    );
  }
}

class _TappableField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? sublabel;
  final VoidCallback onTap;

  const _TappableField({
    required this.icon,
    required this.label,
    this.sublabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.blueGrey[50],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.blueGrey),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (sublabel != null)
                  Text(sublabel!,
                      style: const TextStyle(
                          fontSize: 11, color: Colors.black45)),
                Text(label,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ColourPicker extends StatelessWidget {
  final List<Color> colors;
  final Color selected;
  final ValueChanged<Color> onSelected;

  const _ColourPicker({
    required this.colors,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: colors.map((color) {
        final isSelected = color.value == selected.value;
        return GestureDetector(
          onTap: () => onSelected(color),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: isSelected
                  ? Border.all(color: Colors.black87, width: 2.5)
                  : null,
              boxShadow: isSelected
                  ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 6)]
                  : null,
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : null,
          ),
        );
      }).toList(),
    );
  }
}