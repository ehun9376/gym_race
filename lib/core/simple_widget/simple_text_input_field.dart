import "package:flutter/material.dart";
import "package:gym_race/core/simple_widget/simple_text.dart";
import "package:gym_race/core/simple_widget/simple_text_field.dart";
import "package:gym_race/core/utility/widget_fixer.dart";

/// 通用文本輸入組件
/// 支持標題、必填標記、子標題、輸入框等
enum SimpleTextInputFieldStyle { rounded, selectable }

class SimpleTextInputField extends StatefulWidget {
  final String title;

  final String placeHolder;

  final String? subTitle;

  final bool isRequired;

  final String defaultText;

  final Function(String value) onEditValue;

  final TextInputType keyboardType;

  final bool obscureText;

  final BorderRadius? cornerRadius;

  final int maxLines;

  final int minLines;

  final bool canEdit;

  final RegExp? inputRegex;

  final bool showPasswordToggle;

  final TextEditingController? controller;

  final SimpleTextInputFieldStyle style;

  final int? maxLength;

  final bool showCharacterCounter;

  const SimpleTextInputField({
    super.key,
    required this.title,
    required this.placeHolder,
    required this.defaultText,
    required this.onEditValue,
    this.subTitle,
    this.isRequired = false,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.cornerRadius,
    this.maxLines = 1,
    this.minLines = 1,
    this.canEdit = true,
    this.inputRegex,
    this.showPasswordToggle = false,
    this.controller,
    this.style = SimpleTextInputFieldStyle.rounded,
    this.maxLength,
    this.showCharacterCounter = false,
  });

  @override
  State<SimpleTextInputField> createState() => _SimpleTextInputFieldState();
}

class _SimpleTextInputFieldState extends State<SimpleTextInputField> {
  late bool _obscureText;
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
    _controller =
        widget.controller ?? TextEditingController(text: widget.defaultText);
    _controller.text = widget.defaultText;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSelectableStyle =
        widget.style == SimpleTextInputFieldStyle.selectable;
    final cornerRadius =
        widget.cornerRadius ??
        BorderRadius.circular(isSelectableStyle ? 12 : 25);

    final textField = SimpleTextField(
      controller: _controller,
      defaultText: widget.defaultText,
      placeHolder: widget.placeHolder,
      onEditValue: widget.onEditValue,
      keyboardType: widget.keyboardType,
      obscureText: _obscureText,
      textColor: Colors.black,
      cornerRadius: cornerRadius,
      maxLines: widget.maxLines,
      readOnly: !widget.canEdit,
      backgroundColor: widget.canEdit ? Colors.white : Colors.grey[200],
      inputRegex: widget.inputRegex,
      maxLength: widget.maxLength,
      showCharacterCounter: widget.showCharacterCounter,
      borderColor: isSelectableStyle ? Colors.grey.shade300 : null,
      borderWidth: isSelectableStyle ? 1 : 0,
      boxShadow: isSelectableStyle ? const [] : null,
      suffixIcon: widget.showPasswordToggle && widget.obscureText
          ? [
              GestureDetector(
                onTap: _togglePasswordVisibility,
                child: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(
                    _obscureText ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                    size: 20,
                  ),
                ),
              ),
            ]
          : [],
    );

    return Column(
      spacing: 8,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.title.isNotEmpty)
          Row(
            children: [
              SimpleText(
                text: widget.title,
                fontSize: isSelectableStyle ? 16 : 18,
                fontWeight: FontWeight.w600,
              ),
              if (widget.isRequired)
                SimpleText(
                  text: ' ※',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  textColor: Colors.red,
                ),
            ],
          ),

        if (widget.subTitle != null)
          SimpleText(
            text: widget.subTitle!,
            fontSize: 14,
            textColor: Colors.grey,
          ),

        if (isSelectableStyle)
          textField
        else
          textField.container(
            decoration: BoxDecoration(
              borderRadius: cornerRadius,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withAlpha(125),
                  spreadRadius: 0,
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
