import Flutter
import MobileCoreServices
import UIKit
import UniformTypeIdentifiers

public class SwiftFileOpenerPlugin: NSObject, FlutterPlugin, UIDocumentInteractionControllerDelegate {
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
          let filePath = arguments["filePath"] as? String
    else {
      result(
        FlutterError(
          code: "INVALID_ARGUMENTS",
          message: "File path is required",
          details: nil
        )
      )
      return
    }

    let fileURL = URL(fileURLWithPath: filePath)

    // Ensure file exists
    guard FileManager.default.fileExists(atPath: fileURL.path) else {
      result(
        FlutterError(
          code: "FILE_NOT_FOUND",
          message: "File not found at path: \(filePath)",
          details: nil
        )
      )
      return
    }

    // Determine document interaction controller
    let documentController = UIDocumentInteractionController(url: fileURL)
    documentController.delegate = self

    // Attempt to present the document
    DispatchQueue.main.async {
      guard let topViewController = self.topViewController() else {
        result(
          FlutterError(
            code: "NO_VIEW_CONTROLLER",
            message: "Could not find top view controller",
            details: nil
          )
        )
        return
      }

      if documentController.presentOptionsMenu(
        from: topViewController.view.bounds,
        in: topViewController.view,
        animated: true
      ) {
        result(nil)
        return
      }

      // Fallback method if options menu fails
      if documentController.presentOpenInMenu(
        from: topViewController.view.bounds,
        in: topViewController.view,
        animated: true
      ) {
        result(nil)
        return
      }

      result(
        FlutterError(
          code: "OPEN_FAILED",
          message: "Could not open file with any app",
          details: nil
        )
      )
    }

    result(nil)
  }

  // Helper method to find the top view controller
  private func topViewController(controller: UIViewController? = nil) -> UIViewController? {
    let controller = controller ?? UIApplication.shared.keyWindow?.rootViewController

    if let navigationController = controller as? UINavigationController {
      return topViewController(controller: navigationController.visibleViewController)
    }

    if let tabController = controller as? UITabBarController {
      if let selected = tabController.selectedViewController {
        return topViewController(controller: selected)
      }
    }

    if let presented = controller?.presentedViewController {
      return topViewController(controller: presented)
    }

    return controller
  }
}

public extension SwiftFileOpenerPlugin {
  func documentInteractionControllerViewControllerForPreview(_: UIDocumentInteractionController) -> UIViewController {
    return topViewController()!
  }
}
