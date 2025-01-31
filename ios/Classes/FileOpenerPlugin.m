#import "FileOpenerPlugin.h"
#if __has_include(<file_opener/file_opener-Swift.h>)
#import <file_opener/file_opener-Swift.h>
#else
#import "file_opener-Swift.h"
#endif

@implementation FileOpenerPluginObjC

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftFileOpenerPlugin registerWithRegistrar:registrar];
}

@end