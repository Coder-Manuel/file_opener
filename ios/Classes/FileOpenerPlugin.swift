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
    print("SwiftFileOpenerPlugin registered")
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getPlatformVersion":
      let version = "iOS " + UIDevice.current.systemVersion
      print("getPlatformVersion called: \(version)")
      result(version)
    case "openFile":
      print("openFile called")
      openFile(call: call, result: result)
    default:
      print("Method not implemented: \(call.method)")
      result(FlutterMethodNotImplemented)
    }
  }

  private func openFile(call: FlutterMethodCall, result: @escaping FlutterResult) {
    // Extract file path argument.
    guard let arguments = call.arguments as? [String: Any],
          let filePath = arguments["path"] as? String
    else {
      print("Invalid arguments: file path not provided")
      result(FlutterError(code: "INVALID_ARGUMENTS",
                          message: "File path is required",
                          details: nil))
      return
    }

    let fileURL = URL(fileURLWithPath: filePath)
    print("Attempting to open file at path: \(fileURL.path)")

    // Check file existence.
    guard FileManager.default.fileExists(atPath: fileURL.path) else {
      print("File not found at path: \(fileURL.path)")
      result(FlutterError(code: "FILE_NOT_FOUND",
                          message: "File not found at path: \(filePath)",
                          details: nil))
      return
    }

    // Log file attributes for debugging.
    do {
      let attributes = try FileManager.default.attributesOfItem(atPath: fileURL.path)
      print("File attributes: \(attributes)")
    } catch {
      print("Could not get file attributes: \(error.localizedDescription)")
    }

    pendingResult = result

    DispatchQueue.main.async { [weak self] in
      guard let self = self,
            let rootVC = self.topViewController()
      else {
        print("No root view controller found")
        result(FlutterError(code: "NO_VIEW_CONTROLLER",
                            message: "Could not find view controller",
                            details: nil))
        return
      }

      print("Creating UIDocumentInteractionController for file: \(fileURL)")
      self.documentController = UIDocumentInteractionController(url: fileURL)
      self.documentController?.delegate = self

      // Determine the UTI based on file extension.
      let fileExtension = fileURL.pathExtension.lowercased()
      print("File extension: \(fileExtension)")
      var uti: String?

      if #available(iOS 14.0, *) {
        if let utType = UTType(filenameExtension: fileExtension) {
          uti = utType.identifier
          print("Determined UTI using UTType: \(uti!)")
        } else {
          print("Could not determine UTI using UTType for extension: \(fileExtension)")
        }
      } else {
        if let utiUnmanaged = UTTypeCreatePreferredIdentifierForTag(
          kUTTagClassFilenameExtension,
          fileExtension as CFString,
          nil
        ) {
          uti = utiUnmanaged.takeRetainedValue() as String
          print("Determined UTI using UTTypeCreatePreferredIdentifierForTag: \(uti!)")
        } else {
          print("Could not determine UTI using UTTypeCreatePreferredIdentifierForTag for extension: \(fileExtension)")
        }
      }

      // For PDFs, explicitly set the UTI.
      if fileExtension == "pdf" {
        uti = "com.adobe.pdf"
        print("Overriding UTI to: \(uti!) for PDF")
      }

      if let uti = uti {
        self.documentController?.uti = uti
      } else {
        print("Warning: UTI is nil")
      }

      // Attempt to present a preview.
      if self.documentController!.presentPreview(animated: true) {
        print("Presented file preview successfully.")
      } else {
        print("Preview unavailable; presenting options menu instead.")
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
    let vc = topViewController() ?? UIApplication.shared.keyWindow!.rootViewController!
    print("documentInteractionControllerViewControllerForPreview returning: \(vc)")
    return vc
  }

  public func documentInteractionControllerDidEndPreview(_: UIDocumentInteractionController) {
    print("Document preview ended.")
    pendingResult?(true)
    cleanup()
  }

  // When the options menu is dismissed or an action is completed.
  public func documentInteractionController(_: UIDocumentInteractionController, didEndSendingToApplication application: String?) {
    print("Finished sending to application: \(application ?? "unknown")")
    pendingResult?(true)
    cleanup()
  }

  private func cleanup() {
    print("Cleaning up document controller and pending result.")
    documentController = nil
    pendingResult = nil
  }

  // Helper method to get the top view controller.
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
