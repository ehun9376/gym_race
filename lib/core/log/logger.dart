import "dart:developer" as developer;

/// 簡易 Logger（依 CLAUDE.md 日誌規範的精簡版）。
/// 之後若導入 AeroRide 的共用 Logger，可直接替換此檔。
class Logger {
  const Logger._();

  static void startGroup(String name) {
    developer.log("──────── $name ────────");
  }

  static void log(String message) {
    developer.log(message);
  }

  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    developer.log(message, error: error, stackTrace: stackTrace);
  }

  static void endGroup() {
    developer.log("────────────────────────");
  }
}
