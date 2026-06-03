import "package:easy_localization/easy_localization.dart";
import "package:flutter/material.dart";

class GuideFontStyle {
  double fontSize;
  FontWeight fontWeight;
  FontStyle? fontStyle;
  String? fontFamily;
  List<String>? fontFamilyFallback;

  GuideFontStyle({
    required this.fontSize,
    required this.fontWeight,
    this.fontStyle,
    this.fontFamily,
    this.fontFamilyFallback,
  });
}

class SimpleText extends StatelessWidget {
  final String? text;

  final int? lines;
  final int? maxLines;

  final double? fontSize;

  final FontWeight? fontWeight;

  final Color? textColor;

  final FontStyle? style;

  final TextAlign? align;

  final bool? autoFitWidth;

  final TextDecoration? decoration;

  final double? decorationHeight;

  final TextOverflow? overflow;

  final GuideFontStyle? guideFontStyle;
  final String? fontFamily;

  const SimpleText({
    super.key,
    this.text,
    this.fontSize,
    this.fontWeight,
    this.textColor,
    this.lines,
    this.maxLines,
    this.style,
    this.align,
    this.decoration = TextDecoration.none,
    this.autoFitWidth,
    this.overflow = TextOverflow.ellipsis,
    this.decorationHeight,
    this.guideFontStyle,
    this.fontFamily,
  });

  @override
  Widget build(BuildContext context) {
    Widget textWidget = Text(
      (text ?? "").isEmpty ? (text ?? "") : (text ?? "").tr(),
      softWrap: true,
      maxLines: lines ?? 999,
      overflow: overflow,
      textAlign: align,
      style: TextStyle(
        decoration: decoration,
        decorationColor: textColor,
        decorationThickness: decorationHeight,
        fontSize: guideFontStyle?.fontSize ?? fontSize,
        fontWeight: guideFontStyle?.fontWeight ?? fontWeight,
        color: textColor,
        fontStyle: guideFontStyle?.fontStyle ?? style,
        fontFamily: guideFontStyle?.fontFamily ?? fontFamily,
        fontFamilyFallback: guideFontStyle?.fontFamilyFallback,
      ),
    );

    if (autoFitWidth ?? false) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: textWidget,
      );
    } else {
      return textWidget;
    }
  }
}
