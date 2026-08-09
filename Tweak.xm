#include <Foundation/Foundation.h>

@interface AVFlashlight : NSObject
- (float)flashlightLevel;
- (void)setFlashlightLevel:(float)level withError:(NSError **)error;
@end

@interface SBLockHardwareButton : NSObject
- (void)doublePress:(id)press;
- (void)triplePress:(id)press;
@end

extern BOOL MRMediaRemoteSendCommand(NSInteger command, NSDictionary *userInfo);

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
    // MediaRemote command 2 is TogglePlayPause.
    MRMediaRemoteSendCommand(2, nil);
}

%hook AVFlashlight

- (instancetype)init {
    // SpringBoard creates the valid, system-managed flashlight instance.
    // Keep and reuse it instead of constructing another AVFlashlight.
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
    // Intentionally do not call %orig: this replaces the system double-click action.
}

- (void)triplePress:(id)press {
    TapFlashToggleFlashlight();
    // Intentionally do not call %orig: this suppresses Accessibility Shortcut.
}

%end
