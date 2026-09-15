#include <Foundation/Foundation.h>
#include <notify.h>
#include <dlfcn.h>

@interface AVFlashlight : NSObject
- (float)flashlightLevel;
- (void)setFlashlightLevel:(float)level withError:(NSError **)error;
@end

@interface SBLockHardwareButton : NSObject
- (void)doublePress:(id)press;
- (void)triplePress:(id)press;
@end

static AVFlashlight *gSideButtonFlashlight;

static NSString *SBAActionForPress(NSString *key, NSString *fallback) {
    NSDictionary *values = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.moxuan.sidebuttonactions.plist"];
    NSString *value = [values[key] isKindOfClass:NSString.class] ? values[key] : nil;
    return value.length ? value : fallback;
}

static void SBA_SendAction(NSString *action) {
    if ([action isEqualToString:@"flashlight"]) {
        if (!gSideButtonFlashlight) return;
        [gSideButtonFlashlight setFlashlightLevel:([gSideButtonFlashlight flashlightLevel] > 0.0f ? 0.0f : 1.0f) withError:nil];
    } else if ([action isEqualToString:@"aiwindow"]) {
        notify_post("com.moxuan.regionshot/AIWindow");
    } else if ([action isEqualToString:@"aicamera"]) {
        notify_post("com.moxuan.regionshot/AICamera");
    } else if ([action isEqualToString:@"playpause"]) {
        void (*sendCommand)(int) = (void (*)(int))dlsym(RTLD_DEFAULT, "MRMediaRemoteSendCommand");
        if (sendCommand) sendCommand(2);
    }
}

%hook AVFlashlight
- (instancetype)init {
    if (gSideButtonFlashlight) return gSideButtonFlashlight;
    AVFlashlight *flashlight = %orig;
    if (flashlight) gSideButtonFlashlight = flashlight;
    return flashlight;
}
%end

%hook SBLockHardwareButton
- (void)doublePress:(id)press {
    SBA_SendAction(SBAActionForPress(@"DoublePressAction", @"aicamera"));
}
- (void)triplePress:(id)press {
    SBA_SendAction(SBAActionForPress(@"TriplePressAction", @"flashlight"));
}
%end
