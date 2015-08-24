//
//  FlurryLaunchOrigin.m
//  OriginDemo
//
//  Copyright 2015, Yahoo Inc.
//  Copyrights licensed under the MIT License.
//  See the accompanying LICENSE file for terms.
//

#import <objc/message.h>
#import <objc/runtime.h>

#import "FlurryLaunchOrigin.h"

#pragma mark NSNotifications

NSString * __nonnull const FlurryLaunchChanged = @"FlurryLaunchChanged";

#pragma mark Origin Types

NSString * __nonnull const FlurryLaunchMethodDeepLink = @"FlurryLaunchMethodDeepLink";
NSString * __nonnull const FlurryLaunchMethodURL      = @"FlurryLaunchMethodURL";

NSString * __nonnull const FlurryLaunchMethodLocalNotification  = @"FlurryLaunchMethodLocalNotification";
NSString * __nonnull const FlurryLaunchMethodRemoteNotification = @"FlurryLaunchMethodRemoteNotification";

NSString * __nonnull const FlurryLaunchMethodBackgroundFetch = @"FlurryLaunchMethodBackgroundFetch";

NSString * __nonnull const FlurryLaunchMethodURLSession = @"FlurryLaunchMethodURLSession";

NSString * __nonnull const FlurryLaunchMethodWatchExtension = @"FlurryLaunchMethodWatchExtension";

NSString * __nonnull const FlurryLaunchMethodContinuity = @"FlurryLaunchMethodContinuity";

NSString * __nonnull const FlurryLaunchMethodLocation = @"FlurryLaunchMethodLocation";

NSString * __nonnull const FlurryLaunchMethodNewsstand = @"FlurryLaunchMethodNewsstand";

NSString * __nonnull const FlurryLaunchMethodBluetoothCentral    = @"FlurryLaunchMethodBluetoothCentral";
NSString * __nonnull const FlurryLaunchMethodBluetoothPeripheral = @"FlurryLaunchMethodBluetoothPeripheral";

#pragma mark Session Property Keys

NSString * __nonnull const FlurryOriginLaunchPropertySource = @"FlurryOriginLaunchPropertySource";
NSString * __nonnull const FlurryOriginLaunchPropertyURL    = @"FlurryOriginLaunchPropertyURL";

NSString * __nonnull const FlurryOriginLaunchPropertyAction   = @"FlurryOriginLaunchPropertyAction";
NSString * __nonnull const FlurryOriginLaunchPropertyAlert    = @"FlurryOriginLaunchPropertyAlert";
NSString * __nonnull const FlurryOriginLaunchPropertyBadge    = @"FlurryOriginLaunchPropertyBadge";
NSString * __nonnull const FlurryOriginLaunchPropertyCategory = @"FlurryOriginLaunchPropertyCategory";
NSString * __nonnull const FlurryOriginLaunchPropertyTitle    = @"FlurryOriginLaunchPropertyTitle";

NSString * __nonnull const FlurryOriginLaunchPropertyActivityType = @"FlurryOriginLaunchPropertyActivityType";

NSString * __nonnull const FlurryOriginLaunchPropertyNewsstandAsset = @"FlurryOriginLaunchPropertyNewsstandAsset";

NSString * __nonnull const FlurryOriginLaunchPropertyBluetoothRestoreID = @"FlurryOriginLaunchPropertyBluetoothRestoreID";

static const char *kFlurryLaunchOriginAutoInstrumentation = "kFlurryLaunchOriginAutoInstrumentation";

static NSString *FlurryLaunchOrigin_LaunchMethod;
static NSString *FlurryLaunchOrigin_LaunchOrigin;
//static NSDictionary<NSString *, id> *FlurryLaunchOrigin_LaunchProperties;
static NSDictionary *FlurryLaunchOrigin_LaunchProperties;

static BOOL FlurryLaunchOrigin_EnableLogging;

static void clearState();
static void stateChanged();
static void debugDump();

#pragma mark - FlurryLaunchOrigin

@interface FlurryLaunchOrigin () <UIApplicationDelegate>

@end

@implementation FlurryLaunchOrigin

#pragma mark Static Initialization

+ (void)initialize
{
    clearState();
}

#pragma mark Config

+ (void)enableLogging:(BOOL)enabled
{
    FlurryLaunchOrigin_EnableLogging = enabled;
}

#pragma mark Auto Instrument

static void instrumentInstanceMethod(Class delegateClass, Class delegateSubclass, SEL selector)
{
    // Make sure the original delegate supports the selector
    Method delegateMethod = class_getInstanceMethod(delegateClass, selector);
    if (delegateMethod) {
        // Make sure we care about the selector
        Method instrMethod = class_getInstanceMethod([FlurryLaunchOrigin class], selector);
        if (instrMethod) {
            // Grab our implementation
            IMP instrImp = method_getImplementation(instrMethod);
            const char *instrTypes = method_getTypeEncoding(instrMethod);
            
            // Add our implementation to the new subclass
            class_addMethod(delegateSubclass, selector, instrImp, instrTypes);
        }
    }
}

+ (BOOL)autoInstrumentDelegate:(nonnull id <UIApplicationDelegate>)delegate
{
    // Don't instrument non-UIApplicationDelegates
    if (![delegate conformsToProtocol:@protocol(UIApplicationDelegate)]) {
        return NO;
    }
    
    // Don't double-instrument the same delegate
    if (objc_getAssociatedObject(delegate, kFlurryLaunchOriginAutoInstrumentation)) {
        return NO;
    }
 
    // Mark the delegate as instrumented
    objc_setAssociatedObject(delegate, kFlurryLaunchOriginAutoInstrumentation, @(1), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    //
    // In the unlikely case where the app delegate class has multiple instances,
    // we only want to clobber this particular instance. Not the entire class.
    //
    // This is done by dynamically inventing a new subclass of the delegate that
    // we can modify.
    //
    Class originalClass = [delegate class];
    dispatch_time_t now = dispatch_walltime(NULL, 0);
    const char *instrSubclassName = [[NSString stringWithFormat:@"%@-%p-%llu", originalClass, delegate, now] UTF8String];
    Class instrSubclass = objc_allocateClassPair(originalClass, instrSubclassName, 0);
    objc_registerClassPair(instrSubclass);
    
    // Instrument all possible UIApplicationDelegate methods
    instrumentInstanceMethod(originalClass, instrSubclass, @selector(application:willFinishLaunchingWithOptions:));
    instrumentInstanceMethod(originalClass, instrSubclass, @selector(application:didFinishLaunchingWithOptions:));
    
    instrumentInstanceMethod(originalClass, instrSubclass, @selector(application:handleOpenURL:));
    instrumentInstanceMethod(originalClass, instrSubclass, @selector(application:openURL:sourceApplication:annotation:));
    instrumentInstanceMethod(originalClass, instrSubclass, @selector(application:openURL:options:));
    
    instrumentInstanceMethod(originalClass, instrSubclass, @selector(application:didReceiveRemoteNotification:));
    instrumentInstanceMethod(originalClass, instrSubclass, @selector(application:didReceiveRemoteNotification:fetchCompletionHandler:));
    instrumentInstanceMethod(originalClass, instrSubclass, @selector(application:handleActionWithIdentifier:forRemoteNotification:withResponseInfo:completionHandler:));
    instrumentInstanceMethod(originalClass, instrSubclass, @selector(application:handleActionWithIdentifier:forRemoteNotification:completionHandler:));
    
    instrumentInstanceMethod(originalClass, instrSubclass, @selector(application:didReceiveLocalNotification:));
    instrumentInstanceMethod(originalClass, instrSubclass, @selector(application:handleActionWithIdentifier:forLocalNotification:completionHandler:));
    instrumentInstanceMethod(originalClass, instrSubclass, @selector(application:handleActionWithIdentifier:forLocalNotification:withResponseInfo:completionHandler:));
    
    instrumentInstanceMethod(originalClass, instrSubclass, @selector(application:performFetchWithCompletionHandler:));
    
    instrumentInstanceMethod(originalClass, instrSubclass, @selector(application:handleEventsForBackgroundURLSession:completionHandler:));
    
    instrumentInstanceMethod(originalClass, instrSubclass, @selector(application:handleWatchKitExtensionRequest:reply:));
    
    instrumentInstanceMethod(originalClass, instrSubclass, @selector(application:willContinueUserActivityWithType:));
    
    //
    // Always override applicationDidEnterBackground: even it the app doesn't
    // care. We always need to clear our state when entering the background.
    //
    {
        SEL selector = @selector(applicationDidEnterBackground:);
        
        // Make sure we care about the selector
        Method instrMethod = class_getInstanceMethod([FlurryLaunchOrigin class], selector);
        
        // Grab our implementation
        IMP instrImp = method_getImplementation(instrMethod);
        const char *instrTypes = method_getTypeEncoding(instrMethod);
        
        // Add our implementation to the new subclass
        class_addMethod(instrSubclass, selector, instrImp, instrTypes);
    }
    
    // Change the delegate to the new instrumented subclass
    object_setClass(delegate, instrSubclass);

    return YES;
}

#pragma mark Properties

+ (nullable NSString *)launchMethod
{
    return FlurryLaunchOrigin_LaunchMethod;
}

+ (nullable NSString *)launchOrigin
{
    return FlurryLaunchOrigin_LaunchOrigin;
}

//+ (nonnull NSDictionary<NSString *, id> *)launchProperties
+ (nonnull NSDictionary *)launchProperties
{
    return FlurryLaunchOrigin_LaunchProperties;
}

#pragma mark Lifecycle Handlers

+ (void)         application:(nonnull UIApplication *)application
finishedLaunchingWithOptions:(nullable NSDictionary *)launchOptions
{
    if (launchOptions[UIApplicationLaunchOptionsSourceApplicationKey]) {
        NSURL *url = launchOptions[UIApplicationLaunchOptionsURLKey];
        [self application:application openURL:url options:launchOptions];
        
    } else if (launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey]) {
        NSDictionary *options = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
        [self application:application handleActionWithIdentifier:nil forRemoteNotification:options withResponseInfo:@{} completionHandler:^{}];
        
    } else if (launchOptions[UIApplicationLaunchOptionsLocalNotificationKey]) {
        UILocalNotification *notification = launchOptions[UIApplicationLaunchOptionsLocalNotificationKey];
        [self application:application handleActionWithIdentifier:nil forLocalNotification:notification withResponseInfo:@{} completionHandler:^{}];
        
    } else if (launchOptions[UIApplicationLaunchOptionsUserActivityDictionaryKey]) {
        NSString *userActivityType = launchOptions[UIApplicationLaunchOptionsUserActivityDictionaryKey][UIApplicationLaunchOptionsUserActivityTypeKey];
        [self application:application willContinueUserActivityWithType:userActivityType];
        
    } else if (launchOptions[UIApplicationLaunchOptionsLocationKey]) {
        FlurryLaunchOrigin_LaunchMethod     = FlurryLaunchMethodLocation;
        FlurryLaunchOrigin_LaunchOrigin     = nil;
        FlurryLaunchOrigin_LaunchProperties = @{};

    } else if (launchOptions[UIApplicationLaunchOptionsNewsstandDownloadsKey]) {
        FlurryLaunchOrigin_LaunchMethod = FlurryLaunchMethodNewsstand;
        FlurryLaunchOrigin_LaunchOrigin = nil;

        //
        // TODO: Flurry is working on supporting more complex parameters. Report
        //       the first item for now.
        //
        NSArray *assets = launchOptions[UIApplicationLaunchOptionsNewsstandDownloadsKey];
        if (assets.count) {
            FlurryLaunchOrigin_LaunchProperties = @{
                FlurryOriginLaunchPropertyNewsstandAsset : [assets objectAtIndex:0]
            };
        } else {
            FlurryLaunchOrigin_LaunchProperties = @{};
        }
        
    } else if (launchOptions[UIApplicationLaunchOptionsBluetoothCentralsKey]) {
        FlurryLaunchOrigin_LaunchMethod = FlurryLaunchMethodBluetoothCentral;
        FlurryLaunchOrigin_LaunchOrigin = nil;

        //
        // TODO: Flurry is working on supporting more complex parameters. Report
        //       the first item for now.
        //
        NSArray *restoreIDs = launchOptions[UIApplicationLaunchOptionsBluetoothCentralsKey];
        if (restoreIDs.count) {
            FlurryLaunchOrigin_LaunchProperties = @{
                FlurryOriginLaunchPropertyBluetoothRestoreID : [restoreIDs objectAtIndex:0]
            };
        } else {
            FlurryLaunchOrigin_LaunchProperties = @{};
        }
        
    } else if (launchOptions[UIApplicationLaunchOptionsBluetoothPeripheralsKey]) {
        FlurryLaunchOrigin_LaunchMethod = FlurryLaunchMethodBluetoothPeripheral;
        FlurryLaunchOrigin_LaunchOrigin = nil;

        //
        // TODO: Flurry is working on supporting more complex parameters. Report
        //       the first item for now.
        //
        NSArray *restoreIDs = launchOptions[UIApplicationLaunchOptionsBluetoothPeripheralsKey];
        if (restoreIDs.count) {
            FlurryLaunchOrigin_LaunchProperties = @{
                FlurryOriginLaunchPropertyBluetoothRestoreID : [restoreIDs objectAtIndex:0]
            };
        } else {
            FlurryLaunchOrigin_LaunchProperties = @{};
        }
        
    } else {
        clearState();
    }
    
    stateChanged();
}

+ (void)application:(nonnull UIApplication *)application
            openURL:(nonnull NSURL *)url
//            options:(nonnull NSDictionary<NSString*, id> *)options
            options:(nonnull NSDictionary *)options
{
    NSString *urlString = url.absoluteString;

    if (options[UIApplicationLaunchOptionsSourceApplicationKey]) {
        FlurryLaunchOrigin_LaunchMethod     = FlurryLaunchMethodDeepLink;
        FlurryLaunchOrigin_LaunchOrigin     = options[UIApplicationLaunchOptionsSourceApplicationKey];
        FlurryLaunchOrigin_LaunchProperties = @{
            FlurryOriginLaunchPropertySource : FlurryLaunchOrigin_LaunchOrigin,
            FlurryOriginLaunchPropertyURL    : urlString ? urlString : @""
        };
        
    } else if (options[UIApplicationOpenURLOptionsSourceApplicationKey]) {
        FlurryLaunchOrigin_LaunchMethod     = FlurryLaunchMethodDeepLink;
        FlurryLaunchOrigin_LaunchOrigin     = options[UIApplicationOpenURLOptionsSourceApplicationKey];
        FlurryLaunchOrigin_LaunchProperties = @{
            FlurryOriginLaunchPropertySource : FlurryLaunchOrigin_LaunchOrigin,
            FlurryOriginLaunchPropertyURL    : urlString ? urlString : @""
        };
        
    } else {
        FlurryLaunchOrigin_LaunchMethod     = FlurryLaunchMethodURL;
        FlurryLaunchOrigin_LaunchOrigin     = nil;
        FlurryLaunchOrigin_LaunchProperties = @{
            FlurryOriginLaunchPropertyURL : urlString ? urlString : @""
        };
    }
    
    stateChanged();
}

+ (nonnull void(^)())application:(nonnull UIApplication *)application
      handleActionWithIdentifier:(nullable NSString *)identifier
           forRemoteNotification:(nonnull NSDictionary *)userInfo
                withResponseInfo:(nonnull NSDictionary *)responseInfo
               completionHandler:(nonnull void(^)())completionHandler
{
    FlurryLaunchOrigin_LaunchMethod = FlurryLaunchMethodRemoteNotification;
    FlurryLaunchOrigin_LaunchOrigin = nil;

    {
        NSMutableDictionary *d = [NSMutableDictionary dictionary];

        if (identifier) {
            d[FlurryOriginLaunchPropertyAction] = identifier;
        }
        
        NSDictionary *aps = userInfo[@"aps"];
        NSString *alert = aps[@"alert"];
        NSNumber *badge = aps[@"badge"];
        
        if (alert) {
            d[FlurryOriginLaunchPropertyAlert] = alert;
        }
        
        if (badge) {
            d[FlurryOriginLaunchPropertyBadge] = badge;
        }
        
        FlurryLaunchOrigin_LaunchProperties = [d copy];
    }
    
    stateChanged();
    
    return ^{
        if (application.applicationState == UIApplicationStateBackground) {
            clearState();
        }
        completionHandler();
    };
}

+ (nonnull void(^)())application:(nonnull UIApplication *)application
      handleActionWithIdentifier:(nullable NSString *)identifier
            forLocalNotification:(nonnull UILocalNotification *)notification
                withResponseInfo:(nonnull NSDictionary *)responseInfo
               completionHandler:(nonnull void(^)())completionHandler
{
    // If we're already running, don't update the origin
    if (application.applicationState == UIApplicationStateActive) {
        return ^{};
    }
    
    FlurryLaunchOrigin_LaunchMethod = FlurryLaunchMethodLocalNotification;
    FlurryLaunchOrigin_LaunchOrigin = nil;

    {
        NSMutableDictionary *d = [NSMutableDictionary dictionary];
        
        if (identifier) {
            d[FlurryOriginLaunchPropertyAction] = identifier;
        }
        
        NSString *action   = notification.alertAction;
        NSString *body     = notification.alertBody;
        NSString *category = notification.category;
        NSString *title    = notification.alertTitle;
        
        if (action) {
            d[FlurryOriginLaunchPropertyAction] = action;
        }
        
        if (body) {
            d[FlurryOriginLaunchPropertyAlert] = body;
        }
        
        if (category) {
            d[FlurryOriginLaunchPropertyCategory] = category;
        }
        
        if (title) {
            d[FlurryOriginLaunchPropertyTitle] = title;
        }
        
        d[FlurryOriginLaunchPropertyBadge] = @(notification.applicationIconBadgeNumber);
    
        FlurryLaunchOrigin_LaunchProperties = [d copy];
    }
    
    stateChanged();

    return ^{
        if (application.applicationState == UIApplicationStateBackground) {
            clearState();
        }
        completionHandler();
    };
}

+ (nonnull void (^)(UIBackgroundFetchResult result))application:(nonnull UIApplication *)application
                              performFetchWithCompletionHandler:(nonnull void (^)(UIBackgroundFetchResult result))completionHandler
{
    FlurryLaunchOrigin_LaunchMethod     = FlurryLaunchMethodBackgroundFetch;
    FlurryLaunchOrigin_LaunchOrigin     = nil;
    FlurryLaunchOrigin_LaunchProperties = @{};

    stateChanged();
    
    return ^void(UIBackgroundFetchResult result) {
        if (application.applicationState == UIApplicationStateBackground) {
            clearState();
        }
        completionHandler(result);
    };
}

+ (nonnull void (^)())  application:(nonnull UIApplication *)application
handleEventsForBackgroundURLSession:(nonnull NSString *)identifier
                  completionHandler:(nonnull void (^)())completionHandler
{
    // If we're already running, don't update the origin
    if (application.applicationState == UIApplicationStateActive) {
        return ^{};
    }

    FlurryLaunchOrigin_LaunchMethod     = FlurryLaunchMethodURLSession;
    FlurryLaunchOrigin_LaunchOrigin     = nil;
    FlurryLaunchOrigin_LaunchProperties = @{};

    stateChanged();
    
    return ^{
        if (application.applicationState == UIApplicationStateBackground) {
            clearState();
        }
        completionHandler();
    };
}

+ (nonnull void(^)(NSDictionary * __nullable replyInfo))application:(nonnull UIApplication *)application
                                     handleWatchKitExtensionRequest:(nullable NSDictionary *)userInfo
                                                              reply:(nonnull void(^)(NSDictionary * __nullable replyInfo))reply
{
    // If we're already running, don't update the origin
    if (application.applicationState == UIApplicationStateActive) {
        return ^void(NSDictionary * __nullable replyInfo) {};
    }

    FlurryLaunchOrigin_LaunchMethod     = FlurryLaunchMethodWatchExtension;
    FlurryLaunchOrigin_LaunchOrigin     = nil;
    FlurryLaunchOrigin_LaunchProperties = @{};
    
    stateChanged();
    
    return ^void(NSDictionary * __nullable replyInfo) {
        if (application.applicationState == UIApplicationStateBackground) {
            clearState();
        }
        reply(replyInfo);
    };
}

+ (void)applicationDidEnterBackground:(nonnull UIApplication *)application
{
    if (application.applicationState != UIApplicationStateBackground) {
        return;
    }
    
    clearState();
    
    stateChanged();
}

+ (void)             application:(nonnull UIApplication *)application
willContinueUserActivityWithType:(nonnull NSString *)userActivityType
{
    FlurryLaunchOrigin_LaunchMethod     = FlurryLaunchMethodContinuity;
    FlurryLaunchOrigin_LaunchOrigin     = nil;
    FlurryLaunchOrigin_LaunchProperties = @{ FlurryOriginLaunchPropertyActivityType : userActivityType };
    
    stateChanged();
}

#pragma mark Private

static void clearState()
{
    FlurryLaunchOrigin_LaunchMethod     = nil;
    FlurryLaunchOrigin_LaunchOrigin     = nil;
    FlurryLaunchOrigin_LaunchProperties = @{};
    
    stateChanged();
}

static void stateChanged()
{
    [[NSNotificationCenter defaultCenter] postNotificationName:FlurryLaunchChanged object:nil];

    debugDump();
}

static void debugDump()
{
    if (FlurryLaunchOrigin_EnableLogging) {
        NSLog(@"Method:     %@", FlurryLaunchOrigin_LaunchMethod);
        NSLog(@"Origin:     %@", FlurryLaunchOrigin_LaunchOrigin);
        NSLog(@"Properties: %@", FlurryLaunchOrigin_LaunchProperties);
    }
}

#pragma mark Auto Instrumentation Handlers

- (BOOL)           application:(UIApplication *)application
willFinishLaunchingWithOptions:(nullable NSDictionary *)launchOptions
{
    [FlurryLaunchOrigin application:application finishedLaunchingWithOptions:launchOptions];
    
    // NOTE: Our super is really the original delegate's method
    struct objc_super s = {
        .receiver    = self,
        .super_class = [self superclass]
    };
    
    // return [super application:application willFinishLaunchingWithOptions:launchOptions];
    BOOL (*superMethod)(struct objc_super *, SEL, UIApplication *, NSDictionary *) = (void *)&objc_msgSendSuper;
    return superMethod(&s, _cmd, application, launchOptions);
}

- (BOOL)          application:(UIApplication *)application
didFinishLaunchingWithOptions:(nullable NSDictionary *)launchOptions
{
    [FlurryLaunchOrigin application:application finishedLaunchingWithOptions:launchOptions];

    // NOTE: Our super is really the original delegate's method
    struct objc_super s = {
        .receiver    = self,
        .super_class = [self superclass]
    };
    
    // return [super application:application didFinishLaunchingWithOptions:launchOptions];
    BOOL (*superMethod)(struct objc_super *, SEL, UIApplication *, NSDictionary *) = (void *)&objc_msgSendSuper;
    return superMethod(&s, _cmd, application, launchOptions);
}

- (BOOL)application:(UIApplication *)application
      handleOpenURL:(NSURL *)url
{
    [FlurryLaunchOrigin application:application openURL:url options:@{}];
    
    // NOTE: Our super is really the original delegate's method
    struct objc_super s = {
        .receiver    = self,
        .super_class = [self superclass]
    };
    
    // return [super application:application handleOpenURL:url];
    BOOL (*superMethod)(struct objc_super *, SEL, UIApplication *, NSURL *) = (void *)&objc_msgSendSuper;
    return superMethod(&s, _cmd, application, url);
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(nullable NSString *)sourceApplication
         annotation:(id)annotation
{
    [FlurryLaunchOrigin application:application
                            openURL:url
                            options:sourceApplication ? @{ UIApplicationLaunchOptionsSourceApplicationKey : sourceApplication } : @{}];
    
    // NOTE: Our super is really the original delegate's method
    struct objc_super s = {
        .receiver    = self,
        .super_class = [self superclass]
    };
    
    // return [super application:application openURL:url sourceApplication:sourceApplication annotation:annotation];
    BOOL (*superMethod)(struct objc_super *, SEL, UIApplication *, NSURL *, NSString *, id) = (void *)&objc_msgSendSuper;
    return superMethod(&s, _cmd, application, url, sourceApplication, annotation);
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
//            options:(NSDictionary<NSString*, id> *)options
            options:(NSDictionary *)options
{
    [FlurryLaunchOrigin application:application openURL:url options:options];
    
    // NOTE: Our super is really the original delegate's method
    struct objc_super s = {
        .receiver    = self,
        .super_class = [self superclass]
    };
    
    // return [super application:application openURL:url options:options];
//    BOOL (*superMethod)(struct objc_super *, SEL, UIApplication *, NSURL *, NSDictionary<NSString*, id> *) = (void *)&objc_msgSendSuper;
    BOOL (*superMethod)(struct objc_super *, SEL, UIApplication *, NSURL *, NSDictionary *) = (void *)&objc_msgSendSuper;
    return superMethod(&s, _cmd, application, url, options);
}

- (void)         application:(UIApplication *)application
didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    [FlurryLaunchOrigin application:application handleActionWithIdentifier:nil
              forRemoteNotification:userInfo
                   withResponseInfo:@{}
                  completionHandler:^{}];
    
    // NOTE: Our super is really the original delegate's method
    struct objc_super s = {
        .receiver    = self,
        .super_class = [self superclass]
    };
    
    // [super application:application didReceiveRemoteNotification:userInfo];
    void (*superMethod)(struct objc_super *, SEL, UIApplication *, NSDictionary *) = (void *)&objc_msgSendSuper;
    superMethod(&s, _cmd, application, userInfo);
}

- (void)         application:(UIApplication *)application
didReceiveRemoteNotification:(NSDictionary *)userInfo
      fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler
{
    completionHandler = [FlurryLaunchOrigin application:application
                             handleActionWithIdentifier:nil
                                  forRemoteNotification:userInfo
                                       withResponseInfo:@{}
                                      completionHandler:completionHandler];
    
    // NOTE: Our super is really the original delegate's method
    struct objc_super s = {
        .receiver    = self,
        .super_class = [self superclass]
    };
    
    // [super application:application didReceiveRemoteNotification:userInfo fetchCompletionHandler:completionHandler];
    void (*superMethod)(struct objc_super *, SEL, UIApplication *, NSDictionary *, void (^)(UIBackgroundFetchResult)) = (void *)&objc_msgSendSuper;
    superMethod(&s, _cmd, application, userInfo, completionHandler);
}

- (void)       application:(UIApplication *)application
handleActionWithIdentifier:(nullable NSString *)identifier
     forRemoteNotification:(NSDictionary *)userInfo
         completionHandler:(void(^)())completionHandler
{
    completionHandler = [FlurryLaunchOrigin application:application
                             handleActionWithIdentifier:identifier
                                  forRemoteNotification:userInfo
                                       withResponseInfo:@{}
                                      completionHandler:completionHandler];
    
    // NOTE: Our super is really the original delegate's method
    struct objc_super s = {
        .receiver    = self,
        .super_class = [self superclass]
    };
    
    // [super application:application handleActionWithIdentifier:identifier forRemoteNotification:userInfo completionHandler:completionHandler];
    void (*superMethod)(struct objc_super *, SEL, UIApplication *, NSString *, NSDictionary *, void (^)(UIBackgroundFetchResult)) = (void *)&objc_msgSendSuper;
    superMethod(&s, _cmd, application, identifier, userInfo, completionHandler);
}

- (void)       application:(UIApplication *)application
handleActionWithIdentifier:(nullable NSString *)identifier
     forRemoteNotification:(NSDictionary *)userInfo
          withResponseInfo:(NSDictionary *)responseInfo
         completionHandler:(void(^)())completionHandler
{
    completionHandler = [FlurryLaunchOrigin application:application
                             handleActionWithIdentifier:identifier
                                  forRemoteNotification:userInfo
                                       withResponseInfo:responseInfo
                                      completionHandler:completionHandler];
    
    // NOTE: Our super is really the original delegate's method
    struct objc_super s = {
        .receiver    = self,
        .super_class = [self superclass]
    };
    
    // [super application:application handleActionWithIdentifier:identifier forRemoteNotification:userInfo withResponseInfo:responseInfo completionHandler:completionHandler];
    void (*superMethod)(struct objc_super *, SEL, UIApplication *, NSString *, NSDictionary *, NSDictionary *, void (^)()) = (void *)&objc_msgSendSuper;
    superMethod(&s, _cmd, application, identifier, userInfo, responseInfo, completionHandler);
}

- (void)        application:(UIApplication *)application
didReceiveLocalNotification:(UILocalNotification *)notification
{
    [FlurryLaunchOrigin application:application
         handleActionWithIdentifier:nil
               forLocalNotification:notification
                   withResponseInfo:@{}
                  completionHandler:^{}];
    
    // NOTE: Our super is really the original delegate's method
    struct objc_super s = {
        .receiver    = self,
        .super_class = [self superclass]
    };
    
    // [super application:application didReceiveLocalNotification:notification];
    void (*superMethod)(struct objc_super *, SEL, UIApplication *, UILocalNotification *) = (void *)&objc_msgSendSuper;
    superMethod(&s, _cmd, application, notification);
}

- (void)       application:(UIApplication *)application
handleActionWithIdentifier:(nullable NSString *)identifier
      forLocalNotification:(UILocalNotification *)notification
         completionHandler:(void(^)())completionHandler
{
    completionHandler = [FlurryLaunchOrigin application:application
                             handleActionWithIdentifier:identifier
                                   forLocalNotification:notification
                                       withResponseInfo:@{}
                                      completionHandler:^{}];
    
    // NOTE: Our super is really the original delegate's method
    struct objc_super s = {
        .receiver    = self,
        .super_class = [self superclass]
    };
    
    // [super application:application handleActionWithIdentifier:identifier forLocalNotification:notification completionHandler:completionHandler];
    void (*superMethod)(struct objc_super *, SEL, UIApplication *, NSString *, UILocalNotification *, void(^)()) = (void *)&objc_msgSendSuper;
    superMethod(&s, _cmd, application, identifier, notification, completionHandler);
}

- (void)       application:(UIApplication *)application
handleActionWithIdentifier:(nullable NSString *)identifier
      forLocalNotification:(UILocalNotification *)notification
          withResponseInfo:(nonnull NSDictionary *)responseInfo
         completionHandler:(void(^)())completionHandler
{
    completionHandler = [FlurryLaunchOrigin application:application
                             handleActionWithIdentifier:identifier
                                   forLocalNotification:notification
                                       withResponseInfo:responseInfo
                                      completionHandler:^{}];
    
    // NOTE: Our super is really the original delegate's method
    struct objc_super s = {
        .receiver    = self,
        .super_class = [self superclass]
    };
    
    // [super application:application handleActionWithIdentifier:identifier forLocalNotification:notification withResponseInfo:responseInfo completionHandler:completionHandler];
    void (*superMethod)(struct objc_super *, SEL, UIApplication *, NSString *, UILocalNotification *, NSDictionary *, void(^)()) = (void *)&objc_msgSendSuper;
    superMethod(&s, _cmd, application, identifier, notification, responseInfo, completionHandler);
}

- (void)              application:(UIApplication *)application
performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler
{
    completionHandler = [FlurryLaunchOrigin application:application
                      performFetchWithCompletionHandler:completionHandler];
    
    // NOTE: Our super is really the original delegate's method
    struct objc_super s = {
        .receiver    = self,
        .super_class = [self superclass]
    };
    
    // [super application:application performFetchWithCompletionHandler:completionHandler];
    void (*superMethod)(struct objc_super *, SEL, UIApplication *, void (^)(UIBackgroundFetchResult)) = (void *)&objc_msgSendSuper;
    superMethod(&s, _cmd, application, completionHandler);
}

- (void)                application:(UIApplication *)application
handleEventsForBackgroundURLSession:(NSString *)identifier
                  completionHandler:(void (^)())completionHandler
{
    completionHandler = [FlurryLaunchOrigin application:application
                    handleEventsForBackgroundURLSession:identifier
                                      completionHandler:completionHandler];
    
    // NOTE: Our super is really the original delegate's method
    struct objc_super s = {
        .receiver    = self,
        .super_class = [self superclass]
    };
    
    // [super application:application handleEventsForBackgroundURLSession:identifier completionHandler:completionHandler];
    void (*superMethod)(struct objc_super *, SEL, UIApplication *, NSString *, void (^)(UIBackgroundFetchResult)) = (void *)&objc_msgSendSuper;
    superMethod(&s, _cmd, application, identifier, completionHandler);
}

- (void)           application:(UIApplication *)application
handleWatchKitExtensionRequest:(nullable NSDictionary *)userInfo
                         reply:(void(^)(NSDictionary * __nullable replyInfo))reply
{
    reply = [FlurryLaunchOrigin application:application
             handleWatchKitExtensionRequest:userInfo
                                      reply:reply];
    
    // NOTE: Our super is really the original delegate's method
    struct objc_super s = {
        .receiver    = self,
        .super_class = [self superclass]
    };
    
    // [super application:application handleWatchKitExtensionRequest:userInfo reply:reply];
    void (*superMethod)(struct objc_super *, SEL, UIApplication *, NSDictionary *, void (^)(NSDictionary * __nullable)) = (void *)&objc_msgSendSuper;
    superMethod(&s, _cmd, application, userInfo, reply);
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [FlurryLaunchOrigin applicationDidEnterBackground:application];
    
    //
    // Since we always require overriding applicationDidEnterBackground:, our
    // superclass may not always implement it. So we need to check before trying
    // to bubble the call up.
    //
    if (class_getInstanceMethod([self superclass], _cmd)) {
        // NOTE: Our super is really the original delegate's method
        struct objc_super s = {
            .receiver    = self,
            .super_class = [self superclass]
        };

        // [super applicationDidEnterBackground:application];
        void (*superMethod)(struct objc_super *, SEL, UIApplication *) = (void *)&objc_msgSendSuper;
        superMethod(&s, _cmd, application);
    }
}

- (BOOL)             application:(UIApplication *)application
willContinueUserActivityWithType:(NSString *)userActivityType
{
    [FlurryLaunchOrigin application:application willContinueUserActivityWithType:userActivityType];
    
    // NOTE: Our super is really the original delegate's method
    struct objc_super s = {
        .receiver    = self,
        .super_class = [self superclass]
    };
    
    // return [super application:application willContinueUserActivityWithType:userActivityType];
    BOOL (*superMethod)(struct objc_super *, SEL, UIApplication *, NSString *) = (void *)&objc_msgSendSuper;
    return superMethod(&s, _cmd, application, userActivityType);
}

@end
