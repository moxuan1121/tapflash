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

@interface SBVolumeHardwareButtonActions : NSObject
- (void)volumeDecreasePressDownWithModifiers:(long long)modifiers;
@end

extern "C" BOOL MRMediaRemoteSendCommand(NSInteger command, NSDictionary *userInfo);

static AVFlashlight *gTapFlashlight = nil;
static NSTimeInterval gLastVolumeDownPress;
static NSUInteger gVolumeDownPressCount;
static NSUInteger gVolumeDownSequence;
static const NSTimeInterval kDoubleVolumeDownThreshold = 0.5;
static const NSTimeInterval kVolumeDownConfirmationDelay = 0.4;

static void TapFlashToggleFlashlight(void) {
    AVFlashlight *flashlight = gTapFlashlight;
    if (!flashlight) {
        return;
    }

    const float currentLevel = [flashlight flashlightLevel];
    [flashlight setFlashlightLevel:(currentLevel > 0.0f ? 0.0f : 1.0f)
                         withError:nil];
}

static void TapFlashTogglePlayback(void) {
    MRMediaRemoteSendCommand(2, nil);
}

static void TapFlashHandleVolumeDownPress(void) {
    NSTimeInterval now = NSProcessInfo.processInfo.systemUptime;
    if (!gVolumeDownPressCount || now - gLastVolumeDownPress > kDoubleVolumeDownThreshold)
        gVolumeDownPressCount = 0;
    gLastVolumeDownPress = now;
    gVolumeDownPressCount++;
    NSUInteger sequence = ++gVolumeDownSequence;

    if (gVolumeDownPressCount == 2) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kVolumeDownConfirmationDelay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (sequence != gVolumeDownSequence || gVolumeDownPressCount != 2) return;
            gVolumeDownPressCount = 0;
            gLastVolumeDownPress = 0;
            notify_post("com.moxuan.regionshot/AICamera");
        });
        return;
    }

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kDoubleVolumeDownThreshold * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (sequence != gVolumeDownSequence) return;
        gVolumeDownPressCount = 0;
        gLastVolumeDownPress = 0;
    });
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


%hook SBVolumeHardwareButtonActions

- (void)volumeDecreasePressDownWithModifiers:(long long)modifiers {
    %orig;
    TapFlashHandleVolumeDownPress();
}

%end
