#include <Foundation/Foundation.h>
#include <UIKit/UIKit.h>
#include <objc/message.h>

static NSUInteger lockClickCount = 0;
static NSUInteger lockClickGeneration = 0;

static id SharedController(NSString *className) {
    Class controllerClass = NSClassFromString(className);
    SEL sharedInstance = NSSelectorFromString(@"sharedInstance");

    if (!controllerClass || ![(id)controllerClass respondsToSelector:sharedInstance]) {
        return nil;
    }

    return ((id (*)(id, SEL))objc_msgSend)((id)controllerClass, sharedInstance);
}

static void SendNoArgumentAction(id target, NSString *selectorName) {
    SEL selector = NSSelectorFromString(selectorName);
    if (target && [target respondsToSelector:selector]) {
        ((void (*)(id, SEL))objc_msgSend)(target, selector);
    }
}

static void ToggleFlashlight(void) {
    SendNoArgumentAction(SharedController(@"SBUIFlashlightController"),
                         @"toggleFlashlight");
}

static void TogglePlayback(void) {
    SendNoArgumentAction(SharedController(@"SBMediaController"),
                         @"togglePlayPause");
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
