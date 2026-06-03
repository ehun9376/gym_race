import "package:flutter/material.dart";

class SimpleSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final double width;
  final double height;
  final Color onColor;
  final Color offColor;
  final Color thumbColor;
  final double padding;

  const SimpleSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    required this.width,
    required this.height,
    required this.onColor,
    required this.offColor,
    this.thumbColor = Colors.white,
    this.padding = 3,
  });

  @override
  Widget build(BuildContext context) {
    final thumbSize = height - padding * 2;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: width,
        height: height,
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: value ? onColor : offColor,
          borderRadius: BorderRadius.circular(height / 2),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: thumbSize,
            height: thumbSize,
            decoration: BoxDecoration(
              color: thumbColor,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
