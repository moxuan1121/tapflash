#include <Foundation/Foundation.h>
#include <UIKit/UIKit.h>

@interface AVFlashlight
- (BOOL)setFlashlightLevel:(float)level withError:(NSError **)error;
@end

@interface SBMediaController
+ (instancetype)sharedInstance;
- (void)togglePlayPause;
@end

@interface SBLockHardwareButtonActions
- (void)performFinalButtonUpActions;
@end

static BOOL flashlightEnabled = NO;
static NSUInteger lockClickCount = 0;
static NSUInteger lockClickGeneration = 0;

static void ToggleFlashlight(void) {
    static AVFlashlight *flashlight;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        flashlight = [[%c(AVFlashlight) alloc] init];
    });

    const float level = flashlightEnabled ? 0.0f : 1.0f;
    if ([flashlight setFlashlightLevel:level withError:nil]) {
        flashlightEnabled = !flashlightEnabled;
    }
}

static void TogglePlayback(void) {
    [[%c(SBMediaController) sharedInstance] togglePlayPause];
}

// On iOS 15 this is reached after every completed short side-button press,
// including the presses that form a double- or triple-click gesture.
static void RecordLockButtonClick(void) {
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

- (void)performFinalButtonUpActions {
    %orig;
    RecordLockButtonClick();
}

%end
