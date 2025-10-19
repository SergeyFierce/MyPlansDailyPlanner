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
    const animationDuration = Duration(milliseconds: 220);
    const primaryColor = Color(0xFF4F46E5);
    final borderRadius = BorderRadius.circular(8);

    final backgroundColor = selected ? primaryColor : Colors.transparent;
    final borderColor = selected ? primaryColor : primaryColor.withOpacity(0.2);
    final textColor = selected ? Colors.white : primaryColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: onTap,
        child: AnimatedContainer(
          duration: animationDuration,
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: borderRadius,
            border: Border.all(color: borderColor, width: 1.2),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          child: AnimatedDefaultTextStyle(
            duration: animationDuration,
            curve: Curves.easeInOut,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}
