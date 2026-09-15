#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>

@interface SBASettingsController : PSListController
@end

@implementation SBASettingsController
- (NSArray *)specifiers {
    if (_specifiers) return _specifiers;
    _specifiers = [self loadSpecifiersFromPlistName:@"SideButtonActionsPrefs" target:self];
    return _specifiers;
}
@end
