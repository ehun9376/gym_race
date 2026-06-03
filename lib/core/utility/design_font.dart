import "package:flutter/material.dart";
import "package:google_fonts/google_fonts.dart";
import "package:gym_race/core/simple_widget/simple_text.dart";

class DesignFont {
  static String get notoSansTc => GoogleFonts.notoSansTc().fontFamily!;
  static String get inter => GoogleFonts.inter().fontFamily!;

  /// 英文用 Inter，中文自動 fallback 到 Noto Sans TC
  static List<String> get _fallback => [notoSansTc];

  static GuideFontStyle _style({
    required double fontSize,
    required FontWeight fontWeight,
  }) => GuideFontStyle(
    fontSize: fontSize,
    fontWeight: fontWeight,
    fontFamily: inter,
    fontFamilyFallback: _fallback,
  );

  ///medium/20
  static GuideFontStyle get heading1 =>
      _style(fontSize: 20, fontWeight: FontWeight.w600);

  ///medium/18
  static GuideFontStyle get heading2 =>
      _style(fontSize: 18, fontWeight: FontWeight.w600);

  ///medium/16
  static GuideFontStyle get text0Medium =>
      _style(fontSize: 30, fontWeight: FontWeight.w600);

  ///medium/16
  static GuideFontStyle get text1Medium =>
      _style(fontSize: 16, fontWeight: FontWeight.w600);

  ///medium/14
  static GuideFontStyle get text2Medium =>
      _style(fontSize: 14, fontWeight: FontWeight.w600);

  ///medium/13
  static GuideFontStyle get text3Medium =>
      _style(fontSize: 13, fontWeight: FontWeight.w600);

  ///medium/12
  static GuideFontStyle get text4Medium =>
      _style(fontSize: 12, fontWeight: FontWeight.w600);

  ///reg/16
  static GuideFontStyle get text1Regular =>
      _style(fontSize: 16, fontWeight: FontWeight.w400);

  ///reg/14
  static GuideFontStyle get text2Regular =>
      _style(fontSize: 14, fontWeight: FontWeight.w400);

  ///reg/12
  static GuideFontStyle get text3Regular =>
      _style(fontSize: 12, fontWeight: FontWeight.w400);

  ///reg/10
  static GuideFontStyle get text5Regular =>
      _style(fontSize: 10, fontWeight: FontWeight.w400);
}
