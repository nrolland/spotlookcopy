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

@implementation SLRulerView

- (void)dealloc {
	[textAttributes release];
	[super dealloc];
}

- (id)initWithScrollView:(NSScrollView *)scrollView orientation:(NSRulerOrientation)orientation {
	self = [super initWithScrollView:scrollView orientation:orientation];
	
	textAttributes = [[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSFont fontWithName:@"Lucida Grande" size:9.0], [NSColor grayColor], nil]
												  forKeys:[NSArray arrayWithObjects:NSFontAttributeName, NSForegroundColorAttributeName, nil]] retain];
	
	noAntialiasingTextAttributes = [[NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSFont fontWithName:@"Monaco" size:9.0], [NSColor grayColor], nil]
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
	
	//[super drawHashMarksAndLabelsInRect:aRect];
}

@end