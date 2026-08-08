#include <Foundation/Foundation.h>
#include <UIKit/UIKit.h>

@interface SBUIFlashlightController
+ (instancetype)sharedInstance;
- (void)toggleFlashlight;
@end

@interface SBMediaController
+ (instancetype)sharedInstance;
- (void)togglePlayPause;
@end

@interface SBLockHardwareButtonActions
- (void)performInitialButtonDownActions;
@end

static NSUInteger lockClickCount = 0;
static NSUInteger lockClickGeneration = 0;

static void ToggleFlashlight(void) {
    [[%c(SBUIFlashlightController) sharedInstance] toggleFlashlight];
}

static void TogglePlayback(void) {
    [[%c(SBMediaController) sharedInstance] togglePlayPause];
}

// iOS 15 invokes this once for every physical side-button press, before the
// system resolves whether the sequence is a single, double, or triple click.
static void RecordLockButtonPress(void) {
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

%hook SBLockHardwareButtonActions

- (void)performInitialButtonDownActions {
    %orig;
    RecordLockButtonPress();
}

%end
