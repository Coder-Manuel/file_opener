import Flutter
import MobileCoreServices
import UIKit
import UniformTypeIdentifiers

public class FileOpenerPlugin: NSObject, FlutterPlugin {
  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "file_opener", binaryMessenger: registrar.messenger())
    let instance = FileOpenerPlugin()
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
      result(FlutterError(code: "INVALID_ARGUMENTS",
                          message: "File path is required",
                          details: nil))
      return
    }

    let fileURL = URL(fileURLWithPath: filePath)

    // Ensure file exists
    guard FileManager.default.fileExists(atPath: fileURL.path) else {
      throw NSError(domain: "FileOpenerPlugin",
                    code: 404,
                    userInfo: [NSLocalizedDescriptionKey: "File not found"])
    }

    // Determine document interaction controller
    let documentController = UIDocumentInteractionController(url: fileURL)
    documentController.delegate = self

    // Attempt to present the document
    DispatchQueue.main.async {
      guard let topViewController = self.topViewController() else {
        result(FlutterError(code: "NO_VIEW_CONTROLLER",
                            message: "Could not find top view controller",
                            details: nil))
        return
      }

      let presentSuccess = documentController.presentOptionsMenu(
        from: topViewController.view.bounds,
        in: topViewController.view,
        animated: true
      )

      if !presentSuccess {
        // Fallback method if options menu fails
        let openSuccess = documentController.presentOpenInMenu(
          from: topViewController.view.bounds,
          in: topViewController.view,
          animated: true
        )

        if !openSuccess {
          result(FlutterError(code: "OPEN_FAILED",
                              message: "Could not open file with any app",
                              details: nil))
        }
      }
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

// MARK: - UIDocumentInteractionControllerDelegate

extension FileOpenerPlugin: UIDocumentInteractionControllerDelegate {
  public func documentInteractionControllerViewControllerForPreview(_: UIDocumentInteractionController) -> UIViewController {
    return topViewController()!
  }
}
