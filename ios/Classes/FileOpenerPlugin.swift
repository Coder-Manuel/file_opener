import Flutter
import MobileCoreServices
import UIKit
import UniformTypeIdentifiers

@objc public class SwiftFileOpenerPlugin: NSObject, FlutterPlugin, UIDocumentInteractionControllerDelegate {
  private var documentController: UIDocumentInteractionController?
  private var pendingResult: FlutterResult?

  private var rootViewController: UIViewController? {
    return UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.rootViewController
  }

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "file_opener", binaryMessenger: registrar.messenger())
    let instance = SwiftFileOpenerPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      result("iOS " + UIDevice.current.systemVersion)
    case "openFile":
      openFile(call: call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func openFile(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let arguments = call.arguments as? [String: Any],
          let filePath = arguments["path"] as? String
    else {
      result(FlutterError(code: "INVALID_ARGUMENTS", message: "File path is required", details: nil))
      return
    }

    let fileURL = URL(fileURLWithPath: filePath)

    guard FileManager.default.fileExists(atPath: fileURL.path) else {
      result(FlutterError(code: "FILE_NOT_FOUND", message: "File not found at path: \(filePath)", details: nil))
      return
    }

    pendingResult = result

    DispatchQueue.main.async { [weak self] in
      guard let strongSelf = self, let rootVC = strongSelf.topViewController() else {
        result(FlutterError(code: "NO_VIEW_CONTROLLER", message: "Could not find view controller", details: nil))
        return
      }

      strongSelf.documentController = UIDocumentInteractionController(url: fileURL)
      strongSelf.documentController?.delegate = strongSelf

      if #available(iOS 14.0, *) {
        strongSelf.documentController?.uti = UTType(filenameExtension: fileURL.pathExtension)?.identifier ?? "public.data"
      } else {
        strongSelf.documentController?.uti = "public.data"
      }

      let rect = CGRect(x: rootVC.view.bounds.midX, y: rootVC.view.bounds.midY, width: 0, height: 0)

      if !(strongSelf.documentController?.presentOptionsMenu(from: rect, in: rootVC.view, animated: true) ?? false) {
        result(FlutterError(code: "PRESENTATION_ERROR", message: "Could not present file options", details: nil))
        strongSelf.cleanup()
      }
    }
  }

  private func cleanup() {
    documentController = nil
    pendingResult = nil
  }

  private func topViewController(controller: UIViewController? = nil) -> UIViewController? {
    let controller = controller ?? UIApplication.shared.windows.first(where: { $0.isKeyWindow })?.rootViewController

    if let navigationController = controller as? UINavigationController {
      return topViewController(controller: navigationController.visibleViewController)
    }

    if let tabController = controller as? UITabBarController, let selected = tabController.selectedViewController {
      return topViewController(controller: selected)
    }

    if let presented = controller?.presentedViewController {
      return topViewController(controller: presented)
    }

    return controller
  }
}

// MARK: - UIDocumentInteractionControllerDelegate

public extension SwiftFileOpenerPlugin {
  func documentInteractionControllerViewControllerForPreview(_: UIDocumentInteractionController) -> UIViewController {
    return topViewController() ?? UIViewController()
  }

  func documentInteractionController(_: UIDocumentInteractionController, willBeginSendingToApplication _: String?) {
    pendingResult?(nil)
    cleanup()
  }

  func documentInteractionControllerDidDismissOptionsMenu(_: UIDocumentInteractionController) {
    pendingResult?(nil)
    cleanup()
  }

  func documentInteractionControllerDidDismissOpenInMenu(_: UIDocumentInteractionController) {
    pendingResult?(nil)
    cleanup()
  }

  func documentInteractionController(_: UIDocumentInteractionController, didEndSendingToApplication _: String?) {
    cleanup()
  }
}
