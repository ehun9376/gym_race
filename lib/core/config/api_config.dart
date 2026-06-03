/// 後端 API 設定。對應已部署的 Cloud Functions（asia-east1）。
class ApiConfig {
  const ApiConfig._();

  static const String region = "asia-east1";
  static const String projectId = "voice-fitness-5e822";

  static String get _base =>
      "https://$region-$projectId.cloudfunctions.net";

  /// 語音紀錄解析 API（HTTPS POST）
  static String get parseVoiceLog => "$_base/parseVoiceLog";
}
