#import "NSMetadataItem+SL.h"
#import "AppDelegate.h"
#import "NSNumber+SL.h"

@implementation NSMetadataItem (SL)

- (NSDate *)currentDate {
	NSString *currentDateAttribute = [(AppDelegate *)[NSApp delegate] currentDateAttribute];
	return [self valueForAttribute:currentDateAttribute];
}

- (NSImage *)icon {
	NSString *filename = [self valueForAttribute:(NSString *)kMDItemPath];
	return [[NSWorkspace sharedWorkspace] iconForFile:filename];
}

- (NSString *)prettySize {
	NSNumber *bytesNumber = [self valueForAttribute:(NSString *)kMDItemFSSize];
	return [bytesNumber prettyBytes];
}

@end
