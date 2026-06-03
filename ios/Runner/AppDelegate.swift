import Flutter
import UIKit

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
