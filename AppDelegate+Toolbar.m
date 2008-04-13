//
//  SpotLook_AppDelegate+Toolbar.m
//  SpotLook
//
//  Created by Nicolas Seriot on 14.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate+Toolbar.h"


@implementation AppDelegate (Toolbar)

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag {
    
    NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];

	if ([itemIdentifier isEqualToString:@"informations"]) {
        [item setLabel:NSLocalizedString(@"Track Informations", @"Toolbar item")];
        [item setPaletteLabel:NSLocalizedString(@"Informations", @"Toolbar customize")];
        [item setToolTip:NSLocalizedString(@"Informations", @"Toolbar tooltip")];
        [item setImage:[NSImage imageNamed:NSImageNameInfo]];
        [item setTarget:self];
        [item setAction:@selector(toolbaritemclicked:)];
	} else if ([itemIdentifier isEqualToString:@"quickLook"]) {
        [item setLabel:NSLocalizedString(@"QuickLook", @"Toolbar item")];
        [item setPaletteLabel:NSLocalizedString(@"QuickLook", @"Toolbar customize")];
        [item setToolTip:NSLocalizedString(@"QuickLook", @"Toolbar tooltip")];
        [item setImage:[NSImage imageNamed:NSImageNameQuickLookTemplate]];
        [item setTarget:self];
        [item setAction:@selector(toolbaritemclicked:)];
    } else if ([itemIdentifier isEqualToString:@"search"]) {
        [item setLabel:NSLocalizedString(@"Search", @"Toolbar item")];
        [item setPaletteLabel:NSLocalizedString(@"Search", @"Toolbar customize")];
        [item setToolTip:NSLocalizedString(@"Search", @"Toolbar tooltip")];
        NSRect fRect = [searchView frame];
        [item setView:searchView];
        [item setMinSize:fRect.size];
        [item setMaxSize:fRect.size];
	} else if ([itemIdentifier isEqualToString:@"fromDate"]) {
        [item setLabel:NSLocalizedString(@"From Date", @"Toolbar item")];
        [item setPaletteLabel:NSLocalizedString(@"From Date", @"Toolbar customize")];
        [item setToolTip:NSLocalizedString(@"From Date", @"Toolbar tooltip")];
        NSRect fRect = [fromDateView frame];
        [item setView:fromDateView];
        [item setMinSize:fRect.size];
        [item setMaxSize:fRect.size];
    } else if ([itemIdentifier isEqualToString:@"toDate"]) {
		[item setLabel:NSLocalizedString(@"To Date", @"Toolbar item")];
		[item setPaletteLabel:NSLocalizedString(@"To Date", @"Toolbar customize")];
		[item setToolTip:NSLocalizedString(@"To Date", @"Toolbar tooltip")];
        NSRect fRect = [toDateView frame];
        [item setView:toDateView];
        [item setMinSize:fRect.size];
        [item setMaxSize:fRect.size];
    } else if ([itemIdentifier isEqualToString:@"dateType"]) {
		[item setLabel:NSLocalizedString(@"Date Type", @"Toolbar item")];
		[item setPaletteLabel:NSLocalizedString(@"Date Type", @"Toolbar customize")];
		[item setToolTip:NSLocalizedString(@"Date Type", @"Toolbar tooltip")];
        NSRect fRect = [dateTypeView frame];
        [item setView:dateTypeView];
        [item setMinSize:fRect.size];
        [item setMaxSize:fRect.size];
    } else if ([itemIdentifier isEqualToString:@"slider"]) {
		[item setLabel:NSLocalizedString(@"Date Slider", @"Toolbar item")];
		[item setPaletteLabel:NSLocalizedString(@"Date Slider", @"Toolbar customize")];
		[item setToolTip:NSLocalizedString(@"Date Slider", @"Toolbar tooltip")];
        NSRect fRect = [sliderView frame];
        [item setView:sliderView];
        [item setMinSize:fRect.size];
        [item setMaxSize:fRect.size];
    }
	    
    return [item autorelease];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar*)toolbar {
    return [NSArray arrayWithObjects:@"informations", @"quickLook",
		NSToolbarSeparatorItemIdentifier, @"dateType",
		NSToolbarSpaceItemIdentifier, @"fromDate",
		NSToolbarFlexibleSpaceItemIdentifier, @"slider",
		NSToolbarFlexibleSpaceItemIdentifier, @"search",
		NSToolbarFlexibleSpaceItemIdentifier, @"toDate", nil];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar {
    NSArray *standardItems = [NSArray arrayWithObjects:NSToolbarSeparatorItemIdentifier,
                                                       NSToolbarSpaceItemIdentifier,
                                                       NSToolbarFlexibleSpaceItemIdentifier,
                                                       NSToolbarCustomizeToolbarItemIdentifier, nil];
	NSArray *moreItems = [NSArray array];
	return [[[self toolbarDefaultItemIdentifiers:nil] arrayByAddingObjectsFromArray:standardItems] arrayByAddingObjectsFromArray:moreItems];
}

- (void)toolbaritemclicked:(NSToolbarItem*)item {
    //NSLog(@"-- toolbaritemclicked %@", [item label]);
    
    NSString *identifier = [item itemIdentifier];
    if([identifier isEqualToString:@"informations"]) {
        [self toggleEdition];
    } else if ([identifier isEqualToString:@"quickLook"]) {
        [self openQuickLook:nil];
    }    
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)theItem {
    
	NSString *identifier = [theItem itemIdentifier];
    if ([identifier isEqualToString:@"quickLook"]) {
		return quickLookAvailable && [[selectedResultsController selectedObjects] count] > 0;
	}
    
    return YES;
}

@end
