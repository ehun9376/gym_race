import Flutter
import UIKit

/// App Group + 暫存 key：在「捷徑/App Intent」與「Flutter App」間傳遞語音文字。
/// 定義在此（必在 Runner target 內），RecordWorkoutIntent.swift 加入 target 後共用。
/// 需在 Xcode → Signing & Capabilities 為 Runner 加上 App Group：group.com.vipcart.gymRace
let kAppGroupId = "group.com.vipcart.gymRace"
let kPendingVoiceTextKey = "pending_voice_text"

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let voiceChannelName = "gym_race/voice"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // MethodChannel：讓 Flutter 取出 App Intent / 捷徑 寫入的語音文字。
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: voiceChannelName,
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { call, result in
        switch call.method {
        case "getPendingVoiceText":
          let defaults = UserDefaults(suiteName: kAppGroupId)
          let text = defaults?.string(forKey: kPendingVoiceTextKey)
          // 取出後清掉，避免重複處理
          defaults?.removeObject(forKey: kPendingVoiceTextKey)
          result(text)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
