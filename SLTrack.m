#import "SLTrack.h"
#import "NSPredicate+SL.h"
#import "AppDelegate.h"
#import "SLTrackSet.h"
#import "NSData+SL.h"

@implementation SLTrack

@dynamic trackSets;
@dynamic name;
@dynamic uti;
@dynamic scope;
@dynamic nameContentKeywords;
@dynamic showAll;
@dynamic isActive;
@dynamic customSearch;
@dynamic useCustomSearch;
@dynamic useUTI;
@dynamic useScope;


static NSString *genericFileIconDataHash = nil;
static NSImage *unknownImage = nil;


- (BOOL)isDraggable {
	return YES;
}

- (BOOL)isLeaf {
	return YES;
}

- (id)tracks {
	return nil;
}

- (id)controller {
	return nil;
}

- (id)children {
	return [NSArray array];
}

- (void)setURLPath:(NSURL *)url {
	self.scope = [url relativePath];
}

- (NSString *)interpretedScope {
	return [self.scope isEqualToString:@"NSHomeDirectory"] ? NSHomeDirectory() : self.scope;
}

- (NSURL *)URLPath {
	return [NSURL fileURLWithPath:[self interpretedScope]];
}

- (void)loadIcon {
	if(((AppDelegate *)[NSApp delegate]).isReplacingTracks) {
		//NSLog(@"isReplacingTracks");
		return;
	}

	if(genericFileIconDataHash == nil) {
		NSImage *genericImage = [[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericDocumentIconResource)];
		genericFileIconDataHash = [[genericImage TIFFRepresentation] md5];
	}
	
	NSImage *i;
	
	if([self.useCustomSearch boolValue]) {
		i = [[NSWorkspace sharedWorkspace] iconForFileType:@"com.apple.finder.smart-folder"];
	} else if(![self.useUTI boolValue]) {
		i = [[NSWorkspace sharedWorkspace] iconForFileType:self.uti];

		// try not avoid using TIFFRepresentation
		BOOL mayBeGenericIcon = [[i representations] count] == 5 && [i name] == nil;
		if(mayBeGenericIcon) {
			if([[[i TIFFRepresentation] md5] isEqualToString:genericFileIconDataHash]) {
				return;
			}
		}
	} else if( (self.scope != nil && [self.scope length] > 0) ) {
		i = [[NSWorkspace sharedWorkspace] iconForFile:[self interpretedScope]];
	} else {
		return;
	}

	[self setValue:i forKey:@"icon"];
}

- (NSImage *)icon {

	if(icon == nil) {
		if(unknownImage == nil) {
			unknownImage = [[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kUnknownFSObjectIcon)] retain];
		}
		return unknownImage;
	}
	
	return icon;
}

- (void)closeTrack {
	//NSLog(@"closeTrack");
	[self setValue:[NSNumber numberWithBool:NO] forKey:@"isActive"]; // TODO: remove track from tracksController selection
}

- (void)queryNotification:(NSNotification*)note {
    if ([[note name] isEqualToString:NSMetadataQueryDidStartGatheringNotification]) {
		//NSLog(@"%@: started gathering", self.name);
		//self.isGettingResults = YES;
	} else if ([[note name] isEqualToString:NSMetadataQueryDidFinishGatheringNotification]) {
        //NSLog(@"%@: finished gathering", self.name);
		//self.isGettingResults = NO;
    } else if ([[note name] isEqualToString:NSMetadataQueryGatheringProgressNotification]) {
		//NSLog(@"%@: progressing...", self.name);
	} else if ([[note name] isEqualToString:NSMetadataQueryDidUpdateNotification]) {
        //NSLog(@"%@: an update happened.", self.name);
    }
	
	NSUInteger queryFetchLimit = [[NSUserDefaults standardUserDefaults] integerForKey:@"queryFetchLimit"];
	NSUInteger count = [query resultCount];
	if(queryFetchLimit != 0 && count >= queryFetchLimit) {
        //NSLog(@"%@: %d results -> STOP", self.name, );
		[query stopQuery];
		self.displayedQueryResultsCount = [NSString stringWithFormat:@"%d (limited)", count];
	} else {
		self.displayedQueryResultsCount = [NSString stringWithFormat:@"%d", count];
	}
}

- (void)setUp {
	//NSLog(@"-setUp %@", self.name);
	
	NSMetadataQuery *q = [[[NSMetadataQuery alloc] init] autorelease];
	[self setValue:q forKey:@"query"];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(queryNotification:) name:nil object:query];
				
	NSArrayController *c = [[[NSArrayController alloc] init] autorelease];
	[c setAvoidsEmptySelection:NO];	
	[c bind:@"contentArray" toObject:query withKeyPath:@"results" options:nil];
	[self setValue:c forKey:@"queryResults"];
	
	[self createPredicate];
}

- (void)didTurnIntoFault {
	//NSLog(@"- didTurnIntoFault");
	
	[queryResults release];
	[query release];
	[super didTurnIntoFault];
}

- (void)awakeFromFetch {
	[super awakeFromFetch];
	[self setUp];
}

/*
- (id)initWithEntity:(NSEntityDescription*)entity insertIntoManagedObjectContext:(NSManagedObjectContext*)context {
    if (self = [super initWithEntity:entity insertIntoManagedObjectContext:context]) {
    }
    return self;
}
*/

- (void)setActiveStateIfChanged:(NSNumber *)n {
	if([n boolValue] != [self.isActive boolValue]) {
		self.isActive = n;
	}
}
 
- (void)didChangeValueForKey:(NSString *)key {
	//NSLog(@"%@ didChangeValueForKey %@", self.name, key);

	if([key isEqualToString:@"isActive"]) {
		
		if([[self valueForKey:@"isActive"] boolValue] == YES) {
			[self createPredicate];
			[query startQuery];
		} else {
			[query stopQuery];
			[query setPredicate:nil];
		}
	}
	
	if([key isEqualToString:@"uti"] || [key isEqualToString:@"useCustomSearch"]) { // FIXME: makes importing updating icon twice
		self.icon = nil;
		[self loadIcon];
	}
	
	if([key isEqualToString:@"nameContentKeywords"] || [key isEqualToString:@"uti"] || [key isEqualToString:@"scope"] || [key isEqualToString:@"showAll"]) {
		// create and start query only if importation is over
		if([[[NSUserDefaultsController sharedUserDefaultsController] defaults] boolForKey:@"defaultTracksImported"]) {
			[self createPredicate];
			[query startQuery];
		}
	}

	[super didChangeValueForKey:key];
}

/*
- (void)setHasScope:(NSNumber *)n {
	[self willChangeValueForKey:@"URLPath"];
	[self willChangeValueForKey:@"icon"];

	if([n boolValue]) {
		self.scope = @"NSHomeDirectory";
	} else {
		self.scope = @"";
	}

	if(icon != nil) {
		[icon release];
		icon = nil;
	}
	
	[self didChangeValueForKey:@"icon"];
	[self didChangeValueForKey:@"URLPath"];
}
*/

/*
- (void)setHasUTI:(NSNumber *)n {
	[self willChangeValueForKey:@"icon"];

	if([n boolValue]) {
		self.uti = @"com.adobe.pdf";
	} else {
		self.uti = @"";
	}
	
	if(icon != nil) {
		[icon release];
		icon = nil;
	}
	
	[self didChangeValueForKey:@"icon"];
}
*/
- (void)createPredicate {
	[query stopQuery];
	
	if((!self.scope || [self.scope length] == 0) && (!self.uti || [self.uti length] == 0)) {
		//NSLog(@"self.scope %@ self.uti %@", self.scope, self.uti);
		return;
	}
	
	NSString *searchKey = [[NSApp delegate] valueForKey:@"searchKey"];
	NSDate *fromDate = [[NSApp delegate] valueForKey:@"fromDate"];
	NSDate *toDate = [[NSApp delegate] valueForKey:@"toDate"];
		
	NSString *dateType = [(AppDelegate *)[NSApp delegate] currentDateAttribute];
	
	NSPredicate *fromPredicate = [NSPredicate predicateWithFormat:@"%K >= %@", dateType, fromDate];
	NSPredicate *toPredicate = [NSPredicate predicateWithFormat:@"%K <= %@", dateType, toDate];
	NSPredicate *timePredicate = [NSCompoundPredicate andPredicateWithSubpredicates:[NSArray arrayWithObjects:fromPredicate, toPredicate, nil]];
    NSPredicate *searchKeyPredicate;
	
	NSString *nck = self.nameContentKeywords;
	if([nck isEqualToString:@"Name"]) {
		searchKeyPredicate = [NSPredicate predicateWithFormat:@"%K like[wcd] %@", kMDItemDisplayName, searchKey, nil];
	} else if([nck isEqualToString:@"Keywords"]) {
		searchKeyPredicate = [NSPredicate predicateWithFormat:@"%K like[wcd] %@", kMDItemKeywords, searchKey, nil];	
	} else if([nck isEqualToString:@"Content"]){
		searchKeyPredicate = [NSPredicate predicateWithFormat:@"%K like[wcd] %@", kMDItemTextContent, searchKey, nil];
	} else if([nck isEqualToString:@"Title"]){
		searchKeyPredicate = [NSPredicate predicateWithFormat:@"%K like[wcd] %@", kMDItemTitle, searchKey, nil];
	} else {
		NSAssert2(NO, @"Error: track %@ nameContentKeywords is %@", self.name, nck);
	}
	
	NSMutableArray *subPredicates = [[NSMutableArray alloc] initWithObjects:timePredicate, nil];

	if(self.uti != nil && [self.uti length] > 0) {
		NSPredicate *utiPredicate = [NSPredicate predicateWithFormat:@"kMDItemContentTypeTree == %@", self.uti];
		[subPredicates addObject:utiPredicate];
	}

	if(!showAll) { [subPredicates addObject:searchKeyPredicate]; }
		
	NSPredicate *predicateToRun = [NSCompoundPredicate andPredicateWithSubpredicates:subPredicates];	
	[subPredicates release];

	predicateToRun = [NSPredicate spotlightFriendlyPredicate:predicateToRun];
	//NSLog(@"predicateToRun %@", predicateToRun);




//	NSPredicate *p = [NSPredicate predicateWithFormat:@"(((kMDItemTextContent = \"toto*\"cdw) && (kMDItemContentCreationDate > 220921200))) && (true)"];
//	NSPredicate *p = [NSPredicate predicateWithFormat:@"(((%K LIKE %@[cdw]) && (%K < %@)))", kMDItemTextContent, @"toto", kMDItemContentCreationDate, [NSDate date]];
//	NSLog(@"p  %@", p);
//	NSPredicate *p2 = [NSPredicate spotlightFriendlyPredicate:p];
//	NSLog(@"p2 %@", p2);



	
	[query setPredicate:predicateToRun];
//	[query setPredicate:p2];
	
	BOOL noScopeFromDefaults = [[NSUserDefaults standardUserDefaults] boolForKey:@"ignoreTracksSearchScopes"];
	BOOL noScopeFromTracks = [self.scope isEqualToString:@""];
	NSArray *scopes = (noScopeFromDefaults || noScopeFromTracks) ? nil : [NSArray arrayWithObject:[self interpretedScope]];
	[query setSearchScopes:scopes];
	
    [query setValueListAttributes:[NSArray arrayWithObjects:(NSString *)kMDQueryResultContentRelevance, nil]];
}

@synthesize icon;
@synthesize queryResults;
@synthesize query;
@synthesize displayedQueryResultsCount;
//@synthesize collectionView;
//@synthesize mainView;

@end
