import "package:gym_race/core/utility/widget_fixer.dart";
import "package:flutter/material.dart";
import "package:gym_race/core/simple_widget/simple_image.dart";
import "package:gym_race/core/simple_widget/simple_text.dart";

class SimpleButton extends StatelessWidget {
  /// 按鈕點擊回調
  final Function()? buttonAction;

  /// 圖片和文字的相對位置
  final Segmented? segmented;

  /// 背景顏色
  final Color? backgroundColor;

  /// 文字顏色
  final Color? titleColor;

  /// 圖標顏色
  final Color? iconColor;

  /// 本地圖片名稱 (asset/imageName)
  final String? imageName;

  /// 圖片尺寸
  final Size? imageSize;

  /// 網路圖片 URL
  final String? imageURL;

  /// 按鈕標題文字
  final String? buttontitle;

  /// 圓角半徑
  final double? cornerRadius;

  /// 字體大小
  final double? fontSize;

  /// 按鈕最小尺寸
  final Size? buttonMiniSize;

  /// 按鈕最大尺寸
  final Size? buttonMaxize;

  /// 按鈕內邊距
  final EdgeInsets? buttonPadding;

  /// 按鈕圖標 (可選替代 imageName)
  final IconData? buttonIcon;

  /// 圖標尺寸
  final double? iconSize;

  /// 邊框顏色
  final Color? borderColor;

  /// 邊框寬度
  final double? borderWidth;

  /// 字體樣式（優先於 fontSize / fontWeight）
  final GuideFontStyle? guideFontStyle;

  /// 字體粗細
  final FontWeight? fontWeight;

  /// 文字是否自動縮放以適應寬度
  final bool? autoSize;

  /// 圖片和文字之間的間距
  final double? imageTextSpace;

  /// 圖片 BoxFit
  final BoxFit imageFit;

  const SimpleButton({
    super.key,
    this.buttonAction,
    this.segmented,
    this.titleColor,
    this.backgroundColor,
    this.iconColor,
    this.cornerRadius,
    this.buttontitle,
    this.fontSize,
    this.imageName,
    this.imageURL,
    this.imageSize,
    this.buttonMiniSize,
    this.buttonMaxize,
    this.buttonPadding,
    this.buttonIcon,
    this.borderColor,
    this.borderWidth,
    this.guideFontStyle,
    this.fontWeight,
    this.imageTextSpace,
    this.iconSize,
    this.autoSize,
    this.imageFit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        minWidth: buttonMiniSize?.width ?? 0,
        minHeight: buttonMiniSize?.height ?? 0,
        maxWidth: buttonMaxize?.width ?? double.infinity,
        maxHeight: buttonMaxize?.height ?? double.infinity,
      ),
      padding: buttonPadding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(cornerRadius ?? 0),
        border: Border.all(
          color: borderColor ?? Colors.transparent,
          width: borderWidth ?? 0.0,
        ),
      ),
      child: _buildButtonContent().center(),
    ).inkWell(onTap: buttonAction);
  }

  /// 構建按鈕內容 (圖片 + 文字組合)
  Widget _buildButtonContent() {
    final segmented = this.segmented ?? Segmented.upToDown;

    final imageWidget = _buildImageWidget();
    final textWidget = _buildTextWidget();
    final spacer = SizedBox(height: imageTextSpace, width: imageTextSpace);

    // 只有文字，無圖片
    if (imageWidget == null) {
      return textWidget;
    }

    // 有圖片和文字
    if (buttontitle != null && buttontitle!.isNotEmpty) {
      switch (segmented) {
        case Segmented.upToDown:
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [imageWidget, spacer, textWidget],
          );

        case Segmented.downToUp:
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [textWidget, spacer, imageWidget],
          );

        case Segmented.leftToRight:
          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [imageWidget, spacer, textWidget],
          );

        case Segmented.rightToLeft:
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [textWidget, spacer, imageWidget],
          );
      }
    }

    // 只有圖片
    return imageWidget;
  }

  /// 構建圖片 Widget
  Widget? _buildImageWidget() {
    // 優先順序: imageName > imageURL > buttonIcon
    if (imageName != null) {
      return SimpleImage(
        fit: imageFit,
        imageName: imageName,
        imageSize: imageSize,
        color: iconColor,
      );
    }

    if (imageURL != null && imageURL!.isNotEmpty) {
      return SimpleImage(
        fit: imageFit,
        mediaUrl: imageURL,
        imageSize: imageSize,
        color: iconColor,
      );
    }

    if (buttonIcon != null) {
      return Icon(buttonIcon, size: iconSize, color: iconColor);
    }

    return null;
  }

  /// 構建文字 Widget
  Widget _buildTextWidget() {
    return SimpleText(
      text: buttontitle ?? "",
      guideFontStyle: guideFontStyle,
      fontSize: fontSize,
      textColor: titleColor,
      fontWeight: fontWeight,
      lines: 999,
      autoFitWidth: autoSize,
      align: TextAlign.center,
    );
  }
}

enum Segmented { upToDown, leftToRight, rightToLeft, downToUp }
