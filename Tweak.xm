#import <Foundation/Foundation.h>

%ctor {
    @autoreleasepool {

        NSString *bundle =
            [[NSBundle mainBundle] bundleIdentifier];

        NSString *text =
            [NSString stringWithFormat:
                @"SHAHierarchyDump loaded\n"
                 "Bundle = %@\n"
                 "PID = %d\n",
                bundle ?: @"NULL",
                getpid()
            ];

        [text writeToFile:
            @"/var/mobile/Media/SHA-DUMP-TEST.txt"
                 atomically:YES
                   encoding:NSUTF8StringEncoding
                      error:nil];
    }
}
