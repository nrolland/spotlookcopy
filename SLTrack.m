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

static NSData *genericFileIconData = nil;
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

- (NSURL *)URLPath {
	return [NSURL fileURLWithPath:self.scope];
}

- (void)loadIcon {
	if(self.uti == nil || [self.uti length] == 0) {
		return;
	}
	
	if(genericFileIconData == nil) {
		genericFileIconData = [[[[NSWorkspace sharedWorkspace] iconForFileType:NSFileTypeForHFSTypeCode(kGenericDocumentIconResource)] TIFFRepresentation] retain];
	}
	
	NSImage *i;
	NSArray *rootUTIs = [NSArray arrayWithObjects:@"public.item", @"public.data", nil];
	
	if(self.uti != nil && [self.uti length] > 0 && ![rootUTIs containsObject:self.uti]) {
		i = [[NSWorkspace sharedWorkspace] iconForFileType:self.uti];
		NSData *tiff = [i TIFFRepresentation];
		if([tiff isEqualToData:genericFileIconData]) {
			return;
		}
	} else if( (self.scope != nil && [self.scope length] > 0) || [rootUTIs containsObject:self.uti]) {
		i = [[NSWorkspace sharedWorkspace] iconForFile:self.scope];
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
		return unknownImage; // TODO: cache
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
	
	if([key isEqualToString:@"uti"] || [key isEqualToString:@"scope"]) {
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

- (BOOL)hasScope {
	return [self.scope length] > 0;
}

- (void)setHasScope:(NSNumber *)n {
	[self willChangeValueForKey:@"URLPath"];
	[self willChangeValueForKey:@"icon"];

	if([n boolValue]) {
		self.scope = NSHomeDirectory();
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

- (BOOL)hasUTI {
	return self.uti != nil && [self.uti length] > 0;
}

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
