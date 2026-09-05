#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import "RightRegion.h"

@interface _UIStatusBar : UIView
@end

@interface UIApplication (RSSScreenshot)
- (void)takeScreenshot;
@end

static char RSSAttachedKey;
static BOOL RSSDisabled;

// A separate, retained target/delegate; never make a recognizer its own delegate.
@interface RSSGestureHandler : NSObject <UIGestureRecognizerDelegate>
- (void)swiped:(UISwipeGestureRecognizer *)gesture;
@end

@implementation RSSGestureHandler
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gesture shouldReceiveTouch:(UITouch *)touch {
    UIView *view = gesture.view;
    if (RSSDisabled || !view.window || view.hidden || view.alpha < 0.01) return NO;
    CGPoint point = [touch locationInView:view];
    CGRect bounds = view.bounds;
    return RSSInRightRegion(point.x - CGRectGetMinX(bounds),
                            point.y - CGRectGetMinY(bounds),
                            CGRectGetWidth(bounds), CGRectGetHeight(bounds));
}

- (void)swiped:(UISwipeGestureRecognizer *)gesture {
    if (RSSDisabled || gesture.state != UIGestureRecognizerStateRecognized || !gesture.view.window) return;
    // Leave touch handling before requesting the system screenshot UI.
    dispatch_async(dispatch_get_main_queue(), ^{
        if (RSSDisabled) return;
        @try {
            UIApplication *app = [UIApplication sharedApplication];
            if (![app isKindOfClass:NSClassFromString(@"SpringBoard")] ||
                ![app respondsToSelector:@selector(takeScreenshot)]) return;
            NSMethodSignature *signature = [app methodSignatureForSelector:@selector(takeScreenshot)];
            if (signature.numberOfArguments != 2 || strcmp(signature.methodReturnType, @encode(void)) != 0) return;
            [app takeScreenshot];
        } @catch (NSException *exception) {
            RSSDisabled = YES;
            NSLog(@"[RightStatusShot] Disabled after screenshot exception: %@", exception);
        }
    });
}
@end

%group RSSStatusBar
%hook _UIStatusBar
- (void)didMoveToWindow {
    %orig;
    if (RSSDisabled || ![NSThread isMainThread] || !self.window ||
        objc_getAssociatedObject(self, &RSSAttachedKey)) return;
    @try {
        static RSSGestureHandler *handler;
        static dispatch_once_t once;
        dispatch_once(&once, ^{ handler = [RSSGestureHandler new]; });
        UISwipeGestureRecognizer *swipe = [[UISwipeGestureRecognizer alloc]
            initWithTarget:handler action:@selector(swiped:)];
        swipe.direction = UISwipeGestureRecognizerDirectionRight;
        swipe.numberOfTouchesRequired = 1;
        swipe.cancelsTouchesInView = NO;
        swipe.delaysTouchesBegan = NO;
        swipe.delaysTouchesEnded = NO;
        swipe.delegate = handler;
        [self addGestureRecognizer:swipe];
        objc_setAssociatedObject(self, &RSSAttachedKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    } @catch (NSException *exception) {
        RSSDisabled = YES;
        NSLog(@"[RightStatusShot] Disabled after setup exception: %@", exception);
    }
}
%end
%end

%ctor {
    @autoreleasepool {
        if ([[NSBundle mainBundle].bundleIdentifier isEqualToString:@"com.apple.springboard"] &&
            [NSClassFromString(@"_UIStatusBar") isSubclassOfClass:[UIView class]]) {
            %init(RSSStatusBar);
        }
    }
}
