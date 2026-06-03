import "../../../../core/result/default_result.dart";
import "../../data/models/voice_log_result.dart";
import "../repositories/training_repository.dart";

/// 語音紀錄 UseCase。
/// 依 CLAUDE.md：UseCase 只驗證輸入、無 try-catch，直接回傳 Repository 結果。
class LogVoiceUseCase {
  final TrainingRepository _repository;

  LogVoiceUseCase(this._repository);

  Future<DefaultResult<VoiceLogResult>> call(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return Future.value(
        DefaultResult.fail(message: "msg_voice_text_empty"),
      );
    }
    return _repository.logByVoice(trimmed);
  }
}
