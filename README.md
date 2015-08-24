# FlurryLaunchOrigin
Wrapper for instrumenting origin of app launch such as app start, deep linking, local notifications, remote notifications, etc.... While designed with Flurry in mind, the library carries no dependencies on Flurry. Apps can query the currently detected launch origin or receive notifications when it changes.

The currently supported launch "methods" include:
  - Normal launch (Home, Siri, etc...)
  - Deep link (Safari, openURL:, etc...)
  - Local Notification
  - Remote Notification
  - Continuity
  - Watch
  - Bluetooth
  - Background Location
  - Background Fetch
  - Background NSURLSession
  - Background Newsstand

## Quick Start
### Get the code
You can add the FlurryLaunchOrigin Cocoapod to your project or cut & paste the FlurryLaunchOrigin.[hm] files into your project.

### Auto-instrumentation
Add the following snippet to your application delegate:
```
#import <FlurryLaunchOrigin/FlurryLaunchOrigin.h>
...
- (instancetype)init
{
    self = [super init];
    if (self) {
        // **** THIS IS WHERE THE MAGIC HAPPENS ****
        [FlurryLaunchOrigin autoInstrumentDelegate:self];
    }        
    return self;
}
...
- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // **** This is probably a good place to get the update launch origin ****
    NSLog(@"%s: Method:     %@", __PRETTY_FUNCTION__, [FlurryLaunchOrigin launchMethod]);
    NSLog(@"%s: Origin:     %@", __PRETTY_FUNCTION__, [FlurryLaunchOrigin launchOrigin]);
    NSLog(@"%s: Properties: %@", __PRETTY_FUNCTION__, [FlurryLaunchOrigin launchProperties]);

    NSMutableDictionary *sessionProps = [NSMutableDictionary dictionary];
    NSString *method = [FlurryLaunchOrigin launchMethod];
    if ([method isKindOfClass:[NSString class]) {
        [sessionProps setObject:method forKey:@"method"];
    }
    
    NSString *origin = [FlurryLaunchOrigin launchOrigin];
    if ([origin isKindOfClass:[NSString class]) {
        [sessionProps setObject:origin forKey:@"origin"];
    }

    [Flurry sessionProperties:sessionProps];
    [Flurry addSessionOrigin:[FlurryLaunchOrigin launchOrigin]];
}
```

## Advanced
### Launch Properties
The launch properties from ```[FlurryLaunchOrigin launchProperties]``` contains a dictionary with more details gathered from the launch, depending on the method. For example, a push notification will contain elements of the push payload. These can be added to the session properties as required.

### Manual Instrumentation
While the auto-instrumentation is pretty cool, it relies on some Objective-C runtime hackery (which shall remain unnamed here). If this bothers you even in the slightest, the library includes manual instrumentation methods. Just add them to your ```UIApplicationDelegate``` using the following rules:
1. Make sure you instrument all the entry points your app supports
   * ```application:didFinishLaunchingWithOptions:``` is not the only place!
   * If you care about ```openURL:```, you also need to instrument the related delegates
2. Always instrument ```applicationDidEnterBackground:```
   * Necessary to clear origin state when the app is suspended
3. For methods that take a completion block, always use the returned completion block
   * The wrapped completion block will clear the origin when the app is suspended

### Notification
While ```applicationDidBecomeActive:``` is good enough for most uses, it is not always invoked while running in the background. Also several things could happen from the time the origin information is updated and the app entering the active state.

A better way to track origin changes is by listening to the ``` ``` notification.

## TODO
- [] Add watch and extension lifecycle support

## License
MIT

