import "package:flutter/material.dart";

enum ShimmerType {
  breathing, // 呼吸動畫
  sliding, // 從左至右動畫
}

class SimpleShimmerOverlay extends StatefulWidget {
  final double? borderRadius;
  final ShimmerType shimmerType;

  const SimpleShimmerOverlay({
    super.key,
    this.borderRadius,
    this.shimmerType = ShimmerType.breathing,
  });

  @override
  SimpleShimmerOverlayState createState() => SimpleShimmerOverlayState();
}

class SimpleShimmerOverlayState extends State<SimpleShimmerOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    if (widget.shimmerType == ShimmerType.breathing) {
      // 呼吸動畫配置
      _animation = Tween<double>(
        begin: 0.3,
        end: 0.7,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    } else if (widget.shimmerType == ShimmerType.sliding) {
      // 從左至右動畫配置
      _animation = Tween<double>(begin: -0.2, end: 1.2).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Curves.fastEaseInToSlowEaseOut,
        ),
      );
    }
    _controller.repeat(reverse: true); // 啟動動畫
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        if (widget.shimmerType == ShimmerType.breathing) {
          // 呼吸動畫
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius ?? 30),
              color: Colors.grey.withValues(alpha: _animation.value),
            ),
          );
        } else {
          // 從左至右動畫
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius ?? 30),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.grey..withAlpha(100),
                  Colors.grey..withAlpha(200),
                  Colors.grey..withAlpha(100),
                ],
                stops: [
                  (_animation.value - 0.2).clamp(0.0, 1.0),
                  _animation.value.clamp(0.0, 1.0),
                  (_animation.value + 0.2).clamp(0.0, 1.0),
                ],
              ),
            ),
          );
        }
      },
    );
  }
}
