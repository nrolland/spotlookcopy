#import "AppDelegate.h"
#import "NoZeroTransformer.h"
#import "NSMetadataItem+SL.h"
#import "SLTrack.h"
#import "NSPredicate+SL.h"
#import "SLRulerView.h"
#import "SLTrackSet.h"
#import "QuickLook.h"
#import "ImageAndTextCell.h"
#import "Updater.h"
#import "NSView+SL.h"
#import "NSWorkspace+SL.h"

// reset with
// $ rm -r ~/Library/Application\ Support/SpotLook; rm -r ~/Library/Preferences/ch.seriot.SpotLook.plist

#define QUICKLOOK_UI_FRAMEWORK @"/System/Library/PrivateFrameworks/QuickLookUI.framework"
#define QLPreviewPanel NSClassFromString(@"QLPreviewPanel")

#define COLUMNID_NAME @"NameColumn"	// the single column name in our outline view

@implementation AppDelegate

+ (void)initialize{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *appDefaultsPath = [[NSBundle mainBundle] pathForResource:@"UserDefaults" ofType:@"plist"];
	if(!appDefaultsPath) { NSLog(@"error, could not open defaults file"); }
	NSDictionary *appDefaults = [NSDictionary dictionaryWithContentsOfFile:appDefaultsPath];
	if(!appDefaults) { NSLog(@"error, could interpret content of default file at path %@",appDefaultsPath ); }
    [defaults registerDefaults:appDefaults];
}

/**
    Returns the support folder for the application, used to store the Core Data
    store file.  This code uses a folder named "SpotLook" for
    the content, either in the NSApplicationSupportDirectory location or (if the
    former cannot be found), the system's temporary directory.
 */

- (NSString *)applicationSupportFolder {

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : NSTemporaryDirectory();
    return [basePath stringByAppendingPathComponent:@"SpotLook"];
}


/**
    Creates, retains, and returns the managed object model for the application 
    by merging all of the models found in the application bundle.
 */
 
- (NSManagedObjectModel *)managedObjectModel {

    if (managedObjectModel != nil) {
        return managedObjectModel;
    }
	
    managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles:nil] retain];    
    return managedObjectModel;
}


/**
    Returns the persistent store coordinator for the application.  This 
    implementation will create and return a coordinator, having added the 
    store for the application to it.  (The folder for the store is created, 
    if necessary.)
 */

- (NSPersistentStoreCoordinator *) persistentStoreCoordinator {

    if (persistentStoreCoordinator != nil) {
        return persistentStoreCoordinator;
    }

    NSFileManager *fileManager;
    NSString *applicationSupportFolder = nil;
    NSURL *url;
    NSError *error;
    
    fileManager = [NSFileManager defaultManager];
    applicationSupportFolder = [self applicationSupportFolder];
    if ( ![fileManager fileExistsAtPath:applicationSupportFolder isDirectory:NULL] ) {
        [fileManager createDirectoryAtPath:applicationSupportFolder attributes:nil];
    }
    
    url = [NSURL fileURLWithPath: [applicationSupportFolder stringByAppendingPathComponent: @"SpotLook.xml"]];
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSXMLStoreType configuration:nil URL:url options:nil error:&error]){
        [[NSApplication sharedApplication] presentError:error];
    }    

    return persistentStoreCoordinator;
}


/**
    Returns the managed object context for the application (which is already
    bound to the persistent store coordinator for the application.) 
 */
 
- (NSManagedObjectContext *) managedObjectContext {

    if (managedObjectContext != nil) {
        return managedObjectContext;
    }

    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        managedObjectContext = [[NSManagedObjectContext alloc] init];
        [managedObjectContext setPersistentStoreCoordinator: coordinator];
    }
    
    return managedObjectContext;
}


/**
    Returns the NSUndoManager for the application.  In this case, the manager
    returned is that of the managed object context for the application.
 */
 
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window {
    return [[self managedObjectContext] undoManager];
}


/**
    Performs the save action for the application, which is to send the save:
    message to the application's managed object context.  Any encountered errors
    are presented to the user.
 */
 
- (IBAction) saveAction:(id)sender {

    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}


/**
    Implementation of the applicationShouldTerminate: method, used here to
    handle the saving of changes in the application managed object context
    before the application terminates.
 */
 
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {

    NSError *error;
    int reply = NSTerminateNow;
    
    if (managedObjectContext != nil) {
        if ([managedObjectContext commitEditing]) {
            if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
				
                // This error handling simply presents error information in a panel with an 
                // "Ok" button, which does not include any attempt at error recovery (meaning, 
                // attempting to fix the error.)  As a result, this implementation will 
                // present the information to the user and then follow up with a panel asking 
                // if the user wishes to "Quit Anyway", without saving the changes.

                // Typically, this process should be altered to include application-specific 
                // recovery steps.  

                BOOL errorResult = [[NSApplication sharedApplication] presentError:error];
				
                if (errorResult == YES) {
                    reply = NSTerminateCancel;
                } 

                else {
					
                    int alertReturn = NSRunAlertPanel(nil, @"Could not save changes while quitting. Quit anyway?" , @"Quit anyway", @"Cancel", nil);
                    if (alertReturn == NSAlertAlternateReturn) {
                        reply = NSTerminateCancel;	
                    }
                }
            }
        } 
        
        else {
            reply = NSTerminateCancel;
        }
    }
    
    return reply;
}

- (NSManagedObjectContext *)tracksImportManagedObjectContext {
    if(tracksImportManagedObjectContext == nil) {
        tracksImportManagedObjectContext = [[NSManagedObjectContext alloc] init];
        [tracksImportManagedObjectContext setPersistentStoreCoordinator:[self persistentStoreCoordinator]];
        [tracksImportManagedObjectContext setMergePolicy:NSOverwriteMergePolicy];
        //[[tracksImportManagedObjectContext undoManager] disableUndoRegistration];
    }
    return tracksImportManagedObjectContext;
}


// FIXME: check
- (void)contextDidSave:(NSNotification *)notification {
	// NSLog(@"contextDidSave");
	id notifier= [notification object];
	if (notifier == [self tracksImportManagedObjectContext]) {
		[[self managedObjectContext] mergeChangesFromContextDidSaveNotification:notification];
		[tracksController fetch:self];
		[outlineView reloadData];
	}
}

- (void)askToUpgradeTracksIfNotDone {
	NSString *latestResetToDefaultTracks = [[NSUserDefaults standardUserDefaults] valueForKey:@"latestResetToDefaultTracks"];
    NSString *currentVersionString = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleShortVersionString"];
	BOOL v_1_0_Prefs = ![[[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] allKeys] containsObject:@"latestResetToDefaultTracks"];
	//NSLog(@"v_1_0_Prefs %d", v_1_0_Prefs);

	BOOL skipCurrentVersionTrackUpgrade = [[[NSUserDefaults standardUserDefaults] objectForKey:@"skipTracksUpgradeVersion"] isEqualToString:currentVersionString];
	if(skipCurrentVersionTrackUpgrade) { return; }
	
	if(v_1_0_Prefs || (latestResetToDefaultTracks != nil && [[Updater sharedInstance] shortVersion:currentVersionString isBiggerThan:latestResetToDefaultTracks])) {
		NSAlert *alert = [[[NSAlert alloc] init] autorelease];
		[alert addButtonWithTitle:@"Upgrade!"];
		[alert addButtonWithTitle:@"Later"];
		[alert setMessageText:@"New tracks available!"];
		[alert setInformativeText:[NSString stringWithFormat:@"Do you want to upgrade to SpotLook %@ tracks? Your old custom tracks will be lost. You can upgrade at any time by choosing \"Reset Tracks\" in the Tracks menu.", currentVersionString]];
		[alert setAlertStyle:NSWarningAlertStyle];
		
		[alert beginSheetModalForWindow:window
					  modalDelegate:self
					 didEndSelector:@selector(upgradeToLatestTracksAlertDidEnd:returnCode:contextInfo:)
						contextInfo:nil];
	}
}

- (void)iconsLoadedFromSeparateThread {
	[outlineView reloadData];
	self.isLoadingIcons = NO;
}

// FIXME: may crash. use semaphore.
/*
Thread 7 Crashed:
0   com.apple.CoreFoundation      	0x9429c0f4 ___TERMINATING_DUE_TO_UNCAUGHT_EXCEPTION___ + 4
1   libobjc.A.dylib               	0x961d10fb objc_exception_throw + 40
2   com.apple.CoreFoundation      	0x9429b60e __NSFastEnumerationMutationHandler + 206
3   com.apple.Foundation          	0x903f6625 -[NSCFSet unionSet:] + 181
4   com.apple.CoreData            	0x918b8ba4 -[NSManagedObjectContext deletedObjects] + 180
5   ch.seriot.SpotLook            	0x00003484 -[AppDelegate performIconsFetching] + 314
6   com.apple.Foundation          	0x903df5ad -[NSThread main] + 45
7   com.apple.Foundation          	0x903df154 __NSThread__main__ + 308
8   libSystem.B.dylib             	0x9694bc55 _pthread_start + 321
9   libSystem.B.dylib             	0x9694bb12 thread_start + 34
*/
- (void)performIconsFetching {

	NSAutoreleasePool *p = [[NSAutoreleasePool alloc] init];
	//NSLog(@"performIconsFetching");
	
	for(SLTrack *t in [[[tracksController arrangedObjects] copy] autorelease]) {
		if(![[[self managedObjectContext] deletedObjects] containsObject:t]) {
			[t loadIcon];
		} /*else {
			NSLog(@"no track %@", t.name);
		}*/
	}
	
	[self performSelectorOnMainThread:@selector(iconsLoadedFromSeparateThread) withObject:nil waitUntilDone:YES];
	[p release];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	NSDockTile *dock = [NSApp dockTile];
	[dock setContentView:appIconView];
	[dock display];
	
	[tracksController fetchWithRequest:nil merge:NO error:nil];
	
	if(!self.isReplacingTracks && !self.isLoadingIcons) {
		self.isLoadingIcons = YES;
		//NSLog(@"applicationDidFinishLaunching detach performIconsFetching");
		[NSThread detachNewThreadSelector:@selector(performIconsFetching)
								 toTarget:self
							   withObject:nil];
	}
	
    [[Updater sharedInstance] checkUpdateSilentIfUpToDate:self];
	
	[self askToUpgradeTracksIfNotDone];
}

/**
    Implementation of dealloc, to release the retained variables.
 */
 
- (void) dealloc {
    [managedObjectContext release], managedObjectContext = nil;
    [persistentStoreCoordinator release], persistentStoreCoordinator = nil;
    [managedObjectModel release], managedObjectModel = nil;
	[contents release];
	[tracksSD release];
    [super dealloc];
}

- (IBAction)resetDates:(id)sender {
	self.fromDate = (NSDate *)[[NSCalendarDate date] dateByAddingYears:0 months:-1 days:0 hours:0 minutes:0 seconds:0];
	self.toDate = (NSDate *)[[NSCalendarDate date] dateByAddingYears:0 months:0 days:0 hours:12 minutes:0 seconds:0];
}

- (id)init {
	if(self = [super init]) {

		contents = [[NSMutableArray alloc] init];
		
		// FIXME: get this used
		NSSortDescriptor *sd = [[[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES] autorelease];
		tracksSD = [NSArray arrayWithObject:sd];

        NoZeroTransformer *noZeroTransformer = [[[NoZeroTransformer alloc] init] autorelease];
        [NSValueTransformer setValueTransformer:noZeroTransformer forName:@"NoZeroTransformer"];
		
		self.searchKey = @"";
		
		self.fromDate = (NSDate *)[[NSCalendarDate date] dateByAddingYears:0 months:-1 days:0 hours:0 minutes:0 seconds:0];
		self.toDate = (NSDate *)[[NSCalendarDate date] dateByAddingYears:0 months:0 days:0 hours:12 minutes:0 seconds:0];
		
		initialTracksUsageCounter = 5; // this is a hack to keep the initial active tracks active during controllers filling by coredata
		
		[[NSNotificationCenter defaultCenter] addObserver:self
											     selector:@selector(contextDidSave:) 
												     name:NSManagedObjectContextDidSaveNotification
											       object:nil];
	}
	
	return self;
}

- (IBAction)createPredicatesAndStartQueries:(id)sender {
	if(self.searchKey == nil) {
		self.searchKey = @"";
	}
	
	[[activeTracksController arrangedObjects] makeObjectsPerformSelector:@selector(createPredicate) withObject:nil];
	[[[activeTracksController arrangedObjects] valueForKey:@"query"] makeObjectsPerformSelector:@selector(startQuery)];
}

- (void)didChangeValueForKey:(NSString *)key {

	if([[NSArray arrayWithObjects:@"fromDate", @"toDate", @"searchKey", nil] containsObject:key]) {
		[self createPredicatesAndStartQueries:nil];
	}
	
	if([[NSArray arrayWithObjects:@"fromDate", @"toDate", nil] containsObject:key]) {
		NSTimeInterval dsv = [toDate timeIntervalSinceDate:fromDate];
		[self setValue:[NSNumber numberWithDouble:dsv] forKey:@"dateSliderValue"];
		[[scrollView horizontalRulerView] setNeedsDisplay:YES];
		
		int sliderBackYears = [[NSUserDefaults standardUserDefaults] integerForKey:@"sliderBackYears"];
		NSCalendarDate *toCalendarDate = [toDate dateWithCalendarFormat:nil timeZone:[NSTimeZone defaultTimeZone]]; // hassling conversions..
		NSCalendarDate *sliderBackYearsDate = [toCalendarDate dateByAddingYears:-sliderBackYears months:0 days:0 hours:0 minutes:0 seconds:0];
		[slider setMaxValue:[toDate timeIntervalSince1970]];
		[slider setMinValue:[sliderBackYearsDate timeIntervalSince1970]];
		[slider setFloatValue:[fromDate timeIntervalSince1970]];
	}

	[super didChangeValueForKey:key];
}

- (IBAction)dateSliderUpdate:(id)sender {
	NSDate *sliderDate = [NSDate dateWithTimeIntervalSince1970:[slider floatValue]];
	self.fromDate = sliderDate;
}

// TODO: use bindings and KVO
- (IBAction)dateTypeDidChange:(id)sender {
	[[[NSUserDefaultsController sharedUserDefaultsController] values] setValue:[sender titleOfSelectedItem] forKey:@"dateType"];
	[self createPredicatesAndStartQueries:nil];
}

- (NSString *)currentDateAttribute {
	NSString *dateTypeKey = [[NSUserDefaults standardUserDefaults] valueForKey:@"dateType"];

	NSAssert(dateTypeKey != nil, @"dateType should not be nil");

	NSString *dateType;
	if([dateTypeKey isEqualToString:@"Creation"]) {
		dateType = (NSString *)kMDItemContentCreationDate;
	} else if ([dateTypeKey isEqualToString:@"Modification"]) {
		dateType = (NSString *)kMDItemContentModificationDate;
	} else if ([dateTypeKey isEqualToString:@"Last Use"]) {
		dateType = (NSString *)kMDItemLastUsedDate;
	} else {
		NSAssert1(NO, @"Error: dateTypeKey is %@", dateTypeKey);	
	}
	return dateType;
}

- (SLTrack *)createdAndInsertedTrackFromDictionary:(NSDictionary *)d context:(NSManagedObjectContext *)context{
	SLTrack *t = [NSEntityDescription insertNewObjectForEntityForName: @"SLTrack" inManagedObjectContext:context];
	t.scope = @"NSHomeDirectory"; // NSHomeDirectory()
	t.name = [d objectForKey:@"name"];
	t.uti = [d objectForKey:@"uti"];
	t.nameContentKeywords = [d objectForKey:@"nameContentKeywords"];
	[t setUp];
	return t;
}

- (SLTrackSet *)createAndInsertTrackSetWithName:(NSString *)s context:(NSManagedObjectContext *)context {
	SLTrackSet *ts = [NSEntityDescription insertNewObjectForEntityForName: @"SLTrackSet" inManagedObjectContext:context];
	ts.name = s;
	return ts;
}

- (void)importDefaultTracks {
	//NSLog(@"importDefaultTracks");
    NSManagedObjectContext *context = [self tracksImportManagedObjectContext];

	NSString *dtPath = [[NSBundle mainBundle] pathForResource:@"DefaultTracks" ofType:@"plist"]; // TODO: handle if not present..
	NSArray *dt = [NSArray arrayWithContentsOfFile:dtPath];
	
	for(NSDictionary *d in dt) {
		if([[d allKeys] containsObject:@"tracks"]) { // we found a trackSet
			SLTrackSet *ts = [self createAndInsertTrackSetWithName:[d objectForKey:@"name"] context:context];
			for(NSDictionary *td in [d objectForKey:@"tracks"] ) {
				SLTrack *t = [self createdAndInsertedTrackFromDictionary:td context:context];
				ts.tracks = [ts.tracks setByAddingObject:t];
			}
		} else {
			[self createdAndInsertedTrackFromDictionary:d context:context];
		}
	}
	
	[context save:nil];

    NSString *currentVersionString = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleShortVersionString"];
	[[NSUserDefaults standardUserDefaults] setObject:currentVersionString forKey:@"latestResetToDefaultTracks"];
}

- (void)populateOutlineContents {
	self.isPopulatingOutline = YES;

	tracksSetController.name = TRACKSGROUPS;
	[treeController insertObject:tracksSetController atArrangedObjectIndexPath:[NSIndexPath indexPathWithIndex:0]];

	tracksController.name = TRACKS;
	[treeController insertObject:tracksController atArrangedObjectIndexPath:[NSIndexPath indexPathWithIndex:1]];
		
	if([[NSUserDefaults standardUserDefaults] boolForKey:@"outlineExpandTrackGroups"]) {
		[outlineView expandItem:[[treeController arrangedObjects] descendantNodeAtIndexPath:[NSIndexPath indexPathWithIndex:0]]];
	}

	if([[NSUserDefaults standardUserDefaults] boolForKey:@"outlineExpandTracks"]) {
		[outlineView expandItem:[[treeController arrangedObjects] descendantNodeAtIndexPath:[NSIndexPath indexPathWithIndex:1]]];
	}
	self.isPopulatingOutline = NO;
}

- (void)setupSlider {
	int sliderBackYears = [[NSUserDefaults standardUserDefaults] integerForKey:@"sliderBackYears"];
	NSCalendarDate *sliderBackYearsDate = [[NSCalendarDate date] dateByAddingYears:-sliderBackYears months:0 days:0 hours:0 minutes:0 seconds:0];
	[self setValue:sliderBackYearsDate forKey:@"startDate"];
	
	[self setValue:[NSNumber numberWithDouble:[startDate timeIntervalSince1970]] forKey:@"dateSliderMin"];
	[self setValue:[NSNumber numberWithDouble:(double)[toDate timeIntervalSince1970] - 60*60*24] forKey:@"dateSliderMax"];
	[self setValue:[NSNumber numberWithDouble:(double)[fromDate timeIntervalSince1970]] forKey:@"dateSliderValue"];
}

- (void)awakeFromNib {	
	quickLookAvailable = [[NSBundle bundleWithPath:QUICKLOOK_UI_FRAMEWORK] load];
	if(quickLookAvailable) {
		[[[QLPreviewPanel sharedPreviewPanel] windowController] setDelegate:self];
	} else {
		NSLog(@"Warning: could not load QuickLookUI.framework at path %@", QUICKLOOK_UI_FRAMEWORK); // TODO: display alert?
	}

	[window setAutorecalculatesContentBorderThickness:YES forEdge:NSMinYEdge];
	[window setContentBorderThickness:30 forEdge:NSMinYEdge];
	
	// use custom imageCell
	NSTableColumn *tableColumn = [outlineView tableColumnWithIdentifier:COLUMNID_NAME];
	ImageAndTextCell *imageAndTextCell = [[[ImageAndTextCell alloc] init] autorelease];
	[imageAndTextCell setEditable:YES];
	[tableColumn setDataCell:imageAndTextCell];
	
	// TODO: useful ?
	[[[outlineView enclosingScrollView] verticalScroller] setFloatValue:0.0];
	[[[outlineView enclosingScrollView] contentView] scrollToPoint:NSMakePoint(0,0)];
	
	[outlineView setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleSourceList];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(outlineItemDidExpand:) name:NSOutlineViewItemDidExpandNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(outlineItemDidCollapse:) name:NSOutlineViewItemDidCollapseNotification object:nil];
					
	// set defaults
	if([[NSUserDefaults standardUserDefaults] boolForKey:@"defaultTracksImported"] == NO) {
		//[self importDefaultTracks];
		self.isReplacingTracks = YES;
		//NSLog(@"%s", __PRETTY_FUNCTION__);
		[NSThread detachNewThreadSelector:@selector(performReplaceTracksWithDefaults) toTarget:self withObject:nil];
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"defaultTracksImported"];
	} else {
		[self populateOutlineContents];
	}
	
	// set date slider
	[self setupSlider];

	// set rulerView
	[NSScrollView setRulerViewClass:[SLRulerView class]];
	[scrollView setHasHorizontalRuler:YES];
	[scrollView setRulersVisible:YES];

	[[scrollView horizontalRulerView] setRuleThickness:16.0];
	[[scrollView horizontalRulerView] setReservedThicknessForMarkers:0.0];
	[[scrollView horizontalRulerView] setReservedThicknessForAccessoryView:0.0];
	//[scrollView setBackgroundColor:[NSColor windowBackgroundColor]]; // FIXME: unconsidered? for now we must set the color in IB.
		
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(datesDidChange:) name:@"datesDidChange" object:nil];

	// TODO: useful?
	[dateTypesMenu selectItemWithTitle:[[NSUserDefaults standardUserDefaults] valueForKey:@"dateType"]];

	//[self populateOutlineContents];
	//[managedObjectContext processPendingChanges];
	
	[activeTracksResultsController addObserver:self forKeyPath:@"arrangedObjects" options:(NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld) context:nil];
	
	[treeController addObserver:self forKeyPath:@"selectionIndexPaths" options:(NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld) context:nil];
	
	// we want to refresh treeController when adding or removing tracks or trackSets
	[tracksController addObserver:self forKeyPath:@"arrangedObjects" options:(NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld) context:nil];
	[tracksSetController addObserver:self forKeyPath:@"arrangedObjects" options:(NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld) context:nil];

	[slider setFloatValue:[fromDate timeIntervalSince1970]];
	
	[[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:@"disableRulerAntiAliasing" options:(NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld) context:nil];
	[[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:@"sliderBackYears" options:(NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld) context:nil];
	
	[outlineView setDelegate:self];
	
	[activeTracksController fetchWithRequest:nil merge:NO error:nil]; // FIXME: outputs four time SpotLook(40268,0xb0103000) malloc: free_garbage: garbage ptr = 0x......., has non-zero refcount = 1
	initialTracks = [[activeTracksController arrangedObjects] copy];
	//NSLog(@"initialTracks %@", [initialTracks valueForKey:@"name"]);
	
	NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"name" ascending:YES];
	[tracksController setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
	[tracksSetController setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
	[sortDescriptor release];
}

- (IBAction)openUTIDiscoverer:(id)sender {
	[utisController removeObjects:[utisController arrangedObjects]];
	[utiDiscovererWindow makeKeyAndOrderFront:self];
	[utisController addObjects:[NSWorkspace registeredUTIs]];
}

- (void)storeOutlineViewExpandingStatus:(NSOutlineView *)ov {
	BOOL trackGroups = [ov isItemExpanded:[[treeController arrangedObjects] descendantNodeAtIndexPath:[NSIndexPath indexPathWithIndex:0]]];
	BOOL tracks      = [ov isItemExpanded:[[treeController arrangedObjects] descendantNodeAtIndexPath:[NSIndexPath indexPathWithIndex:1]]];

	[[NSUserDefaults standardUserDefaults] setBool:trackGroups forKey:@"outlineExpandTrackGroups"];
	[[NSUserDefaults standardUserDefaults] setBool:tracks      forKey:@"outlineExpandTracks"];
}

- (void)outlineItemDidExpand:(NSNotification *)notification {
	if(isPopulatingOutline) return;
	
	[self storeOutlineViewExpandingStatus:(NSOutlineView *)[notification object]];
}

- (void)outlineItemDidCollapse:(NSNotification *)notification {
	if(isPopulatingOutline) return;
	
	[self storeOutlineViewExpandingStatus:(NSOutlineView *)[notification object]];
}

- (void)datesDidChange:(NSNotification *)notification {
	NSArray *dates = [notification object];
	NSAssert([dates count] == 2, @"dates notification object should have two dates");
	NSDate *from = [dates objectAtIndex:0];
	NSDate *to = [dates objectAtIndex:1];
	[self setValue:from forKey:@"fromDate"];
	[self setValue:to forKey:@"toDate"];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {

	//NSLog(@"%@.%@", object, keyPath);
	
	if ((object == [NSUserDefaults standardUserDefaults]) && [keyPath isEqualToString:@"disableRulerAntiAliasing"]) {
		[[scrollView horizontalRulerView] setNeedsDisplay:YES];
		return;
	}

	if ((object == [NSUserDefaults standardUserDefaults]) && [keyPath isEqualToString:@"sliderBackYears"]) {
		[self setupSlider];
		return;
	}

	if((object == treeController) && [keyPath isEqualToString:@"selectionIndexPaths"]) {

		// synchronize subcontrollers selections
		[tracksController setSelectedObjects:[treeController selectedObjects]];
		[tracksSetController setSelectedObjects:[treeController selectedObjects]];

		// activate all selected objects
		[[treeController selectedObjects] makeObjectsPerformSelector:@selector(setActiveStateIfChanged:) withObject:[NSNumber numberWithBool:YES]];
		
		// remove unused objects
		NSMutableSet *toDesactivate = [[NSMutableSet alloc] initWithArray:[activeTracksController arrangedObjects]];
		[toDesactivate minusSet:[NSSet setWithArray:[treeController selectedObjects]]];
		
		if(initialTracksUsageCounter > 0) {
			//NSLog(@"initialTracksUsageCounter");
			initialTracksUsageCounter--;
			[toDesactivate minusSet:[NSSet setWithArray:initialTracks]];
			if(initialTracksUsageCounter == 0) {
				[initialTracks release]; initialTracks = nil;
			}
		}
		
		for(SLTrackSet *ts in [tracksSetController selectedObjects]) {
			[toDesactivate minusSet:ts.tracks];
		}
		[[toDesactivate allObjects] makeObjectsPerformSelector:@selector(setActiveStateIfChanged:) withObject:[NSNumber numberWithBool:NO]];
		[toDesactivate release];
		
		return;
	}
	
	if((object == tracksController) && [keyPath isEqualToString:@"arrangedObjects"]) {
		[treeController rearrangeObjects];
		return;
	}

	if((object == tracksSetController) && [keyPath isEqualToString:@"arrangedObjects"]) {
		[treeController rearrangeObjects];
		return;
	}

	if((object == activeTracksResultsController) && [keyPath isEqualToString:@"arrangedObjects"]) {
		[self showBadge:self];
		return;
	}

	[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

- (IBAction)pathControlClick:(id)sender {
	NSString *path = [[[pathControl clickedPathComponentCell] URL] relativePath];
	
	[[NSWorkspace sharedWorkspace] openFile:path];
}

- (void)openFileAtPath:(id)path {
    [[NSWorkspace sharedWorkspace] openFile:path];
}

- (IBAction)addNewGroup:(id)sender {
	SLTrackSet *ts = [NSEntityDescription insertNewObjectForEntityForName:@"SLTrackSet" inManagedObjectContext:[self managedObjectContext]];
	ts.name = @"New Group";
	ts.tracks = [NSSet setWithArray:[activeTracksController arrangedObjects]];

	[tracksSetController insertObject:ts atArrangedObjectIndex:0];

	NSUInteger indexes[2] = {0, 0};
	NSIndexPath *ip = [NSIndexPath indexPathWithIndexes:indexes length:2];   

	[treeController setSelectionIndexPaths:[NSArray arrayWithObject:ip]];
}

- (IBAction)addNewTrack:(id)sender {
	SLTrack *t = [NSEntityDescription insertNewObjectForEntityForName:@"SLTrack" inManagedObjectContext:[self managedObjectContext]];
	t.scope = NSHomeDirectory();
	t.uti = @"com.adobe.pdf";
	t.name = @"PDF (sample track)";
	[t setUp];
	
	[tracksController insertObject:t atArrangedObjectIndex:0];
	
	NSUInteger indexes[2] = {1, 0};
	NSIndexPath *ip = [NSIndexPath indexPathWithIndexes:indexes length:2];   

	[treeController setSelectionIndexPaths:[NSArray arrayWithObject:ip]];
}

- (IBAction)deleteSelection:(id)sender {
	NSArray *a = [treeController selectedObjects];
	NSArray *b = [a copy];
	[tracksSetController removeObjects:a];
	[tracksController removeObjects:b];
}

- (BOOL)justOneTrackSelected {
	return [[tracksController selectedObjects] count] == 1; // binding for track inspector menu item .enabled
}

- (IBAction)openTrackInspector:(id)sender {
	if(![trackInspector isVisible]) {
		[trackInspector makeKeyAndOrderFront:self];
	} else {
		[trackInspector close];
	}
}	

- (IBAction)exportAsImage:(id)sender {

/*
	// TODO: collectionView or scrollView?
	// in fact we would like the collectionView BUT with the rulerView above
	
	NSView *view = [[NSView alloc] initWithFrame:[scrollView frame]];
	[[[scrollView horizontalRulerView] image] drawInRect:[view frame] fromRect:[scrollView frame] operation:NSCompositeSourceOver fraction:1.0];
	
	NSRulerView *ruler = [scrollView horizontalRulerView];
	CGFloat rulerHeight = [ruler frame].size.height;
	CGFloat collectionViewHeight = [collectionView frame].size.height;
	
	
	NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize([ruler frame].size.width, rulerHeight+collectionViewHeight)];
	[image lockFocus];
	[[[scrollView horizontalRulerView] image] compositeToPoint:NSMakePoint(0, collectionViewHeight) fromRect:[[scrollView horizontalRulerView] frame] operation:NSCompositeSourceOver];
	[[collectionView image] compositeToPoint:NSMakePoint(0, 0) fromRect:[collectionView frame] operation:NSCompositeSourceOver];
	[image unlockFocus];
*/	

	NSImage *image = [scrollView image];
		
	NSSavePanel *sp;
	int runResult;
	 
	/* create or get the shared instance of NSSavePanel */
	sp = [NSSavePanel savePanel];
	 
	/* set up new attributes */
//	NSView *accessoryView = [[NSView alloc] initWithFrame:[scrollView frame]];
//	[sp setAccessoryView:accessoryView];
	//[sp setRequiredFileType:@"png"];
	[sp setAllowedFileTypes:[NSArray arrayWithObject:@"png"]];
	//[sp setExtensionHidden:NO];
	 
	/* display the NSSavePanel */
	runResult = [sp runModalForDirectory:[NSHomeDirectory() stringByAppendingPathComponent:@"Desktop"] file:@"Untitled.png"];
	 
	/* if successful, save file under designated name */
	if (runResult == NSOKButton) {
		if (![[image TIFFRepresentation] writeToFile:[sp filename] atomically:YES])
			 NSBeep();
	}
	
//	[accessoryView release];
}

- (IBAction)openSelectedResults:(id)sender {
	for(NSMetadataItem *i in [selectedResultsController selectedObjects]) {
		[[NSWorkspace sharedWorkspace] openFile:[i valueForAttribute:(NSString *)kMDItemPath]];
	}
}

- (IBAction)revealSelectedResults:(id)sender {
	NSString *path;
	for(NSMetadataItem *i in [selectedResultsController selectedObjects]) {
		path = [[i valueForAttribute:(NSString *)kMDItemPath] stringByDeletingLastPathComponent];
		[[NSWorkspace sharedWorkspace] openFile:path];
	}
}

- (IBAction)showBadge:(id)sender {
	//NSLog(@"showBadge: %@", count);
	NSUInteger count = [[activeTracksResultsController arrangedObjects] count];

	NSString *title = count > 0 ? [NSString stringWithFormat:@"SpotLook - %d results", count] : @"SpotLook";	
	[window setTitle:title];

	NSString *resultsCount = count > 0 ? [NSString stringWithFormat:@"%d", count] : @"";	
	NSDockTile *dock = [NSApp dockTile];
	[dock setBadgeLabel:resultsCount];
	[dock display];
}

- (IBAction)createSetWithSelectedTracks:(id)sender {
	SLTrackSet *tracksSet = [NSEntityDescription insertNewObjectForEntityForName:@"SLTrackSet" inManagedObjectContext:[self managedObjectContext]];
	tracksSet.name = @"New Group";
	tracksSet.tracks = [NSSet setWithArray:[tracksController selectedObjects]];
	[tracksSetController addObject:tracksSet];
}

- (IBAction)resetDefaultTracks:(id)sender {
	NSAlert *alert = [[[NSAlert alloc] init] autorelease];
	[alert addButtonWithTitle:@"Cancel"];
	[alert addButtonWithTitle:@"Reset!"];
	[alert setMessageText:@"Reset to default tracks?"];
	[alert setInformativeText:@"Your custom tracks and tracks sets will be lost. Default tracks will be restored."];
	[alert setAlertStyle:NSWarningAlertStyle];
	
	[alert beginSheetModalForWindow:window
                  modalDelegate:self
                 didEndSelector:@selector(resetToDefaultTracksAlertDidEnd:returnCode:contextInfo:)
                    contextInfo:nil];
}

- (void)tracksWereReplaced {
	self.isReplacingTracks = NO;
	self.isLoadingIcons = YES;
	
	//NSLog(@"tracksWereReplaced");
	[outlineView reloadData];
	
	//NSLog(@"tracksWereReplaced detach performIconsFetching");
    [NSThread detachNewThreadSelector:@selector(performIconsFetching)
                             toTarget:self
                           withObject:nil];	
}

- (void)performReplaceTracksWithDefaults{
	NSAutoreleasePool *p = [[NSAutoreleasePool alloc] init];
	//NSLog(@"-- performReplaceTracksWithDefaults");

	// remove tree nodes
	if([[treeController arrangedObjects] count] >= 2) {
		[treeController removeObjectAtArrangedObjectIndexPath:[NSIndexPath indexPathWithIndex:1]];
		[treeController removeObjectAtArrangedObjectIndexPath:[NSIndexPath indexPathWithIndex:0]];
	}
	
	// remove controllers content
	[tracksSetController removeObjects:[tracksSetController arrangedObjects]];
	[tracksController removeObjects:[tracksController arrangedObjects]];

	// import
	[[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"defaultTracksImported"];
	[self importDefaultTracks];
	[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"defaultTracksImported"];
	
	[self populateOutlineContents];
	
	[p release];
	
	[self performSelectorOnMainThread:@selector(tracksWereReplaced) withObject:nil waitUntilDone:YES];
}

- (void)resetToDefaultTracksAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == NSAlertSecondButtonReturn) {
		/*
		if(self.isReplacingTracks) {
			NSLog(@"already importing tracks");
			return;
		}
		*/
		self.isReplacingTracks = YES;
		//NSLog(@"detach performReplaceTracksWithDefaults --2");
		[NSThread detachNewThreadSelector:@selector(performReplaceTracksWithDefaults) toTarget:self withObject:nil];
		//[self replaceTracksWithDefaults];
    }	
}

- (void)upgradeToLatestTracksAlertDidEnd:(NSAlert *)alert returnCode:(int)returnCode contextInfo:(void *)contextInfo {
    if (returnCode == NSAlertFirstButtonReturn) {
		/*
		if(self.isReplacingTracks) {
			NSLog(@"already importing tracks");
			return;
		}
		*/
		self.isReplacingTracks = YES;
		//NSLog(@"detach performReplaceTracksWithDefaults --3");
		[NSThread detachNewThreadSelector:@selector(performReplaceTracksWithDefaults) toTarget:self withObject:nil];
		//[self replaceTracksWithDefaults];
    } else {
		NSString *currentVersionString = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleShortVersionString"];
		[[NSUserDefaults standardUserDefaults] setObject:currentVersionString forKey:@"skipTracksUpgradeVersion"];
	}
}

- (IBAction)sendFeedback:(id)sender {
    NSString *email = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"FeedbackEmail"];
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"mailto:%@", email]];
    [[NSWorkspace sharedWorkspace] openURL:url];
}

- (void)windowWillClose:(NSNotification *)aNotification {
	[NSApp terminate:self];
}

- (IBAction)openUserGuide:(id)sender {
    NSURL *url = [NSURL URLWithString:[[[NSBundle mainBundle] infoDictionary] valueForKey:@"UserGuideURL"]];
    [[NSWorkspace sharedWorkspace] openURL:url];
}

- (IBAction)openFAQ:(id)sender {
    NSURL *url = [NSURL URLWithString:[[[NSBundle mainBundle] infoDictionary] valueForKey:@"FAQURL"]];
    [[NSWorkspace sharedWorkspace] openURL:url];	
}

- (IBAction)openDiscussion:(id)sender {
    NSURL *url = [NSURL URLWithString:[[[NSBundle mainBundle] infoDictionary] valueForKey:@"DiscussionURL"]];
    [[NSWorkspace sharedWorkspace] openURL:url];
}

#pragma mark -
#pragma mark QuickLook

- (void)setQuickLookItems {
	if(quickLookAvailable) {
		NSArray *selectedObjects = [selectedResultsController selectedObjects];
		if([selectedObjects count] > 0) {
			NSMutableArray *urls = [NSMutableArray arrayWithCapacity:[selectedObjects count]];
			for(NSMetadataItem *item in selectedObjects) {
				NSString *path = [item valueForAttribute:(NSString *)kMDItemPath];
				NSURL *url = [NSURL fileURLWithPath:path];
				[urls addObject:url];
			}

			[[QLPreviewPanel sharedPreviewPanel] setURLs:urls currentIndex:0 preservingDisplayState:YES];
		}
	}
}

- (BOOL)userDidPressRightInView:(id)sender {
	BOOL keyWasHandled = NO;

	if(quickLookAvailable && [[QLPreviewPanel sharedPreviewPanel] isOpen]) {
		[[QLPreviewPanel sharedPreviewPanel] selectNextItem];
		keyWasHandled = YES;
	}

	return keyWasHandled;
}

- (BOOL)userDidPressLeftInView:(id)sender {
	BOOL keyWasHandled = NO;

	if(quickLookAvailable && [[QLPreviewPanel sharedPreviewPanel] isOpen]) {
		[[QLPreviewPanel sharedPreviewPanel] selectPreviousItem];
		keyWasHandled = YES;
	}

	return keyWasHandled;
}

- (IBAction)openQuickLook:(id)sender {
	if(!quickLookAvailable) return;// NO;

	if([[QLPreviewPanel sharedPreviewPanel] isOpen]) {
		[[QLPreviewPanel sharedPreviewPanel] closeWithEffect:2];
	} else {
		[self setQuickLookItems];
		[[QLPreviewPanel sharedPreviewPanel] makeKeyAndOrderFrontWithEffect:2];			
		[window makeKeyWindow];
	}

	//return YES;
}

- (NSRect)previewPanel:(NSPanel*)panel frameForURL:(NSURL*)URL {
	NSRect frame = NSMakeRect(0, 0, 0, 0);
	if(!quickLookAvailable) return frame;
	
	NSMetadataItem *foundItem;
	NSArray *selectedObjects = [selectedResultsController selectedObjects];
	
	if([selectedObjects count] > 0) {
		NSMetadataItem *item;
		for(item in selectedObjects) {
			NSString *path = [item valueForAttribute:(NSString *)kMDItemPath];
			NSURL *url = [NSURL fileURLWithPath:path];
			//NSLog(@"%@ - %@", url, URL);
			if([[url absoluteString] isEqualTo:[URL absoluteString]]) {
				break;
			}
		}

		if(foundItem) {
			// TODO: refactor
			NSInteger index = -1;
			for(NSMetadataItem *i in selectedObjects) {
				index++;
				if([i isEqualTo:item]) {
					break;
				}
			}

			if(index != -1) {
				frame = [resultsView rectOfRow:index];
				frame.origin = [resultsView convertPoint:frame.origin toView:nil];
				frame.origin = [window convertBaseToScreen:frame.origin];
				frame.origin.y -= frame.size.height;
			}
		}
	}

	return frame;
}

@synthesize searchKey;
@synthesize fromDate;
@synthesize toDate;
@synthesize tracksSetController;
@synthesize dateTypesMenu;
@synthesize quickLookAvailable;
@synthesize scrollView;
@synthesize trackInspector;
@synthesize activeTracksResultsController;
@synthesize window;
@synthesize pathControl;
@synthesize tracksController;
@synthesize treeController;
@synthesize resultsView;
@synthesize allResultsController;
@synthesize activeTracksController;
@synthesize selectedResultsController;
@synthesize outlineView;
@synthesize searchView;
@synthesize dateTypeView;
@synthesize fromDateView;
@synthesize toDateView;
@synthesize isLoadingIcons;
@synthesize isReplacingTracks;
@synthesize isPopulatingOutline;

@end
