#include <Foundation/Foundation.h>
#include <UIKit/UIKit.h>

@interface AVFlashlight : NSObject
- (float)flashlightLevel;
- (void)setFlashlightLevel:(float)level withError:(NSError **)error;
@end

@interface SBLockHardwareButton : NSObject
- (void)doublePress:(id)press;
- (void)triplePress:(id)press;
@end

@interface SpringBoard : UIApplication
- (void)applicationDidFinishLaunching:(id)application;
- (void)takeScreenshot;
@end

@interface _UIStatusBar : UIView
- (instancetype)initWithStyle:(NSInteger)style;
@end

extern "C" BOOL MRMediaRemoteSendCommand(NSInteger command, NSDictionary *userInfo);

static AVFlashlight *gTapFlashlight = nil;
static SpringBoard *gTapSpringBoard = nil;

@interface TapFlashRightStatusBarSwipeRecognizer : UISwipeGestureRecognizer <UIGestureRecognizerDelegate>
@end

@implementation TapFlashRightStatusBarSwipeRecognizer

- (instancetype)initWithTarget:(id)target action:(SEL)action {
    self = [super initWithTarget:target action:action];
    if (self) {
        self.delegate = self;
        self.direction = UISwipeGestureRecognizerDirectionRight;
        self.numberOfTouchesRequired = 1;
        self.cancelsTouchesInView = NO;
        self.delaysTouchesBegan = NO;
        self.delaysTouchesEnded = NO;
    }
    return self;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
       shouldReceiveTouch:(UITouch *)touch {
    UIView *statusBar = gestureRecognizer.view;
    if (!statusBar) {
        return NO;
    }

    const CGFloat width = CGRectGetWidth(statusBar.bounds);
    const CGPoint startPoint = [touch locationInView:statusBar];
    return width > 0.0 && startPoint.x >= width * (2.0 / 3.0);
}

@end

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

static void TapFlashTakeScreenshot(void) {
    SpringBoard *springBoard = gTapSpringBoard;
    if (!springBoard) {
        springBoard = (SpringBoard *)[UIApplication sharedApplication];
    }

    if ([springBoard respondsToSelector:@selector(takeScreenshot)]) {
        [springBoard takeScreenshot];
    }
}

%hook SpringBoard

- (void)applicationDidFinishLaunching:(id)application {
    %orig;
    gTapSpringBoard = self;
}

%end

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

%hook _UIStatusBar

- (instancetype)initWithStyle:(NSInteger)style {
    _UIStatusBar *statusBar = %orig;
    if (!statusBar) {
        return statusBar;
    }

    TapFlashRightStatusBarSwipeRecognizer *recognizer =
        [[TapFlashRightStatusBarSwipeRecognizer alloc]
            initWithTarget:statusBar
                    action:@selector(tapflash_rightStatusBarSwipe:)];
    [statusBar addGestureRecognizer:recognizer];
    return statusBar;
}

%new
- (void)tapflash_rightStatusBarSwipe:(UISwipeGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateRecognized) {
        TapFlashTakeScreenshot();
    }
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
