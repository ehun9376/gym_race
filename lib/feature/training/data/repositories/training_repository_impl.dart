import "../../../../core/utility/logger.dart";
import "../../../../core/result/default_result.dart";
import "../../../auth/data/services/auth_service.dart";
import "../../domain/repositories/training_repository.dart";
import "../models/voice_log_result.dart";
import "../services/voice_api_service.dart";

/// TrainingRepository 實作。
/// 依 CLAUDE.md：try-catch → 記錄 Logger → 回傳 DefaultResult。
///
/// 流程：確保已登入（匿名/正式皆可）→ 取得 ID Token →
/// 帶 token 呼叫 parseVoiceLog。token 過期(401)時自動刷新重試一次。
class TrainingRepositoryImpl implements TrainingRepository {
  final AuthService _authService;
  final VoiceApiService _apiService;

  TrainingRepositoryImpl({
    required AuthService authService,
    required VoiceApiService apiService,
  })  : _authService = authService,
        _apiService = apiService;

  @override
  Future<DefaultResult<VoiceLogResult>> logByVoice(String text) async {
    try {
      Logger.startGroup("📦 語音紀錄");

      final signIn = await _authService.ensureSignedIn();
      if (!signIn.success) {
        return DefaultResult.fail(message: signIn.message);
      }

      final result = await _callWithToken(text, forceRefresh: false);
      Logger.endGroup();
      return result;
    } catch (e, s) {
      Logger.error("❌ 語音紀錄失敗: $e", stackTrace: s);
      Logger.endGroup();
      return DefaultResult.fail(message: "msg_voice_log_failed");
    }
  }

  Future<DefaultResult<VoiceLogResult>> _callWithToken(
    String text, {
    required bool forceRefresh,
  }) async {
    final tokenResult =
        await _authService.getIdToken(forceRefresh: forceRefresh);
    if (!tokenResult.success || tokenResult.data == null) {
      return DefaultResult.fail(message: tokenResult.message);
    }

    try {
      final data = await _apiService.parseVoiceLog(
        text: text,
        idToken: tokenResult.data!,
      );
      Logger.log("✅ 紀錄成功 ${data.exerciseId} 1RM=${data.oneRmEst}");
      return DefaultResult.ok(data: data, message: "msg_voice_log_success");
    } on VoiceApiException catch (e) {
      // token 過期 → 刷新後重試一次
      if (e.statusCode == 401 && !forceRefresh) {
        Logger.log("Token 過期，刷新後重試");
        return _callWithToken(text, forceRefresh: true);
      }
      return DefaultResult.fail(message: e.message);
    }
  }
}
