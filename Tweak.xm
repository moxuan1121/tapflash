#include <Foundation/Foundation.h>
#include <UIKit/UIKit.h>

static NSUInteger lockClickCount = 0;
static NSUInteger lockClickGeneration = 0;

static void PlayDiagnosticFeedback(NSUInteger impacts) {
    UIImpactFeedbackGenerator *generator =
        [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleMedium];

    [generator prepare];
    [generator impactOccurred];

    if (impacts > 1) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.12 * NSEC_PER_SEC)),
                       dispatch_get_main_queue(), ^{
            [generator impactOccurred];
        });
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
            PlayDiagnosticFeedback(1);
        } else if (clicks >= 3) {
            PlayDiagnosticFeedback(2);
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
