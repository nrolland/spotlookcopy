#import "SLTrack.h"
#import "NSPredicate+SL.h"
#import "AppDelegate.h"
#import "SLTrackSet.h"

@implementation SLTrack

@dynamic trackSets;
@dynamic name;
@dynamic uti;
@dynamic scope;
@dynamic nameContentKeywords;
@dynamic showAll;
@dynamic isActive;

static NSData *genericTiff;

+ (void)initialize {
    NSArray *keys = [NSArray arrayWithObjects:@"uti", nil];
    [self setKeys:keys triggerChangeNotificationsForDependentKey:@"icon"];
	genericTiff = [[[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericDocumentIconResource)] TIFFRepresentation] retain]; // TODO: where should it be released?
}

- (void)dealloc {
	[genericTiff release];
	[super dealloc];
}

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

- (NSURL *)URLPath {
	return [NSURL fileURLWithPath:self.scope];
}

- (NSImage *)icon {
	if(icon == nil) {
		NSImage *i = [[NSWorkspace sharedWorkspace] iconForFileType:self.uti];
		NSData *tiff = [i TIFFRepresentation];
		if(![self.uti isEqualToString:@"public.item"] && ![self.uti isEqualToString:@"public.data"] && [tiff isEqualToData:genericTiff]) {
			i = [[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kUnknownFSObjectIcon)];
		}

		[self setValue:i forKey:@"icon"];
	}
	return icon;
}

- (void)closeTrack {
	//NSLog(@"closeTrack");
	[self setValue:[NSNumber numberWithBool:NO] forKey:@"isActive"]; // TODO: remove track from tracksController selection
}

- (void)setUp {
	//NSLog(@"-setUp %@", self.name);
	
	NSMetadataQuery *q = [[[NSMetadataQuery alloc] init] autorelease];
	[self setValue:q forKey:@"query"];
	
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
	//NSLog(@"didChangeValueForKey %@", key);

	if([key isEqualToString:@"isActive"]) {
		
		if([[self valueForKey:@"isActive"] boolValue] == YES) {
			[self createPredicate];
			[query startQuery];
		} else {
			[query stopQuery];
			[query setPredicate:nil];
		}
	}
	
	if([key isEqualToString:@"uti"]) {
		[self setValue:[[NSWorkspace sharedWorkspace] iconForFileType:self.uti] forKey:@"icon"];
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

- (BOOL)hasScope {
	return [self.scope length] > 0;
}

- (void)setHasScope:(NSNumber *)n {
	[self willChangeValueForKey:@"URLPath"];

	if([n boolValue]) {
		self.scope = NSHomeDirectory();
	} else {
		self.scope = @"";
	}
	
	[self didChangeValueForKey:@"URLPath"];
}

- (void)createPredicate {
	[query stopQuery];
	
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
	
	NSPredicate *utiPredicate = [NSPredicate predicateWithFormat:@"kMDItemContentTypeTree == %@", self.uti];
	
	NSMutableArray *subPredicates = [[NSMutableArray alloc] initWithObjects:timePredicate, utiPredicate, nil];
	if(!showAll) { [subPredicates addObject:searchKeyPredicate]; }
		
	NSPredicate *predicateToRun = [NSCompoundPredicate andPredicateWithSubpredicates:subPredicates];	
	[subPredicates release];
	
	predicateToRun = [NSPredicate spotlightFriendlyPredicate:predicateToRun];
	//NSLog(@"predicateToRun %@", predicateToRun);
	
	[query setPredicate:predicateToRun];
	
	BOOL noScopeFromDefaults = [[NSUserDefaults standardUserDefaults] boolForKey:@"ignoreTracksSearchScopes"];
	BOOL noScopeFromTracks = [self.scope isEqualToString:@""];
	NSArray *scopes = (noScopeFromDefaults || noScopeFromTracks) ? nil : [NSArray arrayWithObject:self.scope];
	[query setSearchScopes:scopes];
	
    [query setValueListAttributes:[NSArray arrayWithObjects:(NSString *)kMDQueryResultContentRelevance, nil]];
}

@synthesize queryResults;
@synthesize query;

@end
