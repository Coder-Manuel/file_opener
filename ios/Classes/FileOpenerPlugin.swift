import Flutter
import MobileCoreServices
import UIKit
import UniformTypeIdentifiers

@objc public class SwiftFileOpenerPlugin: NSObject, FlutterPlugin, UIDocumentInteractionControllerDelegate {
  private var documentController: UIDocumentInteractionController?
  private var pendingResult: FlutterResult?

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

    // Store the result callback
    pendingResult = result

    // Create and retain the document controller
    documentController = UIDocumentInteractionController(url: fileURL)
    documentController?.delegate = self

    // Attempt to present the document
    DispatchQueue.main.async { [weak self] in
      guard let self = self,
            let documentController = self.documentController,
            let topViewController = self.topViewController()
      else {
        result(
          FlutterError(
            code: "NO_VIEW_CONTROLLER",
            message: "Could not find top view controller",
            details: nil
          )
        )
        return
      }

      // Try preview first
      if documentController.presentPreview(animated: true) {
        return
      }

      // Try open in menu next
      if documentController.presentOpenInMenu(
        from: topViewController.view.bounds,
        in: topViewController.view,
        animated: true
      ) {
        return
      }

      // Finally try options menu
      if documentController.presentOptionsMenu(
        from: topViewController.view.bounds,
        in: topViewController.view,
        animated: true
      ) {
        return
      }

      self.pendingResult?(
        FlutterError(
          code: "OPEN_FAILED",
          message: "Could not open file with any app",
          details: nil
        )
      )
      self.pendingResult = nil
      self.documentController = nil
    }
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

  func documentInteractionControllerDidEndPreview(_: UIDocumentInteractionController) {
    pendingResult?(nil)
    pendingResult = nil
    documentController = nil
  }

  func documentInteractionController(_: UIDocumentInteractionController, willBeginSendingToApplication _: String?) {
    pendingResult?(nil)
    pendingResult = nil
  }

  func documentInteractionController(_: UIDocumentInteractionController, didEndSendingToApplication _: String?) {
    documentController = nil
  }
}
