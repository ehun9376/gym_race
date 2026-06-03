import "../../../../core/result/default_result.dart";
import "../../data/models/voice_log_result.dart";

/// 訓練紀錄 Repository（抽象）。
abstract class TrainingRepository {
  /// 送出語音文字進行解析與紀錄。
  Future<DefaultResult<VoiceLogResult>> logByVoice(String text);
}
