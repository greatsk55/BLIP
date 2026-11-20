import Flutter
import UIKit
import AudioToolbox

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var screenshotChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
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

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let messenger = engineBridge.applicationRegistrar.messenger()
    screenshotChannel = FlutterMethodChannel(
      name: "com.bakkum.blip/screenshot",
      binaryMessenger: messenger
    )
    let audioChannel = FlutterMethodChannel(
      name: "com.bakkum.blip/audio",
      binaryMessenger: messenger
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

  @objc private func didTakeScreenshot() {
    screenshotChannel?.invokeMethod("onScreenshot", arguments: nil)
  }

  @objc private func screenCaptureChanged() {
    let isCaptured = UIScreen.main.isCaptured
    screenshotChannel?.invokeMethod("onScreenRecording", arguments: isCaptured)
  }
}
