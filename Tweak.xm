#import <Foundation/Foundation.h>
#import <unistd.h>

%ctor {
    @autoreleasepool {

        NSString *bundle =
            [[NSBundle mainBundle] bundleIdentifier];

        NSString *text =
            [NSString stringWithFormat:
                @"SHAHierarchyDump LOADED\n"
                 "Bundle: %@\n"
                 "PID: %d\n",
                bundle ?: @"NULL",
                getpid()
            ];

        NSString *path =
            @"/var/mobile/Media/SHA-DUMP-TEST.txt";

        [text writeToFile:path
              atomically:YES
                encoding:NSUTF8StringEncoding
                   error:nil];
    }
}
