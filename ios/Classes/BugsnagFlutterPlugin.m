#import "BugsnagFlutterPlugin.h"
#import <Bugsnag/Bugsnag.h>

// attachCustomStacktrace is an internal method that can be accessed
// with some objective-c magic
// https://github.com/bugsnag/bugsnag-js/blob/f4e6876b1f3fac8291d1c2918b41804f2403c6ca/packages/react-native/ios/BugsnagReactNative/BugsnagEventDeserializer.m
@interface BugsnagEvent ()
- (void)attachCustomStacktrace:(NSArray *)frames withType:(NSString *)type;
@end

@interface BugsnagFlutterPlugin ()
@property (nonatomic) BOOL configured;
@end

@implementation BugsnagFlutterPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  FlutterMethodChannel* channel = [FlutterMethodChannel
      methodChannelWithName:@"plugins.greenbits.com/bugsnag_flutter"
            binaryMessenger:[registrar messenger]];
  BugsnagFlutterPlugin* instance = [[BugsnagFlutterPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
  if ([@"configure" isEqualToString:call.method]) {
    if (!call.arguments[@"iosApiKey"]) {
      result(@(NO));
      return;
    }

    BugsnagConfiguration *config = [[BugsnagConfiguration alloc] initWithApiKey:call.arguments[@"iosApiKey"]];

    BOOL shouldPersistUser = [call.arguments[@"persistUser"] isEqualToString:@"true"];
    if (shouldPersistUser) {
      config.persistUser = YES;
    }

    if (call.arguments[@"releaseStage"]) {
      config.releaseStage = call.arguments[@"releaseStage"];
    }

    [Bugsnag startWithConfiguration:config];
    self.configured = YES;
    result(@(YES));

  } else if ([@"leaveBreadcrumb" isEqualToString:call.method]) {
    BSGBreadcrumbType type = BSGBreadcrumbTypeManual;

    if (call.arguments[@"type"]) {
      type = [call.arguments[@"type"] intValue];
    }

    if (self.configured) [Bugsnag leaveBreadcrumbWithMessage:call.arguments[@"message"] metadata:nil andType:type];
    result(@(YES));

  } else if ([@"notify" isEqualToString:call.method]) {
    if (!self.configured) {
      result(@(YES));
      return;
    }

    NSException *exception = [NSException exceptionWithName:call.arguments[@"name"]
                                                     reason:call.arguments[@"description"] userInfo:nil];
    [Bugsnag notify:exception block:^BOOL(BugsnagEvent *event) {
      [event attachCustomStacktrace:call.arguments[@"stackTrace"]
                           withType:@"flutter"];
      [event addMetadata:@{@"Full Error": call.arguments[@"fullOutput"]} toSection:@"Flutter"];
      [event addMetadata:@{@"Context": call.arguments[@"context"]} toSection:@"Flutter"];
      if (call.arguments[@"additionalStackTrace"]) {
        [event addMetadata:@{@"StackTrace": call.arguments[@"additionalStackTrace"]} toSection:@"Flutter"];
      }

      return YES;
    }];
    result(@(YES));

  } else if ([@"setUser" isEqualToString:call.method]) {
    if (!self.configured) {
      result(@(YES));
      return;
    }

    NSString *userId = call.arguments[@"id"];
    NSString *email = call.arguments[@"email"];
    NSString *name = call.arguments[@"name"];
    [Bugsnag setUser:userId withEmail:email andName:name];
    result(@(YES));

  } else {
    result(FlutterMethodNotImplemented);
  }
}

@end
