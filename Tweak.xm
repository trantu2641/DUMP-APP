#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

#define SHA_MAX_DEPTH 40
#define SHA_MAX_VIEWS 5000

#pragma mark - Helpers

static NSString *SHAIndent(NSUInteger depth) {
    NSMutableString *result = [NSMutableString string];

    for (NSUInteger i = 0; i < depth; i++) {
        [result appendString:@"  "];
    }

    return result;
}

static NSString *SHAFrameString(CGRect frame) {
    return [NSString stringWithFormat:
        @"(x=%.1f y=%.1f w=%.1f h=%.1f)",
        frame.origin.x,
        frame.origin.y,
        frame.size.width,
        frame.size.height
    ];
}

static NSString *SHABoundsString(CGRect bounds) {
    return [NSString stringWithFormat:
        @"(x=%.1f y=%.1f w=%.1f h=%.1f)",
        bounds.origin.x,
        bounds.origin.y,
        bounds.size.width,
        bounds.size.height
    ];
}

static NSString *SHASafeAreaString(UIEdgeInsets insets) {
    return [NSString stringWithFormat:
        @"(top=%.1f left=%.1f bottom=%.1f right=%.1f)",
        insets.top,
        insets.left,
        insets.bottom,
        insets.right
    ];
}

static BOOL SHAIsTopBarCandidate(CGRect frame) {

    CGFloat y = frame.origin.y;
    CGFloat height = frame.size.height;

    /*
     * Đánh dấu các view có khả năng là
     * status bar / top container / top UI.
     */
    BOOL heightMatch =
        (height >= 40.0 && height <= 55.0);

    BOOL yMatch =
        (y >= -5.0 && y <= 55.0);

    return heightMatch && yMatch;
}

#pragma mark - View Counter

static NSUInteger gSHAViewCount = 0;

#pragma mark - View Hierarchy

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

    NSString *indent =
        SHAIndent(depth);

    CGRect frame =
        view.frame;

    CGRect bounds =
        view.bounds;

    UIEdgeInsets safeArea =
        view.safeAreaInsets;

    BOOL topBar =
        SHAIsTopBarCandidate(frame);

    [output appendFormat:
        @"%@VIEW #%lu %@\n",
        indent,
        (unsigned long)gSHAViewCount,
        NSStringFromClass([view class])
    ];

    [output appendFormat:
        @"%@  frame=%@\n",
        indent,
        SHAFrameString(frame)
    ];

    [output appendFormat:
        @"%@  bounds=%@\n",
        indent,
        SHABoundsString(bounds)
    ];

    [output appendFormat:
        @"%@  safeArea=%@\n",
        indent,
        SHASafeAreaString(safeArea)
    ];

    [output appendFormat:
        @"%@  hidden=%@ alpha=%.2f\n",
        indent,
        view.hidden ? @"YES" : @"NO",
        view.alpha
    ];

    [output appendFormat:
        @"%@  userInteraction=%@\n",
        indent,
        view.userInteractionEnabled ? @"YES" : @"NO"
    ];

    [output appendFormat:
        @"%@  clipsToBounds=%@\n",
        indent,
        view.clipsToBounds ? @"YES" : @"NO"
    ];

    [output appendFormat:
        @"%@  subviews=%lu\n",
        indent,
        (unsigned long)view.subviews.count
    ];

    /*
     * Đánh dấu view nghi ngờ là top UI.
     */
    if (topBar) {

        [output appendFormat:
            @"%@  >>> TOP-BAR CANDIDATE <<<\n",
            indent
        ];
    }

    /*
     * Tìm UIViewController chứa view này.
     *
     * Dùng responder chain, không dùng private API.
     */
    UIResponder *responder =
        [view nextResponder];

    while (responder != nil) {

        if ([responder isKindOfClass:
                [UIViewController class]]) {

            UIViewController *controller =
                (UIViewController *)responder;

            [output appendFormat:
                @"%@  controller=%@\n",
                indent,
                NSStringFromClass(
                    [controller class]
                )
            ];

            break;
        }

        responder =
            [responder nextResponder];
    }

    /*
     * Dump tất cả subviews.
     */
    NSArray *subviews =
        view.subviews;

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
        @"\n============================================================\n"
    ];

    [output appendFormat:
        @"WINDOW #%lu\n",
        (unsigned long)index
    ];

    [output appendString:
        @"============================================================\n"
    ];

    [output appendFormat:
        @"class=%@\n",
        NSStringFromClass([window class])
    ];

    [output appendFormat:
        @"frame=%@\n",
        SHAFrameString(window.frame)
    ];

    [output appendFormat:
        @"bounds=%@\n",
        SHABoundsString(window.bounds)
    ];

    [output appendFormat:
        @"safeArea=%@\n",
        SHASafeAreaString(window.safeAreaInsets)
    ];

    [output appendFormat:
        @"hidden=%@\n",
        window.hidden ? @"YES" : @"NO"
    ];

    [output appendFormat:
        @"alpha=%.2f\n",
        window.alpha
    ];

    [output appendFormat:
        @"windowLevel=%.1f\n",
        window.windowLevel
    ];

    [output appendFormat:
        @"keyWindow=%@\n",
        window.isKeyWindow ? @"YES" : @"NO"
    ];

    if (window.rootViewController) {

        [output appendFormat:
            @"rootViewController=%@\n",
            NSStringFromClass(
                [window.rootViewController class]
            )
        ];

    } else {

        [output appendString:
            @"rootViewController=nil\n"
        ];
    }

    [output appendString:
        @"\n--- VIEW HIERARCHY ---\n"
    ];

    gSHAViewCount = 0;

    SHADumpView(
        window,
        output,
        0
    );

    if (gSHAViewCount >= SHA_MAX_VIEWS) {

        [output appendFormat:
            @"\n*** VIEW LIMIT REACHED: %d ***\n",
            SHA_MAX_VIEWS
        ];
    }
}

#pragma mark - Main Dump

static void SHAPerformDump(void) {

    dispatch_async(
        dispatch_get_main_queue(),
        ^{

            UIApplication *application =
                [UIApplication sharedApplication];

            NSString *bundleID =
                [[NSBundle mainBundle]
                    bundleIdentifier];

            NSString *appName =
                [[NSBundle mainBundle]
                    objectForInfoDictionaryKey:
                        @"CFBundleDisplayName"];

            if (!appName.length) {

                appName =
                    [[NSBundle mainBundle]
                        objectForInfoDictionaryKey:
                            @"CFBundleName"];
            }

            NSMutableString *output =
                [NSMutableString string];

            [output appendString:
                @"============================================================\n"
            ];

            [output appendString:
                @"SHA HIERARCHY DEBUG DUMP\n"
            ];

            [output appendString:
                @"============================================================\n"
            ];

            [output appendFormat:
                @"App: %@\n",
                appName ?: @"Unknown"
            ];

            [output appendFormat:
                @"Bundle ID: %@\n",
                bundleID ?: @"Unknown"
            ];

            [output appendFormat:
                @"iOS: %@\n",
                UIDevice.currentDevice.systemVersion
            ];

            [output appendFormat:
                @"Device: %@\n",
                UIDevice.currentDevice.model
            ];

            [output appendFormat:
                @"Screen: %@\n",
                SHAFrameString(
                    UIScreen.mainScreen.bounds
                )
            ];

            [output appendFormat:
                @"Scale: %.2f\n",
                UIScreen.mainScreen.scale
            ];

            [output appendString:@"\n"];

            /*
             * Lấy tất cả UIWindowScene đang hoạt động.
             */
            NSArray *connectedScenes =
                application.connectedScenes.allObjects;

            NSUInteger sceneIndex = 0;

            for (UIScene *scene
                 in connectedScenes) {

                if (![scene
                    isKindOfClass:
                        [UIWindowScene class]]) {

                    continue;
                }

                UIWindowScene *windowScene =
                    (UIWindowScene *)scene;

                if (windowScene.activationState ==
                    UISceneActivationStateUnattached) {

                    continue;
                }

                sceneIndex++;

                [output appendString:
                    @"\n############################################################\n"
                ];

                [output appendFormat:
                    @"SCENE #%lu\n",
                    (unsigned long)sceneIndex
                ];

                [output appendString:
                    @"############################################################\n"
                ];

                [output appendFormat:
                    @"class=%@\n",
                    NSStringFromClass(
                        [windowScene class]
                    )
                ];

                [output appendFormat:
                    @"activationState=%ld\n",
                    (long)windowScene.activationState
                ];

                [output appendFormat:
                    @"orientation=%ld\n",
                    (long)windowScene.interfaceOrientation
                ];

                NSArray *windows =
                    windowScene.windows;

                [output appendFormat:
                    @"windows=%lu\n",
                    (unsigned long)windows.count
                ];

                NSUInteger windowIndex = 0;

                for (UIWindow *window
                     in windows) {

                    windowIndex++;

                    SHADumpWindow(
                        window,
                        output,
                        windowIndex
                    );
                }
            }

            [output appendString:
                @"\n============================================================\n"
            ];

            [output appendFormat:
                @"TOTAL SCENES: %lu\n",
                (unsigned long)sceneIndex
            ];

            [output appendFormat:
                @"TOTAL VIEWS IN LAST WINDOW: %lu\n",
                (unsigned long)gSHAViewCount
            ];

            [output appendString:
                @"============================================================\n"
            ];

            /*
             * Chọn file output.
             */
            NSString *path = nil;

            if ([bundleID
                isEqualToString:
                    @"com.google.ios.youtube"]) {

                path =
                    @"/var/mobile/Media/SHA-YouTubeHierarchy.txt";

            } else if ([bundleID
                isEqualToString:
                    @"com.facebook.Facebook"]) {

                path =
                    @"/var/mobile/Media/SHA-FacebookHierarchy.txt";

            } else {

                path =
                    @"/var/mobile/Media/SHA-AppHierarchy.txt";
            }

            NSError *error = nil;

            BOOL success =
                [output writeToFile:path
                         atomically:YES
                           encoding:NSUTF8StringEncoding
                              error:&error];

            if (success) {

                NSLog(
                    @"[SHA-DUMP] SUCCESS: %@",
                    path
                );

            } else {

                NSLog(
                    @"[SHA-DUMP] ERROR: %@",
                    error
                );
            }
        }
    );
}

#pragma mark - Constructor

%ctor {

    @autoreleasepool {

        NSString *bundleID =
            [[NSBundle mainBundle]
                bundleIdentifier];

        /*
         * Chỉ hoạt động với YouTube/Facebook.
         */
        BOOL isYouTube =
            [bundleID
                isEqualToString:
                    @"com.google.ios.youtube"];

        BOOL isFacebook =
            [bundleID
                isEqualToString:
                    @"com.facebook.Facebook"];

        if (!isYouTube && !isFacebook) {
            return;
        }

        /*
         * FILE TEST:
         *
         * Nếu file này xuất hiện thì chứng minh
         * dylib thực sự đã được load.
         */
        NSString *loadedPath = nil;

        if (isYouTube) {

            loadedPath =
                @"/var/mobile/Media/SHA-YOUTUBE-LOADED.txt";

        } else {

            loadedPath =
                @"/var/mobile/Media/SHA-FACEBOOK-LOADED.txt";
        }

        NSString *loadedText =
            [NSString stringWithFormat:
                @"SHAHierarchyDump loaded successfully\n"
                 "Bundle ID: %@\n"
                 "iOS: %@\n"
                 "Date: %@\n",
                bundleID ?: @"Unknown",
                UIDevice.currentDevice.systemVersion,
                [NSDate date]
            ];

        NSError *writeError = nil;

        [loadedText writeToFile:
            loadedPath
                     atomically:YES
                       encoding:NSUTF8StringEncoding
                          error:&writeError];

        /*
         * Dump sau khi app dựng UI.
         */
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                (int64_t)(3 * NSEC_PER_SEC)
            ),
            dispatch_get_main_queue(),
            ^{
                SHAPerformDump();
            }
        );

        /*
         * Dump mỗi lần app active.
         */
        [[NSNotificationCenter defaultCenter]
            addObserverForName:
                UIApplicationDidBecomeActiveNotification
            object:nil
            queue:[NSOperationQueue mainQueue]
            usingBlock:
                ^(NSNotification *notification) {

                    (void)notification;

                    dispatch_after(
                        dispatch_time(
                            DISPATCH_TIME_NOW,
                            (int64_t)(2 * NSEC_PER_SEC)
                        ),
                        dispatch_get_main_queue(),
                        ^{
                            SHAPerformDump();
                        }
                    );
                }
        ];

        NSLog(
            @"[SHA-DUMP] Loaded into %@",
            bundleID
        );
    }
}
