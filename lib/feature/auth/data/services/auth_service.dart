import "package:firebase_auth/firebase_auth.dart";

import "../../../../core/log/logger.dart";
import "../../../../core/result/default_result.dart";

/// 身分驗證服務（singleton，依 CLAUDE.md：APIService/Service 用 singleton）。
///
/// 規格：
/// - 未登入用戶以「匿名登入」進場，可語音記錄、看 1RM。
/// - 匿名用戶要加入排行榜時，引導綁定（link）為正式帳號，uid 不變、
///   既有 training_logs 自動歸戶。
class AuthService {
  final FirebaseAuth _auth;

  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  bool get isSignedIn => _auth.currentUser != null;

  bool get isAnonymous => _auth.currentUser?.isAnonymous ?? true;

  /// 確保已登入：若尚未登入則自動匿名登入，回傳 uid。
  Future<DefaultResult<String>> ensureSignedIn() async {
    try {
      if (_auth.currentUser == null) {
        Logger.log("AuthService: 執行匿名登入");
        await _auth.signInAnonymously();
      }
      final uid = _auth.currentUser?.uid;
      if (uid == null) {
        return DefaultResult.fail(message: "msg_sign_in_failed");
      }
      return DefaultResult.ok(data: uid);
    } on FirebaseAuthException catch (e, s) {
      Logger.error("❌ 匿名登入失敗", error: e, stackTrace: s);
      return DefaultResult.fail(message: "msg_sign_in_failed");
    }
  }

  /// 取得目前用戶的 Firebase ID Token（呼叫後端 API 用）。
  /// [forceRefresh] 為 true 時強制刷新（token 過期時使用）。
  Future<DefaultResult<String>> getIdToken({
    bool forceRefresh = false,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return DefaultResult.fail(message: "msg_not_signed_in");
      }
      final token = await user.getIdToken(forceRefresh);
      if (token == null) {
        return DefaultResult.fail(message: "msg_token_failed");
      }
      return DefaultResult.ok(data: token);
    } on FirebaseAuthException catch (e, s) {
      Logger.error("❌ 取得 ID Token 失敗", error: e, stackTrace: s);
      return DefaultResult.fail(message: "msg_token_failed");
    }
  }

  /// 匿名升級：將目前匿名帳號綁定為 Email/密碼 正式帳號（uid 不變）。
  /// 用於用戶點「加入排行榜」時引導註冊。
  Future<DefaultResult<String>> linkWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null || !user.isAnonymous) {
        return DefaultResult.fail(message: "msg_link_not_allowed");
      }
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      final result = await user.linkWithCredential(credential);
      Logger.log("AuthService: 匿名升級成功 uid=${result.user?.uid}");
      return DefaultResult.ok(data: result.user?.uid ?? user.uid);
    } on FirebaseAuthException catch (e, s) {
      Logger.error("❌ 帳號綁定失敗", error: e, stackTrace: s);
      // email-already-in-use / credential-already-in-use 等
      return DefaultResult.fail(message: "msg_link_failed");
    }
  }

  /// 綁定既有 OAuth 憑證（例如 Google / Apple），uid 不變。
  Future<DefaultResult<String>> linkWithCredential(
    AuthCredential credential,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null || !user.isAnonymous) {
        return DefaultResult.fail(message: "msg_link_not_allowed");
      }
      final result = await user.linkWithCredential(credential);
      return DefaultResult.ok(data: result.user?.uid ?? user.uid);
    } on FirebaseAuthException catch (e, s) {
      Logger.error("❌ OAuth 綁定失敗", error: e, stackTrace: s);
      return DefaultResult.fail(message: "msg_link_failed");
    }
  }
}
