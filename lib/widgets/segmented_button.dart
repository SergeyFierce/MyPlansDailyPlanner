import 'package:flutter/material.dart';

class SegmentedButton extends StatelessWidget {
  const SegmentedButton({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final border = RoundedRectangleBorder(borderRadius: BorderRadius.circular(8));
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        shape: border,
        side: BorderSide(
          color: selected ? const Color(0xFF4F46E5) : const Color(0x334F46E5),
          width: 1.2,
        ),
        foregroundColor: selected ? Colors.white : const Color(0xFF4F46E5),
        backgroundColor: selected ? const Color(0xFF4F46E5) : Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Text(label),
    );
  }
}
