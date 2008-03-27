#import <Cocoa/Cocoa.h>
#import <ApplicationServices/ApplicationServices.h>

@interface SLTrackView : NSView {
    NSRect rubberbandRect;
    NSSet *rubberbandGraphics;
    BOOL rubberbandIsDeselecting;

	BOOL isSelected;

	NSString *trackName;
	
	NSArrayController *controller;
	
	CGLayerRef resultsLayer;
	
	NSMetadataQuery *query;
}

- (void)setController:(NSArrayController *)arrayController;

- (BOOL)selectAndTrackMouseWithEvent:(NSEvent *)theEvent;
//- (void)addGraphicToSelection:(id)aGraphic;
- (void)setResultsDirty;

@property (retain) NSMetadataQuery *query;
@property BOOL isSelected;
@property (retain) NSString *trackName;
@property CGLayerRef resultsLayer;
@property (retain) NSSet *rubberbandGraphics;
@property BOOL rubberbandIsDeselecting;

@end
