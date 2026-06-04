import "package:flutter/foundation.dart";

import "../../../auth/data/services/auth_service.dart";
import "../../data/models/training_log_entry.dart";
import "../../data/models/voice_log_result.dart";
import "../../data/services/local_log_cache.dart";
import "../../domain/usecases/log_voice_usecase.dart";

/// 語音紀錄 ViewModel（繼承 ChangeNotifier，依 CLAUDE.md ViewModel 規範）。
class VoiceRecordViewModel extends ChangeNotifier {
  final LogVoiceUseCase _logVoiceUseCase;
  final AuthService _authService;
  final LocalLogCache _localCache;

  VoiceRecordViewModel(
    this._logVoiceUseCase,
    this._authService,
    this._localCache,
  );

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

  // 本機歷史紀錄（A 方案：伺服器為主、手機快取一份供秒開/離線）。
  List<TrainingLogEntry> _history = [];
  List<TrainingLogEntry> get history => _history;
  set history(List<TrainingLogEntry> value) {
    _history = value;
    notifyListeners();
  }

  /// 載入目前 uid 的本機歷史（進頁面時呼叫）。
  Future<void> loadHistory() async {
    final uid = _authService.currentUser?.uid;
    if (uid == null) {
      return;
    }
    history = await _localCache.getAll(uid);
  }

  /// 送出語音文字（來自前端 STT 或 iOS 捷徑）。
  Future<void> submitVoiceText(String text) async {
    isLoading = true;
    final result = await _logVoiceUseCase(text);
    isLoading = false;

    message = result.message;
    if (result.success && result.data != null) {
      lastResult = result.data;
      await _cacheResult(result.data!);
    }
    // 實際專案中於此透過 AppViewModel.showSnackBar(result.message) 顯示。
  }

  /// 成功後寫入本機快取並更新歷史清單。
  Future<void> _cacheResult(VoiceLogResult result) async {
    final uid = _authService.currentUser?.uid;
    if (uid == null) {
      return;
    }
    final entry = TrainingLogEntry.fromResult(
      result,
      DateTime.now().millisecondsSinceEpoch,
    );
    history = await _localCache.append(uid, entry);
  }
}
