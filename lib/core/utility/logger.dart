import "dart:async";
import "dart:convert";
import "dart:developer" as developer;
import "package:flutter/foundation.dart";
import "package:http/http.dart" as http;
import "package:intl/intl.dart";

enum LogLevel { debug, info, warning, error, success }

extension LogLevelExtension on LogLevel {
  String get emoji {
    switch (this) {
      case LogLevel.debug:
        return "🔧";
      case LogLevel.info:
        return "ℹ️";
      case LogLevel.warning:
        return "⚠️";
      case LogLevel.error:
        return "❌";
      case LogLevel.success:
        return "✅";
    }
  }

  String get prefix {
    switch (this) {
      case LogLevel.debug:
        return "DEBUG";
      case LogLevel.info:
        return "INFO";
      case LogLevel.warning:
        return "WARNING";
      case LogLevel.error:
        return "ERROR";
      case LogLevel.success:
        return "SUCCESS";
    }
  }

  String get color {
    switch (this) {
      case LogLevel.debug:
        return "\x1B[36m";
      case LogLevel.info:
        return "\x1B[34m";
      case LogLevel.warning:
        return "\x1B[33m";
      case LogLevel.error:
        return "\x1B[31m";
      case LogLevel.success:
        return "\x1B[32m";
    }
  }
}

class Logger {
  static final bool _isDebugMode = kDebugMode;

  // 統一序號佇列，確保所有 log 依呼叫順序輸出
  static int _nextSeq = 0;
  static int _printSeq = 0;
  static final Map<int, String> _pending = {};

  // ── 遠端傳輸 (對應 igolog VS Code extension) ─────────────
  static String _remoteHost = "127.0.0.1";
  static int _remotePort = 9876;
  static bool _remoteEnabled = kDebugMode;
  static http.Client _remoteClient = http.Client();
  // 全域單調遞增序號，讓 extension 端可重排（fire-and-forget 後順序由它負責）
  static int _remoteSeq = 0;

  // ── 熔斷狀態 ────────────────────────────────────────────
  // 連續 N 次失敗暫時關 remote，X 秒後再試
  static const int _circuitFailureThreshold = 3;
  static const Duration _circuitOpenDuration = Duration(seconds: 5);
  static const Duration _remoteTimeout = Duration(milliseconds: 150);
  static int _consecutiveFailures = 0;
  static DateTime? _circuitOpenedAt;

  /// 設定遠端 log 傳輸位置；預設 127.0.0.1:9876，對應 igolog VS Code extension。
  /// 真機/模擬器跨網路時把 [host] 換成電腦 IP，extension 端 igolog.host 設成 0.0.0.0。
  static void configureRemote({
    String host = "127.0.0.1",
    int port = 9876,
    bool enabled = true,
  }) {
    _remoteHost = host;
    _remotePort = port;
    _remoteEnabled = enabled;
    _resetCircuit();
  }

  static void _resetCircuit() {
    _consecutiveFailures = 0;
    _circuitOpenedAt = null;
  }

  /// 熔斷器是否打開（短期不送）。冷卻時間到了就半開、放一筆出去試
  static bool _isCircuitOpen() {
    final openedAt = _circuitOpenedAt;
    if (openedAt == null) return false;
    if (DateTime.now().difference(openedAt) >= _circuitOpenDuration) {
      _circuitOpenedAt = null;
      return false;
    }
    return true;
  }

  /// 失敗時 close 並重建 client，釋放壞掉的 keep-alive socket
  static void _rebuildClient() {
    try {
      _remoteClient.close();
    } catch (_) {}
    _remoteClient = http.Client();
  }

  static void _sendRemote(Map<String, dynamic> payload) {
    if (!_remoteEnabled || !_isDebugMode) return;
    if (_isCircuitOpen()) return;
    // 帶上序號讓 extension 端可重排
    payload["seq"] = _remoteSeq++;
    // Fire-and-forget：不串成 chain，一筆卡住不影響後面
    unawaited(_doSendRemote(payload));
  }

  static Future<void> _doSendRemote(Map<String, dynamic> payload) async {
    try {
      await _remoteClient
          .post(
            Uri.parse("http://$_remoteHost:$_remotePort/log"),
            headers: const {"Content-Type": "application/json"},
            body: jsonEncode(payload),
          )
          .timeout(_remoteTimeout);
      // 成功就重置熔斷
      if (_consecutiveFailures > 0) _resetCircuit();
    } catch (_) {
      _consecutiveFailures++;
      if (_consecutiveFailures >= _circuitFailureThreshold) {
        _circuitOpenedAt = DateTime.now();
        _rebuildClient();
      }
    }
  }

  // ── 核心佇列方法 ────────────────────────────────────────

  /// 分配序號並將訊息加入佇列，按序輸出
  static void _enqueue(String message) {
    final seq = _nextSeq++;
    _pending[seq] = message;
    _flush();
  }

  static void _flush() {
    while (_pending.containsKey(_printSeq)) {
      if (kDebugMode) {
        developer.log(_pending.remove(_printSeq)!);
      }
      _printSeq++;
    }
  }

  // ── 輔助工具 ────────────────────────────────────────────

  static Map<String, String> _getFileInfo({int skipFrames = 1}) {
    final stackTrace = StackTrace.current.toString().split("\n");
    final traceIndex = skipFrames + 2;
    if (traceIndex >= stackTrace.length) {
      return {"file": "unknown", "line": "0"};
    }
    final traceString = stackTrace[traceIndex];
    final fileMatch = RegExp(r"([A-Za-z_]+\.dart)").firstMatch(traceString);
    final fileName = fileMatch?.group(1) ?? "unknown";
    final lineMatch = RegExp(r":(\d+)").firstMatch(traceString);
    final lineNumber = lineMatch?.group(1) ?? "0";
    return {"file": fileName, "line": lineNumber};
  }

  static String _getTimestamp() {
    return DateFormat("HH:mm:ss.SSS").format(DateTime.now());
  }

  static String _formatMessage(
    String message,
    LogLevel level,
    Map<String, String> fileInfo,
  ) {
    final timestamp = _getTimestamp();
    final file = fileInfo["file"] ?? "unknown";
    final line = fileInfo["line"] ?? "0";
    return "${level.emoji} [$timestamp] [${level.prefix}] [$file:$line] $message";
  }

  static void _logLevel(
    String message,
    LogLevel level, {
    StackTrace? stackTrace,
  }) {
    if (!_isDebugMode) return;
    final fileInfo = _getFileInfo(skipFrames: 1);
    final formatted = _formatMessage(message, level, fileInfo);
    final colored = "${level.color}$formatted\x1B[0m";
    _enqueue(colored);
    if (stackTrace != null) _enqueue("Stack Trace:\n$stackTrace");

    _sendRemote({
      "level": level.name,
      "message": message,
      "timestamp": _getTimestamp(),
      "file": fileInfo["file"],
      "line": fileInfo["line"],
      if (stackTrace != null) "stackTrace": stackTrace.toString(),
    });
  }

  // ── 公開 API ────────────────────────────────────────────

  static void log(String message) => _logLevel(message, LogLevel.debug);
  static void info(String message) => _logLevel(message, LogLevel.info);
  static void warning(String message) => _logLevel(message, LogLevel.warning);
  static void success(String message) => _logLevel(message, LogLevel.success);

  static void error(String message, {StackTrace? stackTrace}) {
    _logLevel(message, LogLevel.error, stackTrace: stackTrace);
  }

  static void startGroup(String groupName) {
    if (!_isDebugMode) return;
    final timestamp = _getTimestamp();
    _enqueue(
      "\n════════════════════════════════════════════════\n"
      "🔖 [$timestamp] 【$groupName】\n"
      "════════════════════════════════════════════════\n",
    );
    _sendRemote({
      "type": "group_start",
      "message": groupName,
      "timestamp": timestamp,
    });
  }

  static void endGroup() {
    if (!_isDebugMode) return;
    _enqueue("\n════════════════════════════════════════════════\n");
    _sendRemote({"type": "group_end"});
  }

  static void table(String title, Map<String, dynamic> data) {
    if (!_isDebugMode) return;
    final buffer = StringBuffer();
    buffer.writeln("\n════════════════════════════════════════════════");
    buffer.writeln("🔖 [${_getTimestamp()}] 【$title】");
    buffer.writeln("════════════════════════════════════════════════\n");
    data.forEach((key, value) => buffer.writeln("  📌 $key: $value"));
    buffer.writeln("\n════════════════════════════════════════════════\n");
    _enqueue(buffer.toString());
    _sendRemote({"level": "info", "message": buffer.toString()});
  }

  static void listOutput(String title, List<dynamic> items) {
    if (!_isDebugMode) return;
    final buffer = StringBuffer();
    buffer.writeln("\n════════════════════════════════════════════════");
    buffer.writeln("🔖 [${_getTimestamp()}] 【$title】");
    buffer.writeln("════════════════════════════════════════════════\n");
    for (int i = 0; i < items.length; i++) {
      buffer.writeln("  [$i] ${items[i]}");
    }
    buffer.writeln("\n════════════════════════════════════════════════\n");
    _enqueue(buffer.toString());
    _sendRemote({"level": "info", "message": buffer.toString()});
  }

  static Stopwatch startTimer(String timerName) {
    if (!_isDebugMode) return Stopwatch();
    log("⏱️ 計時開始: $timerName");
    return Stopwatch()..start();
  }

  static void endTimer(Stopwatch stopwatch, String timerName) {
    if (!_isDebugMode) return;
    stopwatch.stop();
    success("⏱️ $timerName 耗時: ${stopwatch.elapsedMilliseconds}ms");
  }

  static void divider({String char = "─", int length = 50}) {
    if (!_isDebugMode) return;
    final line = char * length;
    _enqueue(line);
    _sendRemote({"type": "divider", "message": line});
  }

  static void jsonPretty({
    required String httpMethod,
    required String title,
    required Map<String, dynamic> header,
    required Map<String, dynamic> request,
    required Map<String, dynamic> response,
  }) {
    if (!_isDebugMode) return;
    const encoder = JsonEncoder.withIndent("  ");
    final output =
        "\n\n$httpMethod"
        "\n\n$title\n\n📋 Header:===================\n\n${encoder.convert(header)}"
        "\n\n📋 Request:===================\n\n${encoder.convert(request)}"
        "\n\n📋 Response:===================\n\n${encoder.convert(response)}";
    _enqueue(output);
    _sendRemote({"level": "info", "message": output});
  }
}
