//
//  NSWorkspace+SL.h
//  SpotLook
//
//  Created by Nicolas Seriot on 03.04.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSWorkspace (SL)

- (void)searchForUTIInSpotlightImporters:(id)sender;

@end

@interface NSObject (SLWorkspaceDelegate)

- (void)didFindUti:(NSString *)uti description:(NSString *)description;

@end
