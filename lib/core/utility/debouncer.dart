import "dart:async";

/// Leading + trailing debouncer。
///
/// - 視窗外（`_timer == null`）首次呼叫 [run]：**立即執行 leading** 並開啟視窗。
/// - 視窗內後續呼叫：只標記 trailing pending，視窗結束後最多再執行 1 次。
/// - 視窗內無論呼叫幾次，總共最多執行 2 次（leading + 1 次 trailing）。
///
/// 與純 trailing 的差別：第一次呼叫不會等待，UI 反饋較即時。
class Debouncer {
  final Duration duration;
  final Future<void> Function() action;

  Timer? _timer;
  bool _pendingTrailing = false;

  Debouncer({
    required this.action,
    this.duration = const Duration(seconds: 1),
  });

  /// 視窗外立即跑 leading；視窗內把後續呼叫合併成一次 trailing。
  Future<void> run() async {
    if (_timer != null) {
      _pendingTrailing = true;
      return;
    }
    _timer = Timer(duration, () async {
      _timer = null;
      if (_pendingTrailing) {
        _pendingTrailing = false;
        await action();
      }
    });
    await action();
  }

  /// 中斷 pending trailing，並關閉視窗。
  void cancel() {
    _timer?.cancel();
    _timer = null;
    _pendingTrailing = false;
  }
}
