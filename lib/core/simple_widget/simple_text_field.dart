import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:gym_race/core/simple_widget/simple_text.dart";
import "package:gym_race/core/utility/design_color.dart";
import "package:gym_race/core/utility/design_font.dart";
import "package:gym_race/core/utility/widget_fixer.dart";

class SimpleTextField extends StatefulWidget {
  final TextInputType? keyboardType;
  final String? defaultText;
  final String? placeHolder;
  final Color? backgroundColor;
  final Function(String newValue)? onEditValue;
  final Function(String newValue)? subAction;
  final Function()? onTap;
  final BorderRadiusGeometry? cornerRadius;
  final Color? borderColor;
  final double? borderWidth;
  final int? maxLines;
  final bool? readOnly;
  final bool obscureText;
  final FocusNode? textFieldFocusNode;
  final double? width;
  final double? height;
  final TextEditingController? controller;
  final List<Widget> prefixIcon;
  final List<Widget> suffixIcon;
  final GuideFontStyle? guideFontStyle;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? textColor;
  final List<BoxShadow>? boxShadow;
  final Color? shadowColor;
  final double? shadowBlur;
  final Offset? shadowOffset;
  final int? maxLength;
  final RegExp? inputRegex;
  final List<String>? autofillHints;
  final bool showCharacterCounter;
  final TextInputAction? textInputAction;
  final EdgeInsets? contentPadding;

  const SimpleTextField({
    super.key,
    this.defaultText,
    this.backgroundColor,
    this.cornerRadius,
    this.borderColor,
    this.borderWidth,
    this.placeHolder,
    this.onEditValue,
    this.subAction,
    this.keyboardType,
    this.maxLines,
    this.readOnly,
    this.obscureText = false,
    this.textFieldFocusNode,
    this.width,
    this.height,
    this.controller,
    this.onTap,
    this.prefixIcon = const [],
    this.suffixIcon = const [],
    this.guideFontStyle,
    this.fontSize,
    this.fontWeight,
    this.textColor,
    this.boxShadow,
    this.shadowColor,
    this.shadowBlur,
    this.shadowOffset,
    this.maxLength,
    this.inputRegex,
    this.autofillHints,
    this.showCharacterCounter = false,
    this.textInputAction,
    this.contentPadding,
  });

  @override
  State<SimpleTextField> createState() => _SimpleTextFieldState();
}

class _SimpleTextFieldState extends State<SimpleTextField> {
  late FocusNode _focusNode;
  TextEditingController? _internalController;

  TextEditingController get _effectiveController =>
      widget.controller ?? _internalController!;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.textFieldFocusNode ?? FocusNode();

    if (widget.controller == null) {
      _internalController = TextEditingController(text: widget.defaultText);
    }

    // 計數器即時更新交給 [TextField.buildCounter]，由 Flutter 在 text
    // 變動時自動重建，不需要在這裡 setState。

    // 監聽焦點變化
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        // 確保焦點設置
        if (!_focusNode.hasPrimaryFocus) {
          _focusNode.requestFocus();
        }
      }
    });
  }

  @override
  void didUpdateWidget(SimpleTextField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.controller == null && oldWidget.controller != null) {
      _internalController = TextEditingController(text: widget.defaultText);
    } else if (widget.controller != null && oldWidget.controller == null) {
      _internalController?.dispose();
      _internalController = null;
    }

    final controller = _effectiveController;
    if (widget.defaultText != oldWidget.defaultText &&
        widget.defaultText != controller.text) {
      // 只有當新傳入的值跟目前輸入框裡的值「真的不同」時才賦值
      controller.value = controller.value.copyWith(
        text: widget.defaultText ?? "",
        selection: TextSelection.collapsed(
          offset: (widget.defaultText ?? "").length,
        ),
      );
    }
  }

  @override
  void dispose() {
    if (widget.textFieldFocusNode == null) {
      _focusNode.dispose(); // 僅在本地創建時釋放
    }
    _internalController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localController = _effectiveController;

    return Container(
      width: widget.width,
      height: widget.height, // 動態調整高度
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Colors.white,
        borderRadius: widget.cornerRadius ?? BorderRadius.circular(0),
        boxShadow:
            widget.boxShadow ??
            (widget.shadowColor != null || widget.shadowBlur != null
                ? [
                    BoxShadow(
                      color: widget.shadowColor ?? Colors.black.withAlpha(50),
                      blurRadius: widget.shadowBlur ?? 8,
                      offset: widget.shadowOffset ?? const Offset(0, 4),
                      spreadRadius: 0,
                    ),
                  ]
                : null),
      ),
      child: TextField(
        autofillHints: widget.autofillHints,
        focusNode: _focusNode,

        cursorColor: Colors.grey,
        obscureText: widget.obscureText,
        readOnly: widget.readOnly ?? false,
        textAlignVertical: widget.height != null
            ? TextAlignVertical.center
            : null, // 根據高度居中對齊
        maxLines: widget.maxLines ?? 1,
        textInputAction: (widget.maxLines ?? 1) > 1
            ? TextInputAction.newline
            : (widget.textInputAction ?? TextInputAction.done),
        keyboardType: (widget.maxLines ?? 1) > 1
            ? TextInputType.multiline
            : widget.keyboardType,
        controller: localController,
        style: TextStyle(
          fontSize: widget.guideFontStyle?.fontSize ?? widget.fontSize ?? 16,
          fontWeight:
              widget.guideFontStyle?.fontWeight ??
              widget.fontWeight ??
              FontWeight.normal,
          fontFamily: widget.guideFontStyle?.fontFamily,
          color: widget.textColor ?? Colors.black,
        ),
        decoration: InputDecoration(
          prefixIcon: widget.prefixIcon.isEmpty
              ? null
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: widget.prefixIcon,
                ),
          suffixIcon: widget.suffixIcon.isEmpty
              ? null
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: widget.suffixIcon,
                ),
          enabledBorder: OutlineInputBorder(
            borderRadius: widget.cornerRadius != null
                ? widget.cornerRadius is BorderRadius
                      ? widget.cornerRadius as BorderRadius
                      : BorderRadius.circular(0)
                : BorderRadius.circular(0),
            borderSide: BorderSide(
              color: widget.borderColor ?? Colors.transparent,
              width: widget.borderWidth ?? 0,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: widget.cornerRadius != null
                ? widget.cornerRadius is BorderRadius
                      ? widget.cornerRadius as BorderRadius
                      : BorderRadius.circular(0)
                : BorderRadius.circular(0),
            borderSide: BorderSide(
              color: widget.borderColor ?? Colors.transparent,
              width: widget.borderWidth ?? 0,
            ),
          ),
          contentPadding:
              widget.contentPadding ??
              EdgeInsets.symmetric(
                vertical: widget.height != null
                    ? widget.height! * 0.3
                    : 5, // 動態調整內邊距
                horizontal: 15,
              ),
          border: OutlineInputBorder(
            borderRadius: widget.cornerRadius != null
                ? widget.cornerRadius is BorderRadius
                      ? widget.cornerRadius as BorderRadius
                      : BorderRadius.circular(0)
                : BorderRadius.circular(0),
            borderSide: BorderSide(
              color: widget.borderColor ?? Colors.transparent,
              width: widget.borderWidth ?? 0,
            ),
          ),
          hintText: widget.placeHolder?.tr(),
          hintStyle: TextStyle(
            color: DesignColor.neutral65,
            fontSize: widget.guideFontStyle?.fontSize ?? widget.fontSize ?? 16,
            fontWeight: widget.guideFontStyle?.fontWeight,
            fontFamily: widget.guideFontStyle?.fontFamily,
          ),
        ),
        buildCounter: widget.showCharacterCounter && widget.maxLength != null
            ? (
                BuildContext context, {
                required int currentLength,
                required int? maxLength,
                required bool isFocused,
              }) {
                return SimpleText(
                  text: "$currentLength/${widget.maxLength}",
                  guideFontStyle: DesignFont.text3Regular,
                ).padding(const EdgeInsets.only(bottom: 15));
              }
            : null,
        onChanged: (value) {
          // 如果設定了 inputRegex，檢查輸入是否符合正規表達式
          if (widget.inputRegex != null) {
            final regex = widget.inputRegex!;
            // 檢查新輸入的字符是否符合正規表達式
            if (value.isNotEmpty && !regex.hasMatch(value)) {
              // 恢復為前一個符合正規表達式的值
              localController.text = localController.text.substring(
                0,
                localController.text.length - 1,
              );
              // 將光標移到文本末尾
              localController.selection = TextSelection.fromPosition(
                TextPosition(offset: localController.text.length),
              );
              return;
            }
          }
          widget.onEditValue?.call(localController.text);
        },
        inputFormatters: [
          if (widget.maxLength != null)
            LengthLimitingTextInputFormatter(widget.maxLength),
        ],
        onTap: () {
          widget.onTap?.call();
        },
        onSubmitted: (text) {
          _focusNode.unfocus();
          widget.subAction?.call(text);
        },

        // onTap: widget.onTap,
      ),
    );
  }
}

class AdaptiveTextField extends StatefulWidget {
  final FocusNode textFieldFocusNode;
  final TextEditingController controller;
  final Function(String)? subAction;
  final Function(String)? onEditValue;
  final String placeHolder;
  final Color backgroundColor;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? textColor;

  const AdaptiveTextField({
    super.key,
    required this.textFieldFocusNode,
    required this.controller,
    this.subAction,
    this.onEditValue,
    required this.placeHolder,
    required this.backgroundColor,
    this.fontSize,
    this.fontWeight,
    this.textColor,
  });

  @override
  AdaptiveTextFieldState createState() => AdaptiveTextFieldState();
}

class AdaptiveTextFieldState extends State<AdaptiveTextField> {
  double _textHeight = 0;
  int lineCount = 1;
  final int _maxLines = 4;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_updateTextHeight);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateTextHeight();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateTextHeight);
    super.dispose();
  }

  void _updateTextHeight() {
    final text = widget.controller.text.isEmpty
        ? widget.placeHolder
        : widget.controller.text;
    final span = TextSpan(
      text: text,
      style: TextStyle(
        fontSize: widget.fontSize ?? 18,
        fontWeight: widget.fontWeight ?? FontWeight.w600,
        color: widget.textColor ?? Colors.black,
      ),
    );
    final tp = TextPainter(
      text: span,
      maxLines: _maxLines,
      textDirection: Directionality.of(context),
    )..layout(maxWidth: MediaQuery.of(context).size.width - 80);
    final lineHeight = tp.preferredLineHeight;
    int lines = (tp.computeLineMetrics().length).clamp(1, _maxLines);
    setState(() {
      lineCount = lines;
      _textHeight = (lineHeight * lines) + 20; // 加點間距
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.backgroundColor,
      child: SizedBox(
        height: _textHeight,
        child: TextField(
          cursorColor: Colors.black,
          textAlign: TextAlign.left,
          focusNode: widget.textFieldFocusNode,
          controller: widget.controller,
          decoration: InputDecoration(
            hintText: widget.placeHolder.tr(),
            border: InputBorder.none,
          ),
          style: TextStyle(
            fontSize: widget.fontSize ?? 18,
            fontWeight: widget.fontWeight ?? FontWeight.w600,
            color: widget.textColor ?? Colors.black,
          ),
          minLines: 1,
          maxLines: _maxLines,
          onSubmitted: widget.subAction,
          onChanged: (value) {
            widget.onEditValue?.call(value);
            _updateTextHeight();
          },
          scrollPadding: const EdgeInsets.all(20),
        ),
      ),
    );
  }
}
