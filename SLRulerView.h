//
//  SLRulerView.h
//  SpotLook
//
//  Created by Nicolas Seriot on 03.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SLRulerView : NSRulerView {
	NSDictionary *textAttributes;
	NSDictionary *noAntialiasingTextAttributes;

    NSRect rubberbandRect;
}

@end
