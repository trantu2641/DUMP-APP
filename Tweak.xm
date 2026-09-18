#import <Foundation/Foundation.h>
#import <unistd.h>

__attribute__((constructor))
static void SHAInit(void)
{
    @autoreleasepool
    {
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

        NSArray<NSString *> *paths = @[
            @"/var/mobile/Media/SHA-DUMP-TEST.txt",
            @"/tmp/SHA-DUMP-TEST.txt"
        ];

        for (NSString *path in paths)
        {
            [text writeToFile:path
                   atomically:YES
                     encoding:NSUTF8StringEncoding
                        error:nil];
        }
    }
}
