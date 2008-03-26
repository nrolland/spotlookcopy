//
//  NSImage+SL.m
//  SpotLook
//
//  Created by Nicolas Seriot on 26.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "NSView+SL.h"


@implementation NSView (SL)

- (NSImage *)image {
	NSBitmapImageRep *rep = [self bitmapImageRepForCachingDisplayInRect:[self frame]];
	[self cacheDisplayInRect:[self frame] toBitmapImageRep:rep];
	NSData *tiffData = [rep TIFFRepresentation];
	NSImage *image = [[NSImage alloc] initWithData:tiffData];
	return [image autorelease];
}

@end
