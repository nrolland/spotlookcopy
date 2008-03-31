// 
//  SLTrackSet.m
//  SpotLook
//
//  Created by Nicolas Seriot on 04.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "SLTrackSet.h"

#import "SLTrack.h"

@implementation SLTrackSet 

static NSImage *folderImage = nil;

@dynamic name;
@dynamic tracks;

- (void)setActiveStateIfChanged:(NSNumber *)n {
	[self.tracks makeObjectsPerformSelector:@selector(setActiveStateIfChanged:) withObject:n];
}

- (id)controller {
	return nil;
}

- (NSArray *)children {
	return [self.tracks allObjects]; // TODO: use sort descriptor?
}

- (NSImage *)icon {
	if(folderImage == nil) {
		folderImage = [[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericFolderIcon)] retain];
		[folderImage setSize:NSMakeSize(16,16)];
	}
	
	if(icon == nil) {
		[self setValue:folderImage forKey:@"icon"];
	}
	
	return icon;
}

- (BOOL)isLeaf {
	return YES;
}

- (BOOL)hasUTI {
	return NO;
}

@end
