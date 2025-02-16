#import "FileOpenerPlugin.h"

@interface FileOpenerPlugin () <UIDocumentInteractionControllerDelegate>
@end

static NSString *const CHANNEL_NAME = @"file_opener";

// Returns the root view controller of the app,
// or nil if the app has no root view controller.
static UIViewController *RootViewController() {
  // If the app is running on iOS 13 or higher, then use the new
  // `connectedScenes` API to get the root view controller of the key window.
  if (@available(iOS 13, *)) {
    // Get a list of all the connected scenes in the app.
    NSSet *scenes = [[UIApplication sharedApplication] connectedScenes];
    // Iterate over the scenes and check if each one is a UIWindowScene.
    for (UIScene *scene in scenes) {
      if ([scene isKindOfClass:[UIWindowScene class]]) {
        // Get a list of all the windows in the scene.
        NSArray *windows = ((UIWindowScene *)scene).windows;
        // Iterate over the windows and check if each one is the key window.
        for (UIWindow *window in windows) {
          if (window.isKeyWindow) {
            // Return the root view controller of the key window.
            return window.rootViewController;
          }
        }
      }
    }
    // If we couldn't find a key window, then return nil.
    return nil;
  } else {
    // Simply return the root view controller of the key window.
    return [UIApplication sharedApplication].keyWindow.rootViewController;
  }
}

// Returns the top view controller in a view controller hierarchy.
static UIViewController *
TopViewControllerForViewController(UIViewController *viewController) {
  // If the view controller has a presented view controller, then return the top
  // view controller in that hierarchy.
  if (viewController.presentedViewController) {
    return TopViewControllerForViewController(
        viewController.presentedViewController);
  }
  // If the view controller is a navigation controller, then return the top
  // view controller in the navigation controller's stack.
  if ([viewController isKindOfClass:[UINavigationController class]]) {
    return TopViewControllerForViewController(
        ((UINavigationController *)viewController).visibleViewController);
  }
  // Otherwise, return the given view controller.
  return viewController;
}

@implementation FileOpenerPlugin {
  FlutterResult _result;
  UIViewController *_viewController;
  UIDocumentInteractionController *_documentController;
  UIDocumentInteractionController *_interactionController;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  FlutterMethodChannel *channel =
      [FlutterMethodChannel methodChannelWithName:CHANNEL_NAME
                                  binaryMessenger:[registrar messenger]];
  UIViewController *rootViewController = RootViewController();
  UIViewController *viewController =
      TopViewControllerForViewController(rootViewController);
  FileOpenerPlugin *instance =
      [[FileOpenerPlugin alloc] initWithViewController:viewController];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (instancetype)initWithViewController:(UIViewController *)viewController {
  self = [super init];
  if (self) {
    _viewController = viewController;
  }
  return self;
}

- (void)handleMethodCall:(FlutterMethodCall *)call
                  result:(FlutterResult)result {
  if ([call.method isEqualToString:@"getPlatformVersion"]) {
    // Return the iOS version string
    NSString *systemVersion = [[UIDevice currentDevice] systemVersion];
    NSDictionary *dict = @{
      @"platform" : @"iOS",
      @"version" : systemVersion
    };
    result(dict);
  } else if ([call.method isEqualToString:@"openFile"]) {
    _result = result;
    NSString *msg = call.arguments[@"path"];
    if (msg == nil) {
      NSDictionary *dict = @{
        @"type" : @4,
        @"message" : @"INVALID_PATH: File path cannot be null"
      };
      result(dict);
      return;
    }
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL fileExist = [fileManager fileExistsAtPath:msg];
    if (fileExist) {
      _documentController = [UIDocumentInteractionController
          interactionControllerWithURL:[NSURL fileURLWithPath:msg]];
      _documentController.delegate = self;
      NSString *uti = call.arguments[@"uti"];
      BOOL isBlank = [self isBlankString:uti];
      if (!isBlank) {
        _documentController.UTI = uti;
      }
      @try {
        BOOL previewSucceeded =
            [_documentController presentPreviewAnimated:YES];
        if (@available(iOS 18.0, *)) {
          sleep(1);
        }
        if (!previewSucceeded) {
          UIViewController *rootViewController = RootViewController();
          UIViewController *viewController =
              TopViewControllerForViewController(rootViewController);
          [_documentController
              presentOpenInMenuFromRect:CGRectMake(500, 20, 100, 100)
                                 inView:viewController.view
                               animated:YES];
        }
      } @catch (NSException *exception) {
        NSDictionary *dict = @{
          @"type" : @1,
          @"message" : @"OPEN_FAILED: File opened incorrectly."
        };
        result(dict);
      }
    } else {
      NSDictionary *dict = @{
        @"type" : @2,
        @"message" : @"FILE_NOT_FOUND: File does not exist or is not readable"
      };
      result(dict);
    }
  } else {
    result(FlutterMethodNotImplemented);
  }
}

- (void)documentInteractionControllerDidEndPreview:
    (UIDocumentInteractionController *)controller {
  NSDictionary *dict = @{@"type" : @0, @"message" : @"done"};
  _result(dict);
}

- (void)documentInteractionControllerDidDismissOpenInMenu:
    (UIDocumentInteractionController *)controller {
  NSDictionary *dict = @{@"type" : @0, @"message" : @"done"};
  _result(dict);
}

- (UIViewController *)documentInteractionControllerViewControllerForPreview:
    (UIDocumentInteractionController *)controller {
  UIViewController *rootViewController = RootViewController();
  UIViewController *viewController =
      TopViewControllerForViewController(rootViewController);
  return viewController;
}

- (BOOL)isBlankString:(NSString *)string {
  if (string == nil || string == NULL) {
    return YES;
  }
  if ([string isKindOfClass:[NSNull class]]) {
    return YES;
  }
  if ([[string stringByTrimmingCharactersInSet:[NSCharacterSet
                                                   whitespaceCharacterSet]]
          length] == 0) {
    return YES;
  }
  return NO;
}
@end