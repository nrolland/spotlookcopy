#import <Cocoa/Cocoa.h>


@interface Updater : NSObject {
}

+ (Updater *)sharedInstance;
- (IBAction) checkUpdateSilentIfUpToDate:(id)sender;
- (IBAction) checkUpdateDisplayAlertIfUptodate:(id)sender;
- (IBAction) checkUpdateBypassPrefsDisplayAlertIfUptodate:(id)sender;
- (BOOL) shortVersion:(NSString *)sa isBiggerThan:(NSString *)sb;

@end
