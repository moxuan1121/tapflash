#include <Foundation/Foundation.h>

@interface AVFlashlight : NSObject
- (float)flashlightLevel;
- (void)setFlashlightLevel:(float)level withError:(NSError **)error;
@end

@interface SBLockHardwareButton : NSObject
- (void)doublePress:(id)press;
- (void)triplePress:(id)press;
@end

extern "C" BOOL MRMediaRemoteSendCommand(NSInteger command, NSDictionary *userInfo);

static AVFlashlight *gTapFlashlight = nil;

static void TapFlashToggleFlashlight(void) {
    AVFlashlight *flashlight = gTapFlashlight;
    if (!flashlight) {
        return;
    }

    const float currentLevel = [flashlight flashlightLevel];
    NSError *error = nil;
    [flashlight setFlashlightLevel:(currentLevel > 0.0f ? 0.0f : 1.0f)
                         withError:&error];
}

static void TapFlashTogglePlayback(void) {
    MRMediaRemoteSendCommand(2, nil);
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
    TapFlashTogglePlayback();
}

- (void)triplePress:(id)press {
    TapFlashToggleFlashlight();
}

%end
