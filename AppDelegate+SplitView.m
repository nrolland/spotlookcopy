//
//  AppDelegate+SplitView.m
//  SpotLook
//
//  Created by Nicolas Seriot on 16.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate+SplitView.h"


@implementation AppDelegate (SplitView)

- (float)splitView:(NSSplitView *)splitView constrainMinCoordinate:(float)proposedCoordinate ofSubviewAt:(int)index {
	return proposedCoordinate + 150;
}

- (float)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(float)proposedCoordinate ofSubviewAt:(int)index {
	return proposedCoordinate - 400;
}

@end
