/// 統一的回傳格式（依 CLAUDE.md 異常處理規範）。
///
/// Repository 一律回傳 DefaultResult；ViewModel 檢查 success 後
/// 透過 SnackBar 顯示 message。
class DefaultResult<T> {
  final bool success;
  final String message;
  final T? data;

  DefaultResult({
    required this.success,
    this.message = "",
    this.data,
  });

  factory DefaultResult.ok({T? data, String message = "msg_success"}) {
    return DefaultResult(success: true, message: message, data: data);
  }

  factory DefaultResult.fail({String message = "msg_unknown_error"}) {
    return DefaultResult(success: false, message: message);
  }
}
