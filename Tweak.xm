#include <Foundation/Foundation.h>
#include <UIKit/UIKit.h>
#include <objc/message.h>

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
        Class controllerClass = NSClassFromString(@"SBUIFlashlightController");
        SEL sharedInstance = NSSelectorFromString(@"sharedInstance");
        SEL level = NSSelectorFromString(@"level");
        SEL setLevel = NSSelectorFromString(@"setLevel:");

        if (!controllerClass ||
            ![(id)controllerClass respondsToSelector:sharedInstance]) {
            return;
        }

        id controller = ((id (*)(id, SEL))objc_msgSend)((id)controllerClass, sharedInstance);
        if (!controller ||
            ![controller respondsToSelector:level] ||
            ![controller respondsToSelector:setLevel]) {
            return;
        }

        const NSInteger currentLevel =
            ((NSInteger (*)(id, SEL))objc_msgSend)(controller, level);
        const NSInteger newLevel = currentLevel == 0 ? 1 : 0;

        ((void (*)(id, SEL, NSInteger))objc_msgSend)(controller, setLevel, newLevel);
    } @catch (NSException *exception) {
        // The selectors were verified on the target iOS 15.6 device.
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
            // Media controller is still being profiled on the target device.
            PlayDiagnosticFeedback();
        } else if (clicks >= 3) {
            ToggleFlashlight();
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
