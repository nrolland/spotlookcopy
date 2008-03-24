//
//  SLTrackSet.h
//  SpotLook
//
//  Created by Nicolas Seriot on 04.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>

@class SLTrack;

@interface SLTrackSet : NSManagedObject  
{
	NSImage *icon;
}

@property (retain) NSString *name;
@property (retain) NSSet *tracks;

@end
/*
@interface SLTrackSet (CoreDataGeneratedAccessors)
- (void)addTracksObject:(SLTrack *)value;
- (void)removeTracksObject:(SLTrack *)value;
- (void)addTracks:(NSSet *)value;
- (void)removeTracks:(NSSet *)value;

@end
*/
