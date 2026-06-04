/// parseVoiceLog 回傳的解析結果（依 CLAUDE.md Model 規範：
/// 屬性非 optional、fromJson 用 optional 轉換 + 預設值）。
class VoiceLogResult {
  final String logId;
  final String parsedBy; // "regex" | "gemini"
  final String exerciseId;
  final double weight;
  final int reps;
  final double rpe;
  final double oneRmEst;

  VoiceLogResult({
    required this.logId,
    required this.parsedBy,
    required this.exerciseId,
    required this.weight,
    required this.reps,
    required this.rpe,
    required this.oneRmEst,
  });

  factory VoiceLogResult.fromJson(Map<String, dynamic> json) {
    final data = (json["data"] as Map<String, dynamic>?) ?? {};
    return VoiceLogResult(
      // 後端改 Postgres 後 log_id 為數字(bigserial)，用 toString 同時相容字串/數字
      logId: json["log_id"]?.toString() ?? "",
      parsedBy: json["parsed_by"] as String? ?? "",
      exerciseId: data["exercise_id"] as String? ?? "",
      weight: (data["weight"] as num?)?.toDouble() ?? 0.0,
      reps: (data["reps"] as num?)?.toInt() ?? 0,
      rpe: (data["rpe"] as num?)?.toDouble() ?? 0.0,
      oneRmEst: (data["one_rm_est"] as num?)?.toDouble() ?? 0.0,
    );
  }
}
