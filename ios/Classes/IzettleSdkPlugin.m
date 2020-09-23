#import "IzettleSdkPlugin.h"
#if __has_include(<izettle_sdk/izettle_sdk-Swift.h>)
#import <izettle_sdk/izettle_sdk-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "izettle_sdk-Swift.h"
#endif

#import "iZettleSDK/iZettleSDK-Swift.h"

@implementation IzettleSdkPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftIzettleSdkPlugin registerWithRegistrar:registrar];
}
@end
