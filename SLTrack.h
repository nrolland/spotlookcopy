#import <CoreData/CoreData.h>
#import "SLTrackView.h"
#import "SLCollectionView.h"

@class SLTrackSet;

@interface SLTrack : NSManagedObject  
{
    NSMetadataQuery *query;
	NSArrayController *queryResults;
	BOOL showAll;
	NSImage *icon;
	NSString *displayedQueryResultsCount;
	
	NSString *customSearch; // TODO: put in coredata model
	
	//SLCollectionView *collectionView;
	//NSView *mainView;
}

- (void)setUp;
- (void)createPredicate;
- (NSImage *)icon;
- (void)loadIcon;

@property (retain) NSString *name;
@property (retain) NSString *uti;
@property (retain) NSString *nameContentKeywords;
@property (retain) NSString *scope;
@property (retain) NSString *customSearch;
@property (retain) NSString *displayedQueryResultsCount;
@property (retain) NSSet *trackSets;
@property (retain) NSNumber *isActive;
@property (retain) NSArrayController *queryResults;
@property (retain) NSMetadataQuery *query;
//@property (retain) SLCollectionView *collectionView;
//@property (retain) NSView *mainView;
@property BOOL showAll;

@end

/*
@interface SLTrack (CoreDataGeneratedAccessors)
- (void)addTrackSetsObject:(SLTrackSet *)value;
- (void)removeTrackSetsObject:(SLTrackSet *)value;
- (void)addTrackSets:(NSSet *)value;
- (void)removeTrackSets:(NSSet *)value;

@end
*/