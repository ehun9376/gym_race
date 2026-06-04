import AppIntents
import Foundation

// 註：kAppGroupId / kPendingVoiceTextKey 定義在 AppDelegate.swift（同 module 共用）。
// 此檔需在 Xcode 加入 Runner target（Target Membership 打勾）才會被編譯與生效。

/// Siri / 捷徑 喚醒用的 App Intent（iOS 16+）。
///
/// 行為：接收一段語音文字（由 Siri 口述或捷徑輸入）→ 寫入 App Group →
/// 喚醒 App，Flutter 端透過 MethodChannel 取出並送後端 parseVoiceLog。
@available(iOS 16.0, *)
struct RecordWorkoutIntent: AppIntent {
  static var title: LocalizedStringResource = "記錄訓練"
  static var description = IntentDescription("用語音記錄一組健身訓練")

  /// 喚醒 App（讓 Flutter 接手處理）
  static var openAppWhenRun: Bool = true

  /// 語音內容參數。Siri 會用 requestValueDialog 詢問；
  /// 捷徑可把「聽寫文字」接到這個參數。
  @Parameter(
    title: "訓練內容",
    requestValueDialog: "要記錄什麼？例如：槓鈴臥推 60 公斤 6 下 體感 8"
  )
  var phrase: String

  func perform() async throws -> some IntentResult {
    let defaults = UserDefaults(suiteName: kAppGroupId)
    defaults?.set(phrase, forKey: kPendingVoiceTextKey)
    defaults?.synchronize()
    return .result()
  }
}

/// 提供給「捷徑 App」與 Siri 的預設片語。
@available(iOS 16.0, *)
struct GymRaceShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: RecordWorkoutIntent(),
      phrases: [
        "用 \(.applicationName) 記錄訓練",
        "在 \(.applicationName) 記一組",
        "Log a set in \(.applicationName)"
      ],
      shortTitle: "記錄訓練",
      systemImageName: "dumbbell.fill"
    )
  }
}
