import "package:flutter/services.dart";

import "../../../../core/log/logger.dart";

/// 與 iOS 原生 App Intent / 捷徑 溝通的 MethodChannel。
/// App 被 Siri/捷徑 喚醒後，呼叫此處取出待處理的語音文字。
class VoiceIntentChannel {
  static const MethodChannel _channel = MethodChannel("gym_race/voice");

  const VoiceIntentChannel._();

  /// 取出 iOS 端（App Group）暫存的語音文字；無則回傳 null。
  /// 取出後原生端會自動清除，避免重複處理。
  static Future<String?> getPendingVoiceText() async {
    try {
      final text =
          await _channel.invokeMethod<String>("getPendingVoiceText");
      if (text == null || text.trim().isEmpty) {
        return null;
      }
      Logger.log("收到捷徑語音文字：$text");
      return text;
    } on PlatformException catch (e, s) {
      Logger.error("❌ 讀取捷徑語音文字失敗", error: e, stackTrace: s);
      return null;
    } on MissingPluginException {
      // 非 iOS 或尚未實作該平台
      return null;
    }
  }
}
