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
    // Extract the file path from the arguments.
    guard let arguments = call.arguments as? [String: Any],
          let filePath = arguments["path"] as? String
    else {
      result(FlutterError(code: "INVALID_ARGUMENTS",
                          message: "File path is required",
                          details: nil))
      return
    }

    let fileURL = URL(fileURLWithPath: filePath)

    // Check that the file exists.
    guard FileManager.default.fileExists(atPath: fileURL.path) else {
      result(FlutterError(code: "FILE_NOT_FOUND",
                          message: "File not found at path: \(filePath)",
                          details: nil))
      return
    }

    pendingResult = result

    DispatchQueue.main.async { [weak self] in
      guard let self = self,
            let rootVC = self.topViewController()
      else {
        result(FlutterError(code: "NO_VIEW_CONTROLLER",
                            message: "Could not find view controller",
                            details: nil))
        return
      }

      // Create and configure the UIDocumentInteractionController.
      self.documentController = UIDocumentInteractionController(url: fileURL)
      self.documentController?.delegate = self

      // Set the UTI for the file based on its extension.
      let fileExtension = fileURL.pathExtension
      if #available(iOS 14.0, *) {
        if let utType = UTType(filenameExtension: fileExtension) {
          self.documentController?.uti = utType.identifier
        }
      } else {
        if let utiUnmanaged = UTTypeCreatePreferredIdentifierForTag(
          kUTTagClassFilenameExtension,
          fileExtension as CFString,
          nil
        ) {
          let uti = utiUnmanaged.takeRetainedValue() as String
          self.documentController?.uti = uti
        }
      }

      // Try to present a preview. If the file cannot be previewed, fall back to the options menu.
      if self.documentController!.presentPreview(animated: true) == false {
        self.documentController?.presentOptionsMenu(
          from: rootVC.view.bounds,
          in: rootVC.view,
          animated: true
        )
      }
    }
  }

  // MARK: - UIDocumentInteractionControllerDelegate

  public func documentInteractionControllerViewControllerForPreview(_: UIDocumentInteractionController) -> UIViewController {
    // Return the top-most view controller.
    return topViewController() ?? UIApplication.shared.keyWindow!.rootViewController!
  }

  public func documentInteractionControllerDidEndPreview(_: UIDocumentInteractionController) {
    // When the preview is dismissed, return success.
    pendingResult?(true)
    cleanup()
  }

  // Call this when you’re done with the document controller.
  private func cleanup() {
    documentController = nil
    pendingResult = nil
  }

  // Helper method to find the top view controller.
  private func topViewController(controller: UIViewController? = nil) -> UIViewController? {
    let controller = controller ?? UIApplication.shared.keyWindow?.rootViewController

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
