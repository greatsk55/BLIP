import Flutter
import UIKit
import AudioToolbox

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var screenshotChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      // MethodChannel: 스크린샷 감지
      screenshotChannel = FlutterMethodChannel(
        name: "com.bakkum.blip/screenshot",
        binaryMessenger: controller.binaryMessenger
      )

      // MethodChannel: 시스템 사운드 (WebRTC 오디오 세션 간섭 없음)
      let audioChannel = FlutterMethodChannel(
        name: "com.bakkum.blip/audio",
        binaryMessenger: controller.binaryMessenger
      )
      audioChannel.setMethodCallHandler { (call, result) in
        if call.method == "playBeep" {
          AudioServicesPlaySystemSound(1057)
          result(nil)
        } else {
          result(FlutterMethodNotImplemented)
        }
      }
    }

    // 스크린샷 감지 (사후 알림)
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(didTakeScreenshot),
      name: UIApplication.userDidTakeScreenshotNotification,
      object: nil
    )

    // 화면 녹화 감지
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(screenCaptureChanged),
      name: UIScreen.capturedDidChangeNotification,
      object: nil
    )

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  @objc private func didTakeScreenshot() {
    screenshotChannel?.invokeMethod("onScreenshot", arguments: nil)
  }

  @objc private func screenCaptureChanged() {
    let isCaptured = UIScreen.main.isCaptured
    screenshotChannel?.invokeMethod("onScreenRecording", arguments: isCaptured)
  }
}
