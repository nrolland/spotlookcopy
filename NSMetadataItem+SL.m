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

- (NSString *)prettySize {
	NSNumber *bytesNumber = [self valueForAttribute:(NSString *)kMDItemFSSize];
	NSUInteger unit = 0;
	float bytes = [bytesNumber longValue];

	if(bytes < 1) { return @"-"; }

	while(bytes > 1024) {
		bytes = bytes / 1024.0;
		unit++;
	}
		
	if(unit > 5) { return @"HUGE"; }
	
	NSString *unitString = [[NSArray arrayWithObjects:@"Bytes", @"KB", @"MB", @"GB", @"TB", @"PB", nil] objectAtIndex:unit];
	return [NSString stringWithFormat:@"%.1f %@", (float)bytes, unitString];
}

@end
