#include <Foundation/Foundation.h>
#include <UIKit/UIKit.h>

@interface SBUIFlashlightController : NSObject
+ (instancetype)sharedInstance;
- (NSUInteger)level;
- (void)setLevel:(NSUInteger)level;
@end

static NSUInteger lockClickCount = 0;
static NSUInteger lockClickGeneration = 0;

static void PlayDiagnosticFeedback(void) {
    UIImpactFeedbackGenerator *generator =
        [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];
    [generator prepare];
    [generator impactOccurred];
}

static void ToggleFlashlight(void) {
    @try {
        SBUIFlashlightController *controller = [SBUIFlashlightController sharedInstance];
        const NSUInteger newLevel = controller.level == 0 ? 1 : 0;
        [controller setLevel:newLevel];
    } @catch (NSException *exception) {
        // The interface and the existing singleton were verified on the device.
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
            PlayDiagnosticFeedback();
        } else if (clicks >= 3) {
            // Execute 3 seconds after the final press, outside the side-button flow.
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.30 * NSEC_PER_SEC)),
                           dispatch_get_main_queue(), ^{
                if (generation == lockClickGeneration) {
                    ToggleFlashlight();
                }
            });
        }
    });
}

%hook SpringBoard

- (BOOL)_handlePhysicalButtonEvent:(UIPressesEvent *)event {
    UIPress *press = event.allPresses.anyObject;

    if (press && press.type == 104 && press.force > 0.0) {
        RecordSideButtonPress();
    }

    return %orig;
}

%end
