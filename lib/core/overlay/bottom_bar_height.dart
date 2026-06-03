import "package:flutter/material.dart";
import "package:gym_race/config.dart";

/// 全域當前可見頁面 bottom bar（DefaultScaffold 的 bottomNavigationBar）高度通知器。
/// [Toast] 讀取此值避免重疊；[DefaultScaffold] 會自動把 bottomNavigationBar
/// 包進 [BottomBarHeightObserver] 寫入。
final ValueNotifier<double> bottomBarHeightNotifier = ValueNotifier<double>(0);

// stack 模擬目前「可見」的 bottom bar 高度。
// 一頁被 push 蓋過時 _popHeight，回到頂層時再 _pushHeight。
final List<double> _heightStack = [];

void _pushHeight(double h) {
  _heightStack.add(h);
  bottomBarHeightNotifier.value = h;
}

void _popHeight(double h) {
  for (var i = _heightStack.length - 1; i >= 0; i--) {
    if ((_heightStack[i] - h).abs() < 0.5) {
      _heightStack.removeAt(i);
      break;
    }
  }
  bottomBarHeightNotifier.value = _heightStack.isEmpty ? 0 : _heightStack.last;
}

/// 量測 child 高度並寫入 [bottomBarHeightNotifier]。
/// 透過 [routeObserver] 知道自己所在的 PageRoute 是否為當前可見頁，
/// 只有可見時才 publish 高度，被蓋住 / pop 時自動 unpublish。
class BottomBarHeightObserver extends StatefulWidget {
  final Widget child;

  const BottomBarHeightObserver({super.key, required this.child});

  @override
  State<BottomBarHeightObserver> createState() =>
      _BottomBarHeightObserverState();
}

class _BottomBarHeightObserverState extends State<BottomBarHeightObserver>
    with RouteAware {
  final GlobalKey _key = GlobalKey();
  PageRoute? _route;
  double _published = 0;
  bool _isCurrent = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute && route != _route) {
      if (_route != null) routeObserver.unsubscribe(this);
      _route = route;
      routeObserver.subscribe(this, route);
      _isCurrent = route.isCurrent;
      if (_isCurrent) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
      }
    }
  }

  @override
  void didPush() {
    _isCurrent = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  @override
  void didPopNext() {
    _isCurrent = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  @override
  void didPushNext() {
    _isCurrent = false;
    _unpublish();
  }

  @override
  void didPop() {
    _isCurrent = false;
    _unpublish();
  }

  @override
  void didUpdateWidget(covariant BottomBarHeightObserver oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isCurrent) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
    }
  }

  void _measure() {
    if (!mounted || !_isCurrent) return;
    final ctx = _key.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox?;
    final h = box?.size.height ?? 0;
    if ((h - _published).abs() < 0.5) return;

    if (_published > 0) _popHeight(_published);
    if (h > 0) _pushHeight(h);
    _published = h;
  }

  void _unpublish() {
    if (_published > 0) {
      _popHeight(_published);
      _published = 0;
    }
  }

  @override
  void dispose() {
    if (_route != null) routeObserver.unsubscribe(this);
    _unpublish();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(key: _key, child: widget.child);
  }
}
