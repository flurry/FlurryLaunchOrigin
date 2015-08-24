//
//  FlurryLaunchOrigin.h
//  OriginDemo
//
//  Copyright 2015, Yahoo Inc.
//  Copyrights licensed under the MIT License.
//  See the accompanying LICENSE file for terms.
//

#import <UIKit/UIKit.h>

#pragma mark NSNotifications

extern NSString * __nonnull const FlurryLaunchChanged;

#pragma mark Origin Types

extern NSString * __nonnull const FlurryLaunchMethodDeepLink;
extern NSString * __nonnull const FlurryLaunchMethodURL;

extern NSString * __nonnull const FlurryLaunchMethodLocalNotification;
extern NSString * __nonnull const FlurryLaunchMethodRemoteNotification;

extern NSString * __nonnull const FlurryLaunchMethodBackgroundFetch;
extern NSString * __nonnull const FlurryLaunchMethodContinuity;
extern NSString * __nonnull const FlurryLaunchMethodLocation;
extern NSString * __nonnull const FlurryLaunchMethodWatchExtension;

extern NSString * __nonnull const FlurryLaunchMethodBluetoothCentral;
extern NSString * __nonnull const FlurryLaunchMethodBluetoothPeripheral;

extern NSString * __nonnull const FlurryLaunchMethodNewsstand;
extern NSString * __nonnull const FlurryLaunchMethodURLSession;

#pragma mark Session Property Keys

extern NSString * __nonnull const FlurryOriginLaunchPropertySource;
extern NSString * __nonnull const FlurryOriginLaunchPropertyURL;

extern NSString * __nonnull const FlurryOriginLaunchPropertyAction;
extern NSString * __nonnull const FlurryOriginLaunchPropertyAlert;
extern NSString * __nonnull const FlurryOriginLaunchPropertyBadge;
extern NSString * __nonnull const FlurryOriginLaunchPropertyCategory;
extern NSString * __nonnull const FlurryOriginLaunchPropertyTitle;

extern NSString * __nonnull const FlurryOriginLaunchPropertyActivityType;

extern NSString * __nonnull const FlurryOriginLaunchPropertyNewsstandAsset;

extern NSString * __nonnull const FlurryOriginLaunchPropertyBluetoothRestoreID;

#pragma mark -

@interface FlurryLaunchOrigin : NSObject

#pragma mark Config

/*!
 * @brief Set debug logging
 */
+ (void)enableLogging:(BOOL)enabled;

#pragma mark Auto Instrument

/*!
 * @brief Automatically instrument app delegate
 *
 * Instead of manually calling lifecycle handlers from the app delegate, this
 * will automatically instrument the given delegate to call into the lifecycle
 * handlers.
 *
 * Invoke this method from the init of the app delegate. Something like this:
 * @code
    - (instancetype)init
    {
        self = [super init];
        if (self) {
            [FlurryLaunchOrigin autoInstrumentDelegate:self];
        }

        return self;
    }
 * @endcode
 *
 * @note If you are not comfortable with autoInstrument:, you can always
 *       manually call the lifecycle handlers yourself from your
 *       UIApplicationDelegate.
 */
+ (BOOL)autoInstrumentDelegate:(nonnull id <UIApplicationDelegate>)delegate;

#pragma mark Getters

/*!
 * @brief Get current launch method
 *
 * @return Currently detected launch method, can be nil for "normal launch".
 */
+ (nullable NSString *)launchMethod;

/*!
 * @brief Get current launch origin
 *
 * @return Currently detected origin, can be nil for "normal launch".
 */
+ (nullable NSString *)launchOrigin;

/*!
 * @brief Get current launch origin properties
 *
 * @return Dictionary of detected properties for the current launch origin.
 */
//+ (nonnull NSDictionary<NSString *, id> *)launchProperties;
+ (nonnull NSDictionary *)launchProperties;

#pragma mark Lifecycle Handlers

/*!
 * @brief Handle application launch
 *
 * Update current launch origin due to application launch. Can be called from
 * either the top of application:willFinishLaunchingWithOptions: or
 * application:didFinishLaunchingWithOptions:.
 */
+ (void)         application:(nonnull UIApplication *)application
finishedLaunchingWithOptions:(nullable NSDictionary *)launchOptions;

/*!
 * @brief Handle openURL
 *
 * Update current launch origin due to openURL. Can be called from the top of
 * application:handleOpenURL:, application:openURL:sourceApplication:annotation:,
 * or application:openURL:options:.
 */
+ (void)application:(nonnull UIApplication *)application
            openURL:(nonnull NSURL *)url
//            options:(nonnull NSDictionary<NSString*, id> *)options;
            options:(nonnull NSDictionary *)options;

/*!
 * @brief Handle remote notification
 *
 * Update current launch origin due to a remote notification. Can be called from
 * the top of application:didReceiveRemoteNotification:,
 * application:didReceiveRemoteNotification:fetchCompletionHandler: or
 * application:handleActionWithIdentifier:forRemoteNotification:completionHandler: or
 * application:handleActionWithIdentifier:forRemoteNotification:withResponseInfo:completionHandler:.
 *
 * @return New wrapped completion handler. Use this instead of the original.
 *
 * @note You must use the returned completion handler instead of the one provided
 *       by iOS. We need to wrap the handler to clear the origin when we return
 *       to the background.
 */
+ (nonnull void(^)())application:(nonnull UIApplication *)application
      handleActionWithIdentifier:(nullable NSString *)identifier
           forRemoteNotification:(nonnull NSDictionary *)userInfo
                withResponseInfo:(nonnull NSDictionary *)responseInfo
               completionHandler:(nonnull void(^)())completionHandler;

/*!
 * @brief Handle local notification
 *
 * Update current launch origin due to a remote notification. Can be called from
 * the top of application:didReceiveLocalNotification:,
 * application:handleActionWithIdentifier:forLocalNotification:completionHandler: or
 * application:handleActionWithIdentifier:forLocalNotification:withResponseInfo:completionHandler:.
 *
 * @return New wrapped completion handler. Use this instead of the original.
 *
 * @note You must use the returned completion handler instead of the one provided
 *       by iOS. We need to wrap the handler to clear the origin when we return
 *       to the background. Pass an empty block if iOS didn't provide a
 *       completion handler.
 */
+ (nonnull void(^)())application:(nonnull UIApplication *)application
      handleActionWithIdentifier:(nullable NSString *)identifier
            forLocalNotification:(nonnull UILocalNotification *)notification
                withResponseInfo:(nonnull NSDictionary *)responseInfo
               completionHandler:(nonnull void(^)())completionHandler;

/*!
 * @brief Handle background fetch
 *
 * Update current launch origin due to a background fetch. Can be called from
 * the top of application:performFetchWithCompletionHandler:.
 *
 * @return New wrapped completion handler. Use this instead of the original.
 *
 * @note You must use the returned completion handler instead of the one provided
 *       by iOS. We need to wrap the handler to clear the origin when we return
 *       to the background.
 */
+ (nonnull void (^)(UIBackgroundFetchResult result))application:(nonnull UIApplication *)application
                              performFetchWithCompletionHandler:(nonnull void (^)(UIBackgroundFetchResult result))completionHandler;

/*!
 * @brief Handle background NSURLSession completion
 *
 * Update current launch origin due to background NSURLSession completion. Can
 * be called from the top of
 * application:handleEventsForBackgroundURLSession:completionHandler:.
 *
 * @return New wrapped completion handler. Use this instead of the original.
 *
 * @note You must use the returned completion handler instead of the one provided
 *       by iOS. We need to wrap the handler to clear the origin when we return
 *       to the background.
 */
+ (nonnull void (^)())  application:(nonnull UIApplication *)application
handleEventsForBackgroundURLSession:(nonnull NSString *)identifier
                  completionHandler:(nonnull void (^)())completionHandler;

/*!
 * @brief Handle watch extension request
 *
 * Update current launch origin due to a watch extension request. Can be called
 * from the top of application:handleWatchKitExtensionRequest:reply:.
 *
 * @return New wrapped completion handler. Use this instead of the original.
 *
 * @note You must use the returned completion handler instead of the one provided
 *       by iOS. We need to wrap the handler to clear the origin when we return
 *       to the background.
 */
+ (nonnull void(^)(NSDictionary * __nullable replyInfo))application:(nonnull UIApplication *)application
                                     handleWatchKitExtensionRequest:(nullable NSDictionary *)userInfo
                                                              reply:(nonnull void(^)(NSDictionary * __nullable replyInfo))reply;

/*!
 * @brief Handle app background
 *
 * Clear current launch origin due to app returning to background. Can be called
 * from the top of applicationDidEnterBackground:.
 *
 * @note We count on clearing the origin when backgrounded because there is no
 *       reliable way to detect that we're restarting from the background.
 */
+ (void)applicationDidEnterBackground:(nonnull UIApplication *)application;

/*!
 * @brief Handle continuity continuation
 *
 * Update current launch origin due to continuation. Can be called from the top
 * of application:willContinueUserActivityWithType:.
 */
+ (void)             application:(nonnull UIApplication *)application
willContinueUserActivityWithType:(nonnull NSString *)userActivityType;

@end
