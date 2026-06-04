import "dart:convert";

import "package:shared_preferences/shared_preferences.dart";

import "../../../../core/utility/logger.dart";
import "../models/training_log_entry.dart";

/// 訓練紀錄的本機快取（shared_preferences），singleton。
///
/// A 方案：伺服器為真實來源，本機保留一份供離線/秒開。
/// 以「uid」分區存放（key = `training_logs_<uid>`），所以同台手機切換
/// 不同匿名/正式帳號不會互相污染；同一匿名 uid 重開 App 仍讀得到。
class LocalLogCache {
  static const String _prefix = "training_logs_";

  /// 每位使用者最多保留的本機筆數（避免無限膨脹）。
  static const int _maxEntries = 100;

  String _keyFor(String uid) => "$_prefix$uid";

  /// 讀取某 uid 的全部本機紀錄（新到舊）。
  Future<List<TrainingLogEntry>> getAll(String uid) async {
    if (uid.isEmpty) {
      return [];
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keyFor(uid));
      if (raw == null || raw.isEmpty) {
        return [];
      }
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => TrainingLogEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e, s) {
      Logger.error("❌ 讀取本機紀錄失敗: $e", stackTrace: s);
      return [];
    }
  }

  /// 新增一筆到最前面，回傳更新後的清單（已截斷至上限）。
  Future<List<TrainingLogEntry>> append(
    String uid,
    TrainingLogEntry entry,
  ) async {
    final current = await getAll(uid);
    final updated = [entry, ...current];
    if (updated.length > _maxEntries) {
      updated.removeRange(_maxEntries, updated.length);
    }
    await _save(uid, updated);
    return updated;
  }

  Future<void> _save(String uid, List<TrainingLogEntry> entries) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(entries.map((e) => e.toJson()).toList());
      await prefs.setString(_keyFor(uid), raw);
    } catch (e, s) {
      Logger.error("❌ 寫入本機紀錄失敗: $e", stackTrace: s);
    }
  }
}
