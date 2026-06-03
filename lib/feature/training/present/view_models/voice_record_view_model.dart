import "package:flutter/foundation.dart";

import "../../data/models/voice_log_result.dart";
import "../../domain/usecases/log_voice_usecase.dart";

/// 語音紀錄 ViewModel（繼承 ChangeNotifier，依 CLAUDE.md ViewModel 規範）。
class VoiceRecordViewModel extends ChangeNotifier {
  final LogVoiceUseCase _logVoiceUseCase;

  VoiceRecordViewModel(this._logVoiceUseCase);

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  set isLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  VoiceLogResult? _lastResult;
  VoiceLogResult? get lastResult => _lastResult;
  set lastResult(VoiceLogResult? value) {
    _lastResult = value;
    notifyListeners();
  }

  String _message = "";
  String get message => _message;
  set message(String value) {
    _message = value;
    notifyListeners();
  }

  /// 送出語音文字（來自前端 STT 或 iOS 捷徑）。
  Future<void> submitVoiceText(String text) async {
    isLoading = true;
    final result = await _logVoiceUseCase(text);
    isLoading = false;

    message = result.message;
    if (result.success) {
      lastResult = result.data;
    }
    // 實際專案中於此透過 AppViewModel.showSnackBar(result.message) 顯示。
  }
}
