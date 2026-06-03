import "dart:convert";

import "package:http/http.dart" as http;

import "../../../../core/config/api_config.dart";
import "../../../../core/log/logger.dart";
import "../models/voice_log_result.dart";

/// 呼叫後端 parseVoiceLog 的 API 服務（singleton）。
/// 僅負責 HTTP 通訊與序列化；身分 token 由上層（Repository）帶入。
class VoiceApiService {
  final http.Client _client;

  VoiceApiService({http.Client? client}) : _client = client ?? http.Client();

  /// 送出語音文字 + ID Token，回傳解析結果。
  /// 拋出 [VoiceApiException] 讓 Repository 統一轉成 DefaultResult。
  Future<VoiceLogResult> parseVoiceLog({
    required String text,
    required String idToken,
  }) async {
    final uri = Uri.parse(ApiConfig.parseVoiceLog);

    final response = await _client.post(
      uri,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $idToken",
      },
      body: jsonEncode({"text": text}),
    );

    final body = _decode(response.body);

    if (response.statusCode == 200 && body["success"] == true) {
      return VoiceLogResult.fromJson(body);
    }

    final message = body["message"] as String? ?? "解析失敗";
    Logger.error("❌ parseVoiceLog ${response.statusCode}: $message");
    throw VoiceApiException(
      statusCode: response.statusCode,
      message: message,
    );
  }

  Map<String, dynamic> _decode(String raw) {
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}

/// API 例外，攜帶 HTTP 狀態碼供上層判斷（例如 422 解析失敗、404 找不到動作）。
class VoiceApiException implements Exception {
  final int statusCode;
  final String message;

  VoiceApiException({required this.statusCode, required this.message});

  @override
  String toString() => "VoiceApiException($statusCode): $message";
}
