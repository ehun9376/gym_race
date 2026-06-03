import "package:flutter/material.dart";
import "package:gym_race/core/simple_widget/simple_image.dart";
import "package:gym_race/core/utility/widget_fixer.dart";

class SimpleCheckBox extends StatefulWidget {
  const SimpleCheckBox({
    super.key,
    required this.selected,
    required this.onChange,
    this.size = 25,
  });
  final bool selected;
  final Function(bool) onChange;
  final double size;

  @override
  State<SimpleCheckBox> createState() => _SimpleCheckBoxState();
}

class _SimpleCheckBoxState extends State<SimpleCheckBox> {
  bool selected = false;

  @override
  void initState() {
    super.initState();
    selected = widget.selected;
  }

  @override
  void didUpdateWidget(covariant SimpleCheckBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    setState(() {
      selected = widget.selected;
    });
  }

  @override
  Widget build(BuildContext context) {
    return (selected
            ? SimpleImage(
                    cornerRadius: 5,
                    icon: selected ? Icons.check : null,
                    color: selected ? Colors.white : Colors.black,
                    iconSize: widget.size - 10,
                    borderWidth: 1.5,
                    borderColor: Colors.black,
                    backgroudColor: selected ? Colors.black : Colors.white,
                  )
                  .sizedBox(width: widget.size, height: widget.size)
                  .animatedSwitcher()
            : Container(
                height: widget.size,
                width: widget.size,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: Colors.black, width: 1.5),
                ),
              ))
        .animatedSwitcher()
        .inkWell(
          onTap: () {
            setState(() {
              selected = !selected;
            });
            widget.onChange(selected);
          },
        );
  }
}
