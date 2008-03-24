#import "NSMetadataItem+SL.h"
#import "AppDelegate.h"

@implementation NSMetadataItem (SL)

- (NSDate *)currentDate {
	NSString *currentDateAttribute = [(AppDelegate *)[NSApp delegate] currentDateAttribute];
	return [self valueForAttribute:currentDateAttribute];
}

- (NSImage *)icon {
	NSString *filename = [self valueForAttribute:(NSString *)kMDItemPath];
	return [[NSWorkspace sharedWorkspace] iconForFile:filename];
}

@end
