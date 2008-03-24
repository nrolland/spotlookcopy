//
//  SLTableView.m
//  SpotLook
//
//  Created by Nicolas Seriot on 09.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "SLTableView.h"
#import "AppDelegate.h"

@implementation SLTableView

- (void)keyDown:(NSEvent *)event {
	//NSLog(@"SLTableView event %@", event);
	BOOL keyWasHandled = NO;

	if([[event charactersIgnoringModifiers] characterAtIndex:0] == ' ') {
		/*keyWasHandled = */[(AppDelegate *)[self delegate] openQuickLook:self];
		keyWasHandled = YES;
	} else if([[event charactersIgnoringModifiers] characterAtIndex:0] == NSRightArrowFunctionKey) {
		keyWasHandled = [(AppDelegate *)[self delegate] userDidPressRightInView:self];
	} else if([[event charactersIgnoringModifiers] characterAtIndex:0] == NSLeftArrowFunctionKey) {
		keyWasHandled = [(AppDelegate *)[self delegate] userDidPressLeftInView:self];
	}
	
	if(!keyWasHandled) {
		[super keyDown:event];
	}
}

@end
