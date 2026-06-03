import "package:flutter/foundation.dart";
import "package:flutter/material.dart";

/// 給 overlay popup 用的「平滑展開」動畫：scale 0.9 → 1.0、opacity 0 → 1。
/// 預設以 [Alignment.topCenter] 為原點，配合貼在 anchor 下方的 dropdown popup
/// 由上往下展開最自然。
///
/// 若傳入 [dismissNotifier] 並把它設成 true，會反向播放動畫；動畫結束後
/// 呼叫 [onDismissed]（呼叫端通常在這裡才真正 `OverlayEntry.remove()`）。
class AnimatedPopupReveal extends StatefulWidget {
  final Widget child;
  final Alignment alignment;
  final Duration duration;

  /// 設成 true → 反向播放收合動畫
  final ValueListenable<bool>? dismissNotifier;

  /// 反向動畫完成時呼叫
  final VoidCallback? onDismissed;

  const AnimatedPopupReveal({
    super.key,
    required this.child,
    this.alignment = Alignment.topCenter,
    this.duration = const Duration(milliseconds: 180),
    this.dismissNotifier,
    this.onDismissed,
  });

  @override
  State<AnimatedPopupReveal> createState() => _AnimatedPopupRevealState();
}

class _AnimatedPopupRevealState extends State<AnimatedPopupReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  late final Animation<double> _scale = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );
  late final Animation<double> _opacity = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.6, curve: Curves.easeOut),
  );

  bool _dismissing = false;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    widget.dismissNotifier?.addListener(_onDismissChanged);
  }

  @override
  void didUpdateWidget(covariant AnimatedPopupReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dismissNotifier != widget.dismissNotifier) {
      oldWidget.dismissNotifier?.removeListener(_onDismissChanged);
      widget.dismissNotifier?.addListener(_onDismissChanged);
    }
  }

  @override
  void dispose() {
    widget.dismissNotifier?.removeListener(_onDismissChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onDismissChanged() {
    if (_dismissing) return;
    if (widget.dismissNotifier?.value != true) return;
    _dismissing = true;
    _controller.reverse().whenComplete(() {
      if (!mounted) return;
      widget.onDismissed?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacity.value,
          child: Transform.scale(
            scale: 0.9 + 0.1 * _scale.value,
            alignment: widget.alignment,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
