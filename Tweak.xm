#include <Foundation/Foundation.h>
#include <UIKit/UIKit.h>
#include <dlfcn.h>
#include <objc/message.h>

typedef BOOL (*MediaRemoteSendCommand)(int command, id userInfo);

static NSUInteger lockClickCount = 0;
static NSUInteger lockClickGeneration = 0;
static id flashlight = nil;
static BOOL flashlightEnabled = NO;

static void ToggleFlashlight(void) {
    @try {
        if (!flashlight) {
            Class flashlightClass = NSClassFromString(@"AVFlashlight");
            if (!flashlightClass) {
                return;
            }

            flashlight = [[flashlightClass alloc] init];
        }

        SEL setLevel = NSSelectorFromString(@"setFlashlightLevel:withError:");
        if (![flashlight respondsToSelector:setLevel]) {
            return;
        }

        const float level = flashlightEnabled ? 0.0f : 1.0f;
        const BOOL succeeded = ((BOOL (*)(id, SEL, float, NSError **))objc_msgSend)(
            flashlight, setLevel, level, NULL);

        if (succeeded) {
            flashlightEnabled = !flashlightEnabled;
        }
    } @catch (NSException *exception) {
        // Never allow a private API failure to crash SpringBoard.
    }
}

static void TogglePlayback(void) {
    @try {
        static BOOL didLookUpMediaRemote = NO;
        static MediaRemoteSendCommand sendCommand = NULL;

        if (!didLookUpMediaRemote) {
            didLookUpMediaRemote = YES;
            void *framework = dlopen(
                "/System/Library/PrivateFrameworks/MediaRemote.framework/MediaRemote",
                RTLD_LAZY);
            if (framework) {
                sendCommand = (MediaRemoteSendCommand)dlsym(
                    framework, "MRMediaRemoteSendCommand");
            }
        }

        // kMRTogglePlayPause is command 2. A missing framework simply does nothing.
        if (sendCommand) {
            sendCommand(2, nil);
        }
    } @catch (NSException *exception) {
        // Never allow a private API failure to crash SpringBoard.
    }
}

static void RecordSideButtonPress(void) {
    lockClickCount += 1;
    const NSUInteger generation = ++lockClickGeneration;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.70 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        if (generation != lockClickGeneration) {
            return;
        }

        const NSUInteger clicks = lockClickCount;
        lockClickCount = 0;

        if (clicks == 2) {
            TogglePlayback();
        } else if (clicks >= 3) {
            ToggleFlashlight();
        }
    });
}

%hook SpringBoard

- (BOOL)_handlePhysicalButtonEvent:(UIPressesEvent *)event {
    UIPress *press = event.allPresses.anyObject;

    // UIKit type 104 is the side/power button; force 1 means button down.
    if (press && press.type == 104 && press.force > 0.0) {
        RecordSideButtonPress();
    }

    return %orig;
}

%end
