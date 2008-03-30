//
//  SLRulerView.m
//  SpotLook
//
//  Created by Nicolas Seriot on 03.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "SLRulerView.h"

static CGFloat positionForDates(NSDate *date, NSDate *fromDate, NSDate *toDate, float width) {
	NSTimeInterval dateInterval = [date timeIntervalSinceDate:fromDate];
	NSTimeInterval fullInterval = [toDate timeIntervalSinceDate:fromDate];
	return dateInterval / fullInterval * width;
}

static NSRect LLRectFromPoints(NSPoint point1, NSPoint point2) {
    return NSMakeRect(((point1.x <= point2.x) ? point1.x : point2.x), ((point1.y <= point2.y) ? point1.y : point2.y), ((point1.x <= point2.x) ? point2.x - point1.x : point1.x - point2.x), ((point1.y <= point2.y) ? point2.y - point1.y : point1.y - point2.y));
}

@implementation SLRulerView

- (NSDate *)dateForPosition:(int)x {
	float width = [self frame].size.width;
	NSDate *fromDate = [[NSApp delegate] valueForKey:@"fromDate"];
	NSDate *toDate = [[NSApp delegate] valueForKey:@"toDate"];
	
	float ratio = x / width;
	
	NSTimeInterval total = [toDate timeIntervalSinceDate:fromDate];
	NSTimeInterval timePos = total * ratio;
	NSDate *newDate = [fromDate addTimeInterval:timePos];
	return newDate;
}

- (void)dealloc {
	[textAttributes release];
	[super dealloc];
}

- (id)initWithScrollView:(NSScrollView *)scrollView orientation:(NSRulerOrientation)orientation {
	self = [super initWithScrollView:scrollView orientation:orientation];
	
	[self setWantsLayer:YES];
	
	textAttributes = [[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSFont fontWithName:@"Lucida Grande" size:9.0], [NSColor darkGrayColor], nil]
												  forKeys:[NSArray arrayWithObjects:NSFontAttributeName, NSForegroundColorAttributeName, nil]] retain];
	
	noAntialiasingTextAttributes = [[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSFont fontWithName:@"Monaco" size:9.0], [NSColor darkGrayColor], nil]
												  forKeys:[NSArray arrayWithObjects:NSFontAttributeName, NSForegroundColorAttributeName, nil]] retain];
	
	return self;
}

- (void)drawDay:(float)pos small:(BOOL)small {
	float height = [self frame].size.height;
	float verticalLength = small ? height - 5 : 0;

	NSPoint a = {pos, height - 1};
	NSPoint b = {pos, verticalLength};
	[NSBezierPath strokeLineFromPoint:a toPoint:b];
}

- (void)drawHashMarksAndLabelsInRect:(NSRect)aRect {
	
	float width = aRect.size.width;
	NSDate *fromDate = [[NSApp delegate] valueForKey:@"fromDate"];
	NSDate *toDate = [[NSApp delegate] valueForKey:@"toDate"];
	
	float days = [toDate timeIntervalSinceDate:fromDate] / (60 * 60 * 24);
	if(days < 0.0) { return; } // fromDate > lastDate // TODO: play boing! prevent in appDelegate willChangeValueForKey:

	CGContextRef c = [[NSGraphicsContext currentContext] graphicsPort];
	
	BOOL disableAntiAliasing = [[NSUserDefaults standardUserDefaults] boolForKey:@"disableRulerAntiAliasing"]; // TODO: add in preferences
	
	CGContextSetAllowsAntialiasing(c, !disableAntiAliasing);

	// draw the days
	NSCalendarDate *fcd = [fromDate dateWithCalendarFormat:nil timeZone:[NSTimeZone defaultTimeZone]];
	NSCalendarDate *tcd = [toDate dateWithCalendarFormat:nil timeZone:[NSTimeZone defaultTimeZone]];
	
	NSCalendarDate *fromRulerDate = [NSCalendarDate dateWithYear:[fcd yearOfCommonEra] month:[fcd monthOfYear] day:[fcd dayOfMonth] hour:0 minute:0 second:0 timeZone:[NSTimeZone defaultTimeZone]];
	NSCalendarDate *toRulerDate = [NSCalendarDate dateWithYear:[tcd yearOfCommonEra] month:[tcd monthOfYear] day:[tcd dayOfMonth] hour:24 minute:0 second:0 timeZone:[NSTimeZone defaultTimeZone]];

	NSTimeInterval day = 60 * 60 * 24;
	
	NSString *s = nil;
	NSCalendarDate *iDate;		
	for(iDate = [fromRulerDate dateWithCalendarFormat:nil timeZone:[NSTimeZone defaultTimeZone]];
		[iDate compare:toRulerDate] == NSOrderedAscending;
		iDate = [iDate addTimeInterval:day]) {
				
		float pos = positionForDates(iDate, fromDate, toDate, width);
		s = nil;

		if(days > 500) {
			//NSLog(@"%f, days > 500", days);
			if ([iDate dayOfYear] == 1) {
				[self drawDay:pos small:NO];
				s = [NSString stringWithFormat:@"%d", [iDate yearOfCommonEra]];
			} else if([iDate dayOfMonth] == 1) {
				[self drawDay:pos small:YES];
			}
		} else if(days > 150) {
			//NSLog(@"%f, days > 150", days);
			if ([iDate dayOfYear] == 1) {
				[self drawDay:pos small:NO];
				s = [NSString stringWithFormat:@"%d", [iDate yearOfCommonEra]];
			} else if([iDate dayOfMonth] == 1) {
				[self drawDay:pos small:YES];
				s = [iDate descriptionWithCalendarFormat:@"%b"];
			}
		} else if(days > 25) {
			//NSLog(@"%f, days > 25", days);
			if ([iDate dayOfYear] == 1) {
				[self drawDay:pos small:NO];
				s = [NSString stringWithFormat:@"%d", [iDate yearOfCommonEra]];
			} else if([iDate dayOfMonth] == 1) {
				[self drawDay:pos small:NO];
				s = [iDate descriptionWithCalendarFormat:@"%B"];
			} else {
				[self drawDay:pos small:YES];
			}
		} else if(days > 10) {
			//NSLog(@"%f, days > 10", days);
			if ([iDate dayOfYear] == 1) {
				[self drawDay:pos small:NO];
				s = [NSString stringWithFormat:@"%d", [iDate yearOfCommonEra]];
			} else if([iDate dayOfMonth] == 1) {
				[self drawDay:pos small:NO];
				s = [iDate descriptionWithCalendarFormat:@"%B"];
			} else {
				[self drawDay:pos small:NO];
				s = [iDate descriptionWithCalendarFormat:@"%e"];
			}
		} else if (days > 3) {
			//NSLog(@"%f, days <= 10", days);
			if ([iDate dayOfYear] == 1) {
				[self drawDay:pos small:NO];
				s = [NSString stringWithFormat:@"%d", [iDate yearOfCommonEra]];
			} else if([iDate dayOfMonth] == 1) {
				[self drawDay:pos small:NO];
				s = [iDate descriptionWithCalendarFormat:@"%B"];
			} else {
				[self drawDay:pos small:NO];
				s = [iDate descriptionWithCalendarFormat:@"%A %d"];
			}
		} else {
			[self drawDay:pos small:NO];
			s = [iDate descriptionWithCalendarFormat:@"%A %d"];
			// draw 24h before and 24h after
			NSCalendarDate *from = [iDate dateByAddingYears:0 months:0 days:-1 hours:0 minutes:0 seconds:0];
			NSCalendarDate *to = [iDate dateByAddingYears:0 months:0 days:1 hours:0 minutes:0 seconds:0];
			NSCalendarDate *hDate;
			float hPos;
			for(hDate = from;
				[hDate compare:to] == NSOrderedAscending;
				hDate = [hDate addTimeInterval:60*60]) {
				hPos = positionForDates(hDate, fromDate, toDate, width);

				[self drawDay:hPos small:YES];
			}
		}
		
		[s drawAtPoint:NSMakePoint(pos + 4, 0) withAttributes:(disableAntiAliasing ? noAntialiasingTextAttributes : textAttributes)];
	}

	CGContextSetAllowsAntialiasing(c, true);	

    if (!NSEqualRects(rubberbandRect, NSZeroRect)) {
        [[[NSColor yellowColor] colorWithAlphaComponent:0.05] set];
        NSRectFill(rubberbandRect); // FIXME: why alpha does not draw?
        //NSFrameRectWithWidth(rubberbandRect, 2);
    }
}

- (void)zoomWithRect:(NSRect)rect {
	int start = rect.origin.x;
	int stop  = rect.origin.x + rect.size.width;
	
	NSDate *from = [self dateForPosition:start];
	NSDate *to = [self dateForPosition:stop];
	
//	NSLog(@"%d %d", start, stop);
//	NSLog(@"%@ %@", from, to);
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"datesDidChange" object:[NSArray arrayWithObjects:from, to, nil]];
}

- (void)mouseDown:(NSEvent *)theEvent {
	//NSLog(@"mouseDown");
	
	if (!([theEvent modifierFlags] & NSAlternateKeyMask)) {
        return;
    }
	
    NSPoint origPoint, curPoint;
    
    origPoint = curPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	origPoint.y = 0;
	
    while (1) {
        theEvent = [[self window] nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask)];
        curPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
		
		// keep curPoint in self bounds
		curPoint.x = curPoint.x > [self bounds].size.width ? [self bounds].size.width : curPoint.x;
		curPoint.x = curPoint.x < 0.0 ? 0.0 : curPoint.x;
		curPoint.y = [self bounds].size.height-1;
		
		// if we did move
        if (!NSEqualPoints(origPoint, curPoint)) {
            NSRect newRubberbandRect = LLRectFromPoints(origPoint, curPoint);
			
            if (!NSEqualRects(rubberbandRect, newRubberbandRect)) {
//                [self setNeedsDisplayInRect:rubberbandRect];
//                [self setNeedsDisplayInRect:newRubberbandRect];
				
				[self setNeedsDisplay:YES];
				
                rubberbandRect = newRubberbandRect;
            }
        }
		
        if ([theEvent type] == NSLeftMouseUp) {
            break;
        }
        
    }

	[self zoomWithRect:rubberbandRect];
	[self setNeedsDisplay:YES];
	
    rubberbandRect = NSZeroRect;
}

@end
