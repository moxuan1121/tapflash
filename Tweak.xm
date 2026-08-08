#include <Foundation/Foundation.h>
#include <UIKit/UIKit.h>

@interface AVFlashlight
- (BOOL)setFlashlightLevel:(float)level withError:(NSError **)error;
@end

@interface SBLockHardwareButtonActions
- (void)performTriplePressUpActions;
@end

static BOOL flashlightEnabled = NO;

static void ToggleFlashlight(void) {
    static AVFlashlight *flashlight;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        flashlight = [[%c(AVFlashlight) alloc] init];
    });

    const float level = flashlightEnabled ? 0.0f : 1.0f;
    if ([flashlight setFlashlightLevel:level withError:nil]) {
        flashlightEnabled = !flashlightEnabled;
    }
}

%hook SBLockHardwareButtonActions

- (void)performTriplePressUpActions {
    ToggleFlashlight();
}

%end
