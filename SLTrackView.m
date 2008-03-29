#import "SLTrackView.h"
#import "AppDelegate.h"

static NSRect LLRectFromPoints(NSPoint point1, NSPoint point2) {
    return NSMakeRect(((point1.x <= point2.x) ? point1.x : point2.x), ((point1.y <= point2.y) ? point1.y : point2.y), ((point1.x <= point2.x) ? point2.x - point1.x : point1.x - point2.x), ((point1.y <= point2.y) ? point2.y - point1.y : point1.y - point2.y));
}

@implementation SLTrackView

- (void)dealloc {
	[controller removeObserver:self forKeyPath:@"arrangedObjects"];
	[controller removeObserver:self forKeyPath:@"selectionIndexes"];

	[[NSNotificationCenter defaultCenter] removeObserver:self
													name:nil
												  object:query];

	[super dealloc];
}

- (void)unbind:(NSString *)bindingName {
	[super unbind:bindingName];	
    [self setNeedsDisplay:YES];
}

- (void)noteFromQuery:(NSNotification *)note {
	
	//NSLog(@"note from query %@", query);
	/*
	if ([[note name] isEqualToString:NSMetadataQueryDidStartGatheringNotification]) {
		NSLog(@"%@ %d results, %@ started", self.uti, [query resultCount], query);
	} else if ([[note name] isEqualToString:NSMetadataQueryDidFinishGatheringNotification]) {
		NSLog(@"%@ %d results, finished", self.uti, [query resultCount]);
	} else if ([[note name] isEqualToString:NSMetadataQueryGatheringProgressNotification]) {
		NSLog(@"%@ %d results, gathering", self.uti, [query resultCount]);
	} else if ([[note name] isEqualToString:NSMetadataQueryDidUpdateNotification]) {
		NSLog(@"%@ %d results, updated", self.uti, [query resultCount]);
	}
	*/

	[self setResultsDirty];
}

- (BOOL)isOpaque {
	return YES;
}

- (void)setValue:(id)value forKey:(NSString *)key {
	if([key isEqualToString:@"query"]) {

		if(value != query) {
			[[NSNotificationCenter defaultCenter] removeObserver:self
			                                                name:nil
														  object:query];
														  
			[[NSNotificationCenter defaultCenter] addObserver:self
													 selector:@selector(noteFromQuery:)
														 name:nil
													   object:value];
		}
	}
	
	[super setValue:value forKey:key];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {

	if (object == controller) {
		if ([keyPath isEqualToString:@"arrangedObjects"] || [keyPath isEqualToString:@"selectionIndexes"]) {
			[self setNeedsDisplay:YES];
		}
		return;
	}
	
	if ([keyPath isEqualToString:@"fromDate"] || [keyPath isEqualToString:@"toDate"]) {
		[self setNeedsDisplay:YES];
		return;
	}
	
	[super observeValueForKeyPath:keyPath ofObject:object change:change context:context]; // FIXME: why it doesn't work?
}

- (void)setResultsDirty {
	CGLayerRelease(resultsLayer);
	resultsLayer = NULL;
}

- (void)setController:(NSArrayController *)arrayController {
	controller = [arrayController retain];
	
	[controller addObserver:self forKeyPath:@"arrangedObjects" options:NSKeyValueChangeSetting context:(void *)nil];
	[controller addObserver:self forKeyPath:@"selectionIndexes" options:NSKeyValueChangeSetting context:(void *)nil];
}

- (BOOL)graphicIsSelected:(id)aGraphic {
	return [[controller selectedObjects] containsObject:aGraphic];
}

- (double)xLocationForItem:(NSMetadataItem *)item {
	NSDate *date = [item valueForKey:[(AppDelegate *)[NSApp delegate] currentDateAttribute]];
	
	NSDate *fd = [[NSApp delegate] valueForKey:@"fromDate"];
	NSDate *td = [[NSApp delegate] valueForKey:@"toDate"];
	
	NSTimeInterval fullInterval = [td timeIntervalSinceDate:fd];
	NSTimeInterval pointInterval = [date timeIntervalSinceDate:fd];
	
	int width = [self frame].size.width;
	return (pointInterval / fullInterval) * width;
}

- (NSRect)drawingBoundsForItem:(NSMetadataItem *)item {
	NSUInteger idx = [query indexOfResult:item];
	NSNumber *relevance = [query valueOfAttribute:(NSString *)kMDQueryResultContentRelevance forResultAtIndex:idx];
	//NSLog(@"r: %@", relevance); // FIXME: bad values for relevance
	if([relevance floatValue] > 0.5) {
		relevance = [NSNumber numberWithFloat:0.5];
	}
	return NSMakeRect([self xLocationForItem:item] - 2.5, 5+[relevance floatValue] * 20, 5, 5); // TODO: factorize with drawMDItem: // FIXME: * 20 is a hack to amplify the relevance difference
}

- (void)drawMDItem:(NSMetadataItem *)item context:(CGContextRef)context {
	// TODO: put the color in preferences?
	CGColorRef myColor = [self graphicIsSelected:item] ?
		CGColorCreateGenericRGB(1.0, 0.0, 0.0, 1.0) :
		CGColorCreateGenericRGB(0.0, 0.0, 1.0, 1.0);
	
	CGContextSetStrokeColorWithColor(context, myColor);
	CGRect rect = NSRectToCGRect([self drawingBoundsForItem:item]);
	CGContextStrokeRect(context, rect);
	CGColorRelease(myColor);
}

- (void)viewDidEndLiveResize {
	[self setResultsDirty];
	[self setNeedsDisplay:YES];
	[super viewDidEndLiveResize];
}

- (void)drawRect:(NSRect)rect {
	if(isSelected) { // TODO: handle selected tracks drawing?
		[[NSColor selectedControlColor] set];
	} else {
		[[NSColor textBackgroundColor] set];
	}
	[NSBezierPath fillRect:[self bounds]];
	
	CGContextRef c = [[NSGraphicsContext currentContext] graphicsPort];

	[[NSColor controlShadowColor] set];
	NSBezierPath *path = [[NSBezierPath alloc] init];
	[path moveToPoint:NSMakePoint(0,0)];
	[path lineToPoint:NSMakePoint(rect.size.width, 0)];
	[path closePath];
	[path stroke];

	if (resultsLayer==NULL) {
		CGSize layerSize = CGSizeMake(self.frame.size.width, self.frame.size.height);
		resultsLayer = CGLayerCreateWithContext(c,layerSize,NULL);
		CGContextRef layerContext = CGLayerGetContext(resultsLayer);

		BOOL disableAntiAliasing = [[NSUserDefaults standardUserDefaults] boolForKey:@"disableTracksAntiAliasing"];
		CGContextSetAllowsAntialiasing(layerContext, !disableAntiAliasing);
		
		//CGContextSetShadowWithColor(layerContext, CGSizeMake(0,-2), 2.0, CGColorCreateGenericRGB(0.0, 0.0, 0.0, 0.25));
		
		NSRect bounds;
		for(NSMetadataItem *g in [controller arrangedObjects]) {
			bounds = [self drawingBoundsForItem:g];
			if ([self needsToDrawRect:bounds]) {
				[self drawMDItem:g context:layerContext];
			}
		}
	}
	
	CGContextDrawLayerAtPoint(c,CGPointMake(0,0),resultsLayer);
	
    if (!NSEqualRects(rubberbandRect, NSZeroRect)) {
        [[NSColor redColor] set];
        NSFrameRect(rubberbandRect);
    }
}

- (void)unselectAll {
	[controller setSelectedObjects:[NSArray array]];
}

- (BOOL)acceptsFirstResponder { 
	return YES; 
} 

- (void)keyDown:(NSEvent *)event {
	//NSLog(@"-- %@", event);
	
	if( ([event modifierFlags] & NSCommandKeyMask) && [[event characters] isEqualToString:@"a"]) {
		[controller setSelectedObjects:[controller arrangedObjects]];
	}
	
	if([event keyCode] == 53) {
		[controller setSelectedObjects:[NSArray array]];
		[controller setSelectionIndexes:[[[NSIndexSet alloc] init] autorelease]];
	}
		
	[self setResultsDirty];
} 

- (BOOL)hitTestWithPoint:(NSPoint)point onItem:(NSMetadataItem *)item {
	NSBezierPath *circle = [NSBezierPath bezierPathWithOvalInRect:[self drawingBoundsForItem:item]];
	return [circle containsPoint:point];
}

- (void)addGraphicToSelection:(id)aGraphic {
	[controller addSelectedObjects:[NSArray arrayWithObject:aGraphic]];
}

- (void)mouseDown:(NSEvent *)event {
	
    // unselect all if not shift
	if (!([event modifierFlags] & NSShiftKeyMask)) {
        [self unselectAll];
    }
	
    // hangle dragging selection
    BOOL didMove = [self selectAndTrackMouseWithEvent:event];
	if(!didMove) {
		[self setResultsDirty];
	} else {
		return;
    }
	
	// find out if we hit anything
	NSMetadataItem *g;
	NSPoint p = [self convertPoint:[event locationInWindow] fromView:nil];
    for(g in [[controller arrangedObjects] reverseObjectEnumerator]) {
		if([self hitTestWithPoint:p onItem:g]) {
			break;
		}
	}
	
	// if no graphic hit, then if extending selection do nothing else set selection to nil
	if (g == nil) {
        if (!([event modifierFlags] & NSShiftKeyMask)) {
            [self unselectAll];
        }
        return;
	}
	
	// graphic hit
	// if not extending selection (shift key down) then set selection to this graphic
	if (!([event modifierFlags] & NSShiftKeyMask)) {
        [self unselectAll];
        [self addGraphicToSelection:g];
	}
}

- (NSSet *)graphicsIntersectingRect:(NSRect)rect {
    NSMutableSet *result = [NSMutableSet set];
    
    for (NSMetadataItem *item in [controller arrangedObjects]) {
        if (NSIntersectsRect(rect, [self drawingBoundsForItem:item])) {
            [result addObject:item];
        }
    }
	
    return result;
}

- (BOOL)selectAndTrackMouseWithEvent:(NSEvent *)theEvent {
	
    NSPoint origPoint, curPoint;
    
    rubberbandIsDeselecting = (([theEvent modifierFlags] & NSAlternateKeyMask) ? YES : NO);
    origPoint = curPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	
    while (1) {
        theEvent = [[self window] nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask)];
        curPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
		
		// keep curPoint in self bounds
		curPoint.x = curPoint.x > [self bounds].size.width ? [self bounds].size.width : curPoint.x;
		curPoint.x = curPoint.x < 1.0 ? 0.0 : curPoint.x;
		curPoint.y = curPoint.y > [self bounds].size.height ? [self bounds].size.height : curPoint.y;
		curPoint.y = curPoint.y < 1.0 ? 1.0 : curPoint.y;
		
		// if we did move
        if (!NSEqualPoints(origPoint, curPoint)) {
            NSRect newRubberbandRect = LLRectFromPoints(origPoint, curPoint);
			
            if (!NSEqualRects(rubberbandRect, newRubberbandRect)) {
                [self setNeedsDisplayInRect:rubberbandRect];
                [self setNeedsDisplayInRect:newRubberbandRect];
				
                rubberbandRect = newRubberbandRect;
            }
        }
		
        if ([theEvent type] == NSLeftMouseUp) {
            break;
        }
        
    }
	
	[rubberbandGraphics release];
	rubberbandGraphics = [[self graphicsIntersectingRect:rubberbandRect] retain];		
	
	NSSet *currentSelection = [NSSet setWithArray:[controller selectedObjects]];
	
	NSMutableSet *justAdded = [NSMutableSet setWithSet:rubberbandGraphics];
	[justAdded minusSet:currentSelection];
	[controller addSelectedObjects:[justAdded allObjects]];
	
	NSMutableSet *justRemoved = [NSMutableSet setWithSet:rubberbandGraphics];
	[justRemoved intersectSet:[NSMutableSet setWithSet:currentSelection]];
	[controller removeSelectedObjects:[justRemoved allObjects]];
	
	if([justAdded count] > 0 || [justRemoved count] > 0) {
		[self setResultsDirty];
	}
	[self setNeedsDisplay:YES];
	
    rubberbandRect = NSZeroRect;
    [rubberbandGraphics release];
    rubberbandGraphics = nil;
    
    BOOL didMove = !NSEqualPoints(origPoint, curPoint);
    return didMove;
}

@synthesize resultsLayer;
@synthesize rubberbandIsDeselecting;
@synthesize trackName;
@synthesize query;
@synthesize isSelected;
@synthesize rubberbandGraphics;

@end
