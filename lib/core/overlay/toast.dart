import "dart:async";
import 'package:flutter/material.dart';
import 'package:gym_race/config.dart';
import 'package:gym_race/core/overlay/bottom_bar_height.dart';
import 'package:gym_race/core/overlay/snackbar_config.dart';
import 'package:gym_race/core/simple_widget/simple_text.dart';
import 'package:gym_race/core/utility/design_color.dart';
import 'package:gym_race/core/utility/design_font.dart';

class Toast {
  static OverlayEntry? _currentEntry;

  static void show({
    required String message,
    ToastConfigStyle style = ToastConfigStyle.message,
    Duration duration = const Duration(milliseconds: 3500),
  }) {
    // 如果當前已有顯示，先即時移除（不播 reverse，避免兩個 toast 疊圖）
    _currentEntry?.remove();
    _currentEntry = null;

    final overlay = navigatorKey.currentState?.overlay;
    late final OverlayEntry entry;
    bool removed = false;
    void safeRemove() {
      if (removed) return;
      removed = true;
      entry.remove();
      if (identical(_currentEntry, entry)) _currentEntry = null;
    }

    entry = OverlayEntry(
      builder: (context) {
        // 顯示期間動態追蹤 bottom bar 與鍵盤高度，仿原生 SnackBar 行為
        return ValueListenableBuilder<double>(
          valueListenable: bottomBarHeightNotifier,
          builder: (context, barHeight, _) {
            final mq = MediaQuery.of(context);
            // viewInsets.bottom = 鍵盤高度（鍵盤展開時）
            // 有 bottom bar 時用 barHeight（已涵蓋 home indicator 區）；
            // 沒 bottom bar 才用 padding.bottom 避開 home indicator
            final double safeBottom = barHeight > 0
                ? barHeight
                : mq.padding.bottom;
            return AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              left: 16,
              right: 16,
              bottom: mq.viewInsets.bottom + safeBottom + 10,
              child: Material(
                color: Colors.transparent,
                child: _BottomSnackBarWidget(
                  message: message,
                  style: style,
                  visibleDuration: duration,
                  onDismiss: safeRemove,
                ),
              ),
            );
          },
        );
      },
    );

    _currentEntry = entry;
    overlay?.insert(entry);
  }
}

class _BottomSnackBarWidget extends StatefulWidget {
  final String message;
  final ToastConfigStyle style;
  final Duration visibleDuration;
  final VoidCallback onDismiss;

  const _BottomSnackBarWidget({
    required this.message,
    required this.style,
    required this.visibleDuration,
    required this.onDismiss,
  });

  @override
  State<_BottomSnackBarWidget> createState() => _BottomSnackBarWidgetState();
}

class _BottomSnackBarWidgetState extends State<_BottomSnackBarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;
  Timer? _autoTimer;
  bool _dismissing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
    // 顯示時間到了 → 播 reverse → 才 onDismiss 把 entry 移掉
    _autoTimer = Timer(widget.visibleDuration, _animatedDismiss);
  }

  Future<void> _animatedDismiss() async {
    if (_dismissing || !mounted) return;
    _dismissing = true;
    await _controller.reverse();
    if (!mounted) return;
    widget.onDismiss();
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: _getBackgroundColor(),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(50),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              if (widget.style != ToastConfigStyle.message) ...[
                _buildIcon(),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: SimpleText(
                  text: widget.message,
                  guideFontStyle: DesignFont.text2Regular,
                  textColor: _getTextColor(),
                  style: DesignFont.text2Medium.fontStyle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor() {
    switch (widget.style) {
      case ToastConfigStyle.message:
        return DesignColor.toastMessage;
      case ToastConfigStyle.error:
        return DesignColor.toastError;
      case ToastConfigStyle.success:
        return DesignColor.toastSuccess;
    }
  }

  Color _getTextColor() {
    switch (widget.style) {
      case ToastConfigStyle.message:
      case ToastConfigStyle.error:
      case ToastConfigStyle.success:
        return DesignColor.textSecondary;
    }
  }

  Widget _buildIcon() {
    if (widget.style == ToastConfigStyle.success) {
      // 透明底 + 白邊 + 白勾
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          border: Border.all(color: _getTextColor(), width: 1.5),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.check, color: _getTextColor(), size: 16),
      );
    }
    // Error 樣式 (!)
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        border: Border.all(color: _getTextColor(), width: 1.5),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: SimpleText(
          text: "!",
          fontSize: 14,
          fontWeight: FontWeight.w700,
          textColor: _getTextColor(),
        ),
      ),
    );
  }
}
