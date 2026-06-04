import "voice_log_result.dart";

/// 本機快取用的訓練紀錄項目。
///
/// A 方案（伺服器為主 + 本機快取）：每次成功記錄後，把結果存一份在手機，
/// 讓匿名用戶下次開 App 不需連線也能立即看到過往紀錄（伺服器仍為真實來源）。
class TrainingLogEntry {
  final String logId;
  final String exerciseId;
  final double weight;
  final int reps;
  final double rpe;
  final double oneRmEst;
  final String parsedBy;

  /// 本機記錄時間（毫秒）。供排序與顯示。
  final int recordedAtMillis;

  TrainingLogEntry({
    required this.logId,
    required this.exerciseId,
    required this.weight,
    required this.reps,
    required this.rpe,
    required this.oneRmEst,
    required this.parsedBy,
    required this.recordedAtMillis,
  });

  /// 由 API 回傳結果建立本機項目。
  factory TrainingLogEntry.fromResult(
    VoiceLogResult result,
    int recordedAtMillis,
  ) {
    return TrainingLogEntry(
      logId: result.logId,
      exerciseId: result.exerciseId,
      weight: result.weight,
      reps: result.reps,
      rpe: result.rpe,
      oneRmEst: result.oneRmEst,
      parsedBy: result.parsedBy,
      recordedAtMillis: recordedAtMillis,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "log_id": logId,
      "exercise_id": exerciseId,
      "weight": weight,
      "reps": reps,
      "rpe": rpe,
      "one_rm_est": oneRmEst,
      "parsed_by": parsedBy,
      "recorded_at": recordedAtMillis,
    };
  }

  factory TrainingLogEntry.fromJson(Map<String, dynamic> json) {
    return TrainingLogEntry(
      logId: json["log_id"]?.toString() ?? "",
      exerciseId: json["exercise_id"] as String? ?? "",
      weight: (json["weight"] as num?)?.toDouble() ?? 0.0,
      reps: (json["reps"] as num?)?.toInt() ?? 0,
      rpe: (json["rpe"] as num?)?.toDouble() ?? 0.0,
      oneRmEst: (json["one_rm_est"] as num?)?.toDouble() ?? 0.0,
      parsedBy: json["parsed_by"] as String? ?? "",
      recordedAtMillis: (json["recorded_at"] as num?)?.toInt() ?? 0,
    );
  }
}
