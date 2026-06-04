import "package:speech_to_text/speech_to_text.dart";

import "../../../../core/utility/logger.dart";

/// 行動裝置原生 STT（語音轉文字）服務，singleton。
/// 預設辨識繁體中文（zh-TW），辨識結果回拋給上層送 parseVoiceLog。
class SpeechService {
  final SpeechToText _speech;
  bool _available = false;

  SpeechService({SpeechToText? speech}) : _speech = speech ?? SpeechToText();

  bool get isListening => _speech.isListening;

  /// 初始化並要求麥克風/語音辨識權限。回傳是否可用。
  Future<bool> initialize() async {
    try {
      _available = await _speech.initialize(
        onError: (e) => Logger.error("❌ STT error: ${e.errorMsg}"),
        onStatus: (s) => Logger.log("STT status: $s"),
      );
      return _available;
    } catch (e, s) {
      Logger.error("❌ STT 初始化失敗: $e", stackTrace: s);
      return false;
    }
  }

  /// 開始聆聽。[onResult] 會在辨識過程中多次回拋目前文字；
  /// [onFinal] 在本次辨識結束時回拋最終文字。
  Future<void> startListening({
    required void Function(String text) onResult,
    required void Function(String text) onFinal,
  }) async {
    if (!_available) {
      _available = await initialize();
      if (!_available) {
        return;
      }
    }
    await _speech.listen(
      listenOptions: SpeechListenOptions(
        partialResults: true,
        localeId: "zh-TW",
      ),
      onResult: (result) {
        onResult(result.recognizedWords);
        if (result.finalResult) {
          onFinal(result.recognizedWords);
        }
      },
    );
  }

  Future<void> stop() async {
    await _speech.stop();
  }
}
