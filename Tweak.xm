#include <Foundation/Foundation.h>
#include <UIKit/UIKit.h>
#include <objc/runtime.h>
#include <stdio.h>
#include <string.h>

static NSUInteger lockClickCount = 0;
static NSUInteger lockClickGeneration = 0;

static BOOL IsRelevantSelector(const char *name) {
    return strstr(name, "flash") || strstr(name, "Flash") ||
           strstr(name, "torch") || strstr(name, "Torch") ||
           strstr(name, "play") || strstr(name, "Play") ||
           strstr(name, "media") || strstr(name, "Media") ||
           strstr(name, "toggle") || strstr(name, "Toggle");
}

static void WriteMethods(FILE *file, Class cls, const char *kind) {
    unsigned int count = 0;
    Method *methods = class_copyMethodList(cls, &count);

    fprintf(file, "%s methods:\n", kind);
    for (unsigned int index = 0; index < count; index++) {
        const char *name = sel_getName(method_getName(methods[index]));
        if (IsRelevantSelector(name)) {
            fprintf(file, "  %s\n", name);
        }
    }
    free(methods);
}

static void WriteClassProfile(FILE *file, NSString *className) {
    Class cls = NSClassFromString(className);
    fprintf(file, "\n%s: %s\n", className.UTF8String, cls ? "present" : "missing");

    if (cls) {
        WriteMethods(file, cls, "instance");
        WriteMethods(file, object_getClass(cls), "class");
    }
}

static void WriteRuntimeProfile(void) {
    FILE *file = fopen("/var/mobile/Library/Preferences/tapflash-runtime.txt", "w");
    if (!file) {
        return;
    }

    fprintf(file, "TapFlash 1.9.0 runtime profile\n");
    WriteClassProfile(file, @"AVFlashlight");
    WriteClassProfile(file, @"SBUIFlashlightController");
    WriteClassProfile(file, @"SBMediaController");
    WriteClassProfile(file, @"CCUIFlashlightModule");
    fclose(file);
}

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

        // Diagnostic-only: no private media or flashlight API is called here.
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

    // UIKit type 104 is the side/power button; force 1 means button down.
    if (press && press.type == 104 && press.force > 0.0) {
        RecordSideButtonPress();
    }

    return %orig;
}

%end

%ctor {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)),
                   dispatch_get_main_queue(), ^{
        WriteRuntimeProfile();
    });
}
