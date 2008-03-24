//
//  AppDelegate+OutlineView.m
//  SpotLook
//
//  Created by Nicolas Seriot on 16.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate+OutlineView.h"
#import "ImageAndTextCell.h"
#import "SLTrack.h"
#import "SLTrackSet.h"

@implementation AppDelegate (OutlineView)

- (BOOL)isSpecialGroup:(SLArrayController *)groupNode {
	return (groupNode.icon == nil &&
			[groupNode.name isEqualToString:TRACKS] ||
			[groupNode.name isEqualToString:TRACKSGROUPS]);
}

-(BOOL)outlineView:(NSOutlineView*)outlineView isGroupItem:(id)item {
	return [self isSpecialGroup:[item representedObject]];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item; {
	id node = [item representedObject];
	return ![self isSpecialGroup:node];
}

- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor {
	return [[fieldEditor string] length] > 0;
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldEditTableColumn:(NSTableColumn *)tableColumn item:(id)item {
	item = [item representedObject];
	return ![self isSpecialGroup:item];
}

- (void)outlineView:(NSOutlineView *)olv willDisplayCell:(NSCell*)cell forTableColumn:(NSTableColumn *)tableColumn item:(id)anItem {
	SLArrayController *item = [anItem representedObject];
	[(ImageAndTextCell*)cell setImage:item.icon];
}

@end
