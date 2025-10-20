import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../utils/time_utils.dart';

class TimePickerField extends StatefulWidget {
  const TimePickerField({
    super.key,
    required this.label,
    required this.initialTime,
    required this.onTimeChanged,
    this.enabled = true,
  });

  final String label;
  final TimeOfDay initialTime;
  final ValueChanged<TimeOfDay> onTimeChanged;
  final bool enabled;

  @override
  State<TimePickerField> createState() => _TimePickerFieldState();
}

class _TimePickerFieldState extends State<TimePickerField> {
  late TimeOfDay _selectedTime;
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _selectedTime = widget.initialTime;
    _controller = TextEditingController(text: formatTimeOfDay(_selectedTime));
  }

  @override
  void didUpdateWidget(TimePickerField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTime != widget.initialTime) {
      _selectedTime = widget.initialTime;
      _controller.text = formatTimeOfDay(_selectedTime);
    }
  }

  Future<void> _openPicker() async {
    final selected = await showCupertinoModalPopup<TimeOfDay>(
      context: context,
      builder: (context) {
        TimeOfDay tempValue = _selectedTime;
        return Container(
          height: 280,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Отмена'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(tempValue),
                      child: const Text('Готово'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  use24hFormat: true,
                  initialDateTime: DateTime(
                    0,
                    1,
                    1,
                    _selectedTime.hour,
                    _selectedTime.minute,
                  ),
                  onDateTimeChanged: (dateTime) {
                    tempValue = TimeOfDay(hour: dateTime.hour, minute: dateTime.minute);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );

    if (selected != null && mounted) {
      setState(() {
        _selectedTime = selected;
        _controller.text = formatTimeOfDay(_selectedTime);
      });
      widget.onTimeChanged(selected);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      readOnly: true,
      enabled: widget.enabled,
      onTap: widget.enabled ? _openPicker : null,
      decoration: InputDecoration(
        labelText: widget.label,
        suffixIcon: const Icon(Icons.access_time),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
    );
  }
}
