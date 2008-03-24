//
//  SLArrayController.m
//  SpotLook
//
//  Created by Nicolas Seriot on 17.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "SLArrayController.h"

@implementation SLArrayController

- (BOOL)isLeaf {
	return NO;
}

- (NSArray *)children {
	return [self arrangedObjects];
}

- (NSImage *)icon {
	return nil;
}

- (void) setActiveStateIfChanged:(NSNumber *)n {
}

@synthesize name;
@synthesize icon;

@end
