//
//  SLArrayController.h
//  SpotLook
//
//  Created by Nicolas Seriot on 17.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SLArrayController : NSArrayController {
	NSString *name;
	NSImage *icon;
}

@property (retain) NSString *name;
@property (retain) NSImage *icon;

@end
