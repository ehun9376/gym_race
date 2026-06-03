import "package:gym_race/core/simple_widget/simple_image.dart";
import "package:gym_race/core/utility/widget_fixer.dart";
import "package:flutter/material.dart";

class SimpleRadio<T> extends StatefulWidget {
  const SimpleRadio({
    super.key,
    required this.value,
    required this.groupValue,
    required this.onChange,
    this.size = 30,
    this.selectedIcon,
    this.unselectedIcon,
    this.selectedColor,
    this.unselectedColor,
    this.borderColor,
  });

  final T value;
  final T? groupValue;
  final Function(T) onChange;
  final double size;
  final IconData? selectedIcon;
  final IconData? unselectedIcon;
  final Color? selectedColor;
  final Color? unselectedColor;
  final Color? borderColor;

  @override
  State<SimpleRadio<T>> createState() => _SimpleRadioState<T>();
}

class _SimpleRadioState<T> extends State<SimpleRadio<T>> {
  bool get isSelected => widget.value == widget.groupValue;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: widget.size,
      width: widget.size,

      child: SimpleImage(
        icon: isSelected
            ? (widget.selectedIcon ?? Icons.radio_button_checked)
            : (widget.unselectedIcon ?? Icons.radio_button_off),
        iconSize: widget.size,
        color: Colors.black,
      ),
    ).inkWell(onTap: () => widget.onChange(widget.value));
  }
}
