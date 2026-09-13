#include <Foundation/Foundation.h>
#include <notify.h>

@interface AVFlashlight : NSObject
- (float)flashlightLevel;
- (void)setFlashlightLevel:(float)level withError:(NSError **)error;
@end

@interface SBLockHardwareButton : NSObject
- (void)doublePress:(id)press;
- (void)triplePress:(id)press;
@end

static AVFlashlight *gTapFlashlight = nil;

static void TapFlashToggleFlashlight(void) {
    AVFlashlight *flashlight = gTapFlashlight;
    if (!flashlight) {
        return;
    }

    const float currentLevel = [flashlight flashlightLevel];
    [flashlight setFlashlightLevel:(currentLevel > 0.0f ? 0.0f : 1.0f)
                         withError:nil];
}

%hook AVFlashlight

- (instancetype)init {
    if (gTapFlashlight) {
        return gTapFlashlight;
    }

    AVFlashlight *flashlight = %orig;
    if (flashlight) {
        gTapFlashlight = flashlight;
    }
    return flashlight;
}

%end

%hook SBLockHardwareButton

- (void)doublePress:(id)press {
    notify_post("com.moxuan.regionshot/AICamera");
}

- (void)triplePress:(id)press {
    TapFlashToggleFlashlight();
}

%end
