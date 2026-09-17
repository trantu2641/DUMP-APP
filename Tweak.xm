#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#pragma mark - Configuration

#define SHA_MAX_DEPTH 40
#define SHA_MAX_VIEWS 5000

#pragma mark - Helpers

static NSString *SHAIndent(NSUInteger depth) {
    NSMutableString *s = [NSMutableString string];
    for (NSUInteger i = 0; i < depth; i++) {
        [s appendString:@"  "];
    }
    return s;
}

static BOOL SHAIsApproximatelyTopBar(CGRect frame) {
    CGFloat h = frame.size.height;
    CGFloat y = frame.origin.y;

    // Tìm các vùng thường gặp của status/navigation/top UI.
    BOOL heightMatch =
        (h >= 40.0 && h <= 55.0);

    BOOL yMatch =
        (y >= -5.0 && y <= 55.0);

    return heightMatch && yMatch;
}

static NSString *SHAFrameString(CGRect frame) {
    return [NSString stringWithFormat:
            @"(x=%.1f y=%.1f w=%.1f h=%.1f)",
            frame.origin.x,
            frame.origin.y,
            frame.size.width,
            frame.size.height];
}

static NSString *SHABoundsString(CGRect bounds) {
    return [NSString stringWithFormat:
            @"(x=%.1f y=%.1f w=%.1f h=%.1f)",
            bounds.origin.x,
            bounds.origin.y,
            bounds.size.width,
            bounds.size.height];
}

static NSString *SHASafeAreaString(UIEdgeInsets insets) {
    return [NSString stringWithFormat:
            "(top=%.1f left=%.1f bottom=%.1f right=%.1f)",
            insets.top,
            insets.left,
            insets.bottom,
            insets.right];
}

#pragma mark - View Controller Dump

static void SHADumpViewController(
    UIViewController *vc,
    NSMutableString *output,
    NSUInteger depth
) {
    if (!vc || depth > SHA_MAX_DEPTH)
        return;

    NSString *indent = SHAIndent(depth);

    [output appendFormat:
     @"%@VC: %@\n",
     indent,
     NSStringFromClass([vc class])];

    [output appendFormat:
     @"%@  view=%p\n",
     indent,
     vc.view];

    [output appendFormat:
     @"%@  presented=%@\n",
     indent,
     vc.presentedViewController
        ? NSStringFromClass([vc.presentedViewController class])
        : @"nil"];

    NSArray<UIViewController *> *children = vc.children;

    if (children.count > 0) {
        [output appendFormat:
         @"%@  children=%lu\n",
         indent,
         (unsigned long)children.count];

        for (UIViewController *child in children) {
            SHADumpViewController(child, output, depth + 1);
        }
    }
}

#pragma mark - View Hierarchy

static NSUInteger gSHAViewCount = 0;

static void SHADumpView(
    UIView *view,
    NSMutableString *output,
    NSUInteger depth
) {
    if (!view)
        return;

    if (depth > SHA_MAX_DEPTH)
        return;

    if (gSHAViewCount >= SHA_MAX_VIEWS)
        return;

    gSHAViewCount++;

    NSString *indent = SHAIndent(depth);

    CGRect frame = view.frame;
    CGRect bounds = view.bounds;
    UIEdgeInsets safe = view.safeAreaInsets;

    BOOL topBarCandidate = SHAIsApproximatelyTopBar(frame);

    [output appendFormat:
     @"%@VIEW #%lu %@\n",
     indent,
     (unsigned long)gSHAViewCount,
     NSStringFromClass([view class])];

    [output appendFormat:
     @"%@  frame=%@\n",
     indent,
     SHAFrameString(frame)];

    [output appendFormat:
     @"%@  bounds=%@\n",
     indent,
     SHABoundsString(bounds)];

    [output appendFormat:
     @"%@  safeArea=%@\n",
     indent,
     SHASafeAreaString(safe)];

    [output appendFormat:
     @"%@  hidden=%@ alpha=%.2f userInteraction=%@\n",
     indent,
     view.hidden ? @"YES" : @"NO",
     view.alpha,
     view.userInteractionEnabled ? @"YES" : @"NO"];

    [output appendFormat:
     @"%@  clipsToBounds=%@ subviews=%lu\n",
     indent,
     view.clipsToBounds ? @"YES" : @"NO",
     (unsigned long)view.subviews.count];

    if (topBarCandidate) {
        [output appendFormat:
         @"%@  >>> TOP-BAR CANDIDATE <<<\n",
         indent];
    }

    /*
     * UIViewController chứa view này nếu có.
     *
     * Không sử dụng private API.
     */
    UIResponder *responder = view.nextResponder;

    while (responder) {
        if ([responder isKindOfClass:[UIViewController class]]) {
            UIViewController *vc = (UIViewController *)responder;

            [output appendFormat:
             @"%@  controller=%@\n",
             indent,
             NSStringFromClass([vc class])];

            break;
        }

        responder = [responder nextResponder];
    }

    NSArray<UIView *> *subviews = view.subviews;

    for (UIView *subview in subviews) {
        SHADumpView(
            subview,
            output,
            depth + 1
        );
    }
}

#pragma mark - Window Dump

static void SHADumpWindow(
    UIWindow *window,
    NSMutableString *output,
    NSUInteger index
) {
    if (!window)
        return;

    [output appendString:
     @"\n============================================================\n"];

    [output appendFormat:
     @"WINDOW #%lu\n",
     (unsigned long)index];

    [output appendString:
     @"============================================================\n"];

    [output appendFormat:
     @"class=%@\n",
     NSStringFromClass([window class])];

    [output appendFormat:
     @"frame=%@\n",
     SHAFrameString(window.frame)];

    [output appendFormat:
     @"bounds=%@\n",
     SHABoundsString(window.bounds)];

    [output appendFormat:
     @"safeArea=%@\n",
     SHASafeAreaString(window.safeAreaInsets)];

    [output appendFormat:
     @"hidden=%@\n",
     window.hidden ? @"YES" : @"NO"];

    [output appendFormat:
     @"alpha=%.2f\n",
     window.alpha];

    [output appendFormat:
     @"windowLevel=%.1f\n",
     window.windowLevel];

    [output appendFormat:
     @"keyWindow=%@\n",
     window.isKeyWindow ? @"YES" : @"NO"];

    [output appendFormat:
     @"rootViewController=%@\n",
     window.rootViewController
        ? NSStringFromClass([window.rootViewController class])
        : @"nil"];

    if (window.rootViewController) {
        [output appendString:
         @"\n--- VIEW CONTROLLER TREE ---\n"];

        SHADumpViewController(
            window.rootViewController,
            output,
            0
        );
    }

    gSHAViewCount = 0;

    [output appendString:
     @"\n--- VIEW HIERARCHY ---\n"];

    SHADumpView(
        window,
        output,
        0
    );

    if (gSHAViewCount >= SHA_MAX_VIEWS) {
        [output appendFormat:
         @"\n*** VIEW LIMIT REACHED: %d ***\n",
         SHA_MAX_VIEWS];
    }
}

#pragma mark - Main Dump

static void SHAPerformDump(void) {

    dispatch_async(dispatch_get_main_queue(), ^{

        UIApplication *application =
            [UIApplication sharedApplication];

        NSMutableString *output =
            [NSMutableString string];

        NSString *bundleID =
            [[NSBundle mainBundle] bundleIdentifier];

        NSString *appName =
            [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];

        if (!appName.length) {
            appName =
                [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
        }

        [output appendString:
         @"============================================================\n"];

        [output appendString:
         @"STATUS/HIERARCHY DEBUG DUMP\n"];

        [output appendString:
         @"============================================================\n"];

        [output appendFormat:
         @"App: %@\n",
         appName ?: @"Unknown"];

        [output appendFormat:
         @"Bundle ID: %@\n",
         bundleID ?: @"Unknown"];

        [output appendFormat:
         @"iOS: %@\n",
         UIDevice.currentDevice.systemVersion];

        [output appendFormat:
         @"Device: %@\n",
         UIDevice.currentDevice.model];

        [output appendFormat:
         @"Screen bounds: %@\n",
         SHAFrameString(UIScreen.mainScreen.bounds)];

        [output appendFormat:
         @"Screen scale: %.2f\n",
         UIScreen.mainScreen.scale];

        [output appendString:
         @"\n"];

        NSArray<UIWindowScene *> *scenes = [NSMutableArray array];

        for (UIScene *scene in application.connectedScenes) {

            if (![scene isKindOfClass:[UIWindowScene class]])
                continue;

            UIWindowScene *windowScene =
                (UIWindowScene *)scene;

            if (windowScene.activationState ==
                UISceneActivationStateUnattached) {
                continue;
            }

            [(NSMutableArray *)scenes addObject:windowScene];
        }

        NSUInteger sceneIndex = 0;

        for (UIWindowScene *scene in scenes) {

            sceneIndex++;

            [output appendString:
             @"\n############################################################\n"];

            [output appendFormat:
             @"SCENE #%lu\n",
             (unsigned long)sceneIndex];

            [output appendString:
             @"############################################################\n"];

            [output appendFormat:
             @"sceneClass=%@\n",
             NSStringFromClass([scene class])];

            [output appendFormat:
             @"activationState=%ld\n",
             (long)scene.activationState];

            [output appendFormat:
             @"interfaceOrientation=%ld\n",
             (long)scene.interfaceOrientation];

            NSArray<UIWindow *> *windows =
                scene.windows;

            [output appendFormat:
             @"windows=%lu\n",
             (unsigned long)windows.count];

            NSUInteger windowIndex = 0;

            for (UIWindow *window in windows) {

                windowIndex++;

                SHADumpWindow(
                    window,
                    output,
                    windowIndex
                );
            }
        }

        [output appendString:
         @"\n============================================================\n"];

        [output appendFormat:
         @"TOTAL SCENES: %lu\n",
         (unsigned long)scenes.count];

        [output appendString:
         @"============================================================\n"];

        /*
         * Chọn file theo Bundle ID.
         */
        NSString *filename = nil;

        if ([bundleID isEqualToString:@"com.google.ios.youtube"]) {

            filename =
                @"/var/mobile/Media/SHA-YouTubeHierarchy.txt";

        } else if ([bundleID isEqualToString:@"com.facebook.Facebook"]) {

            filename =
                @"/var/mobile/Media/SHA-FacebookHierarchy.txt";

        } else {

            filename =
                @"/var/mobile/Media/SHA-AppHierarchy.txt";
        }

        NSError *error = nil;

        BOOL success =
            [output writeToFile:filename
                     atomically:YES
                       encoding:NSUTF8StringEncoding
                          error:&error];

        if (success) {

            NSLog(@"[SHA-DUMP] Dump written: %@",
                  filename);

            NSLog(@"[SHA-DUMP] Views dumped: %lu",
                  (unsigned long)gSHAViewCount);

        } else {

            NSLog(@"[SHA-DUMP] ERROR writing %@: %@",
                  filename,
                  error);
        }
    });
}

#pragma mark - Lifecycle

static void SHAAppBecameActive(
    NSNotification *notification
) {

    /*
     * Chờ app dựng xong UI rồi mới dump.
     */
    dispatch_after(
        dispatch_time(
            DISPATCH_TIME_NOW,
            (int64_t)(2.0 * NSEC_PER_SEC)
        ),
        dispatch_get_main_queue(),
        ^{
            SHAPerformDump();
        }
    );
}

#pragma mark - Constructor

%ctor {

    @autoreleasepool {

        /*
         * Chỉ đăng ký notification.
         * Không hook UIView.
         * Không thay đổi geometry.
         */
        [[NSNotificationCenter defaultCenter]
            addObserverForName:UIApplicationDidBecomeActiveNotification
                        object:nil
                         queue:[NSOperationQueue mainQueue]
                    usingBlock:^(NSNotification *note) {

            SHAAppBecameActive(note);
        }];

        NSLog(@"[SHA-DUMP] Loaded into %@",
              [[NSBundle mainBundle] bundleIdentifier]);
    }
}
