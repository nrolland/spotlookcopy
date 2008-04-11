#import "SLCollectionView.h"
#import "SLTrack.h"



@implementation SLCollectionView


- (void)awakeFromNib {
	[self setMinItemSize:NSMakeSize(0.0, 50)];
	[self setMaxItemSize:NSMakeSize(0.0, 50)];
}


// get the view for a track
- (NSCollectionViewItem *)newItemForRepresentedObject:(id)o {
	
	SLTrack *track = (SLTrack *)o;
	
	if([track isFault]) {
		track.uti; // fetch the track
	}
	NSAssert([track isFault] == NO, @"error: track is fault");
	
	NSCollectionViewItem *item = [super newItemForRepresentedObject:track];
	[item setRepresentedObject:track];

	[[item view] setValue:track.queryResults forKey:@"controller"];
	[[item view] setValue:track.query forKey:@"query"];
	
	//track.collectionView = self;
	//track.mainView = [item view];
	
	return [item retain];
}

@end
