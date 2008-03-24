#import <Cocoa/Cocoa.h>
#import "SLTrackView.h"


@interface NSMetadataItem (SL)

// bound in results tableview
- (NSDate *)currentDate;
- (NSImage *)icon;

@end
