#import <Cocoa/Cocoa.h>
#import "SLArrayController.h"

// default groups titles
#define TRACKS @"TRACKS"
#define TRACKSGROUPS @"TRACKS GROUPS"

@interface AppDelegate : NSObject {

	IBOutlet NSWindow *window;
    IBOutlet NSArrayController *selectedResultsController;
	IBOutlet SLArrayController *tracksController;
	IBOutlet NSArrayController *activeTracksController;
	IBOutlet NSArrayController *allResultsController;
	IBOutlet NSArrayController *activeTracksResultsController;
	IBOutlet SLArrayController *tracksSetController;
	IBOutlet NSPopUpButton *dateTypesMenu;
	IBOutlet NSPanel *trackInspector;
	IBOutlet NSPathControl *pathControl;
	IBOutlet NSScrollView *scrollView;
	IBOutlet NSTableView *resultsView;
	IBOutlet NSSplitView *splitView;
	IBOutlet NSSearchField *searchField;
	IBOutlet NSSlider *slider;
	IBOutlet NSView *appIconView;
	IBOutlet NSCollectionView *collectionView;
	
	IBOutlet NSTreeController *treeController;
	IBOutlet NSOutlineView *outlineView;
	
    IBOutlet NSView *fromDateView;
    IBOutlet NSView *toDateView;
    IBOutlet NSView *searchView;
    IBOutlet NSView *dateTypeView;
    IBOutlet NSView *sliderView;
	
	NSUInteger initialTracksUsageCounter;
	NSArray *initialTracks;
	NSArray *tracksSD;
	
	NSString *searchKey;
	
	NSMutableArray *contents;
	NSImage *folderImage;
	
	NSNumber *dateSliderMin;
	NSNumber *dateSliderMax;
	NSNumber *dateSliderValue;

	NSDate *fromDate;
	NSDate *toDate;
	NSDate *startDate;
	
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
    NSManagedObjectModel *managedObjectModel;
    NSManagedObjectContext *managedObjectContext;
		
	BOOL quickLookAvailable;
}

@property (retain) NSString *searchKey;
@property (retain) NSDate *fromDate;
@property (retain) NSDate *toDate;
//@property (retain) NSSortDescriptor *tracksSD;

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator;
- (NSManagedObjectModel *)managedObjectModel;
- (NSManagedObjectContext *)managedObjectContext;

- (IBAction)saveAction:sender;
- (IBAction)dateTypeDidChange:(id)sender;
- (void)openFileAtPath:(id)path;
- (IBAction)openTrackInspector:(id)sender;
- (NSString *)currentDateAttribute;

- (IBAction)addNewGroup:(id)sender;
- (IBAction)addNewTrack:(id)sender;
- (IBAction)deleteSelection:(id)sender;

- (IBAction)openSelectedResults:(id)sender;
- (IBAction)revealSelectedResults:(id)sender;

- (IBAction)sendFeedback:(id)sender;
- (IBAction)dateSliderUpdate:(id)sender;

- (IBAction)showBadge:(id)sender;
- (IBAction)resetDefaultTracks:(id)sender;
- (IBAction)createSetWithSelectedTracks:(id)sender;

- (IBAction)pathControlClick:(id)sender;
- (IBAction)createPredicatesAndStartQueries:(id)sender;

- (IBAction)openQuickLook:(id)sender;
- (BOOL)userDidPressLeftInView:(id)sender;
- (BOOL)userDidPressRightInView:(id)sender;

- (IBAction)exportAsImage:(id)sender;

- (IBAction)openUserGuide:(id)sender;
- (IBAction)openFAQ:(id)sender;
- (IBAction)openDiscussion:(id)sender;

@property (retain) NSArrayController *allResultsController;
@property (retain) NSPopUpButton *dateTypesMenu;
@property (retain) NSArrayController *activeTracksResultsController;
@property (retain) NSPanel *trackInspector;
@property (retain) NSTableView *resultsView;
@property (retain) NSScrollView *scrollView;
@property (retain) NSArrayController *tracksSetController;
@property (retain) NSArrayController *tracksController;
@property (retain) NSTreeController *treeController;
@property (retain) NSPathControl *pathControl;
@property (retain) NSArrayController *selectedResultsController;
@property (retain) NSArrayController *activeTracksController;
@property (retain) NSWindow *window;
@property (retain) NSImage *folderImage;
@property (retain) NSView *toDateView;
@property (retain) NSView *dateTypeView;
@property (retain) NSOutlineView *outlineView;
@property (retain) NSView *searchView;
@property (retain) NSView *fromDateView;
@property BOOL quickLookAvailable;

@end