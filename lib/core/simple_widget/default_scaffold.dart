import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:gym_race/core/overlay/bottom_bar_height.dart";
import "package:gym_race/core/simple_widget/simple_text.dart";
import "package:gym_race/core/utility/design_color.dart";
import "package:gym_race/core/utility/widget_fixer.dart";

class DefaultScaffold extends StatelessWidget {
  const DefaultScaffold({
    super.key,
    required this.body,
    this.bottomNavigationBar,
    this.title,
    this.customTitleWidget,
    this.actions,
    this.leading,
    this.appBarBackgroundColor,
    this.contentBackgroundColor,
    this.statusBarColor,
    this.statusBarIconBrightness,
    this.avoidStatusBar = true,
    this.forceShowBackButton = false,
    this.titleColor,
    this.bottomSafeArea = true,
  });

  final Widget body;
  final Widget? bottomNavigationBar;
  final String? title;
  final Widget? customTitleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final Color? appBarBackgroundColor;
  final Color? contentBackgroundColor;
  final Color? statusBarColor;
  final Brightness? statusBarIconBrightness;
  final Color? titleColor;
  final bool avoidStatusBar;
  final bool forceShowBackButton;
  final bool bottomSafeArea;

  @override
  Widget build(BuildContext context) {
    var showAppBar =
        customTitleWidget != null ||
        title != null ||
        actions != null ||
        leading != null ||
        forceShowBackButton;

    // 設定 Status Bar 樣式
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: statusBarColor ?? DesignColor.backgroundSecondary,
        statusBarIconBrightness: statusBarIconBrightness ?? Brightness.dark,
        statusBarBrightness: statusBarIconBrightness == Brightness.light
            ? Brightness.dark
            : Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    return Container(
      color:
          statusBarColor ?? DesignColor.backgroundSecondary, // Scaffold 外的背景顏色
      child: SafeArea(
        top: avoidStatusBar, // 避免狀態欄遮擋內容
        bottom: false,
        child: Scaffold(
          extendBodyBehindAppBar: true, // 讓背景顏色延伸到 AppBar 後
          appBar: showAppBar
              ? AppBar(
                  // 滑動時不要套用 Material 3 預設的 surfaceTint，避免標題區換色
                  scrolledUnderElevation: 0,
                  surfaceTintColor: Colors.transparent,
                  foregroundColor: titleColor ?? DesignColor.textPrimary,
                  backgroundColor:
                      appBarBackgroundColor ?? DesignColor.backgroundSecondary,
                  title:
                      customTitleWidget ??
                      (title != null
                          ? SimpleText(
                              text: title,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              lines: 1,
                              align: TextAlign.center,
                              textColor: titleColor ?? DesignColor.textPrimary,
                            )
                          : null),
                  actions: actions,
                  leading: leading,
                )
              : null,
          backgroundColor:
              contentBackgroundColor ??
              DesignColor.backgroundSecondary, // Scaffold 內的背景顏色
          body: showAppBar
              ? SafeArea(
                  bottom: bottomSafeArea,
                  child: body.inkWell(
                    onTap: () {
                      // 點擊空白處收起鍵盤
                      FocusScope.of(context).unfocus();
                    },
                  ),
                )
              : body.inkWell(
                  onTap: () {
                    // 點擊空白處收起鍵盤
                    FocusScope.of(context).unfocus();
                  },
                ),
          bottomNavigationBar: bottomNavigationBar == null
              ? null
              : BottomBarHeightObserver(child: bottomNavigationBar!),
        ),
      ),
    );
  }
}
