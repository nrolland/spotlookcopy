//
//  NSWorkspace+SL.m
//  SpotLook
//
//  Created by Nicolas Seriot on 03.04.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "NSWorkspace+SL.h"


@implementation NSWorkspace (SL)

// coded while watching TV, sorry for the style
+ (NSArray *)registeredUTIs {
	NSMutableSet *s = [[NSMutableSet alloc] init];

	NSMutableArray *paths = [[NSMutableArray alloc] init];
	NSArray *directories = NSSearchPathForDirectoriesInDomains (NSAllApplicationsDirectory, NSAllDomainsMask, YES );
	for(NSString *dir in directories) {
		NSArray *content = [[NSFileManager defaultManager] directoryContentsAtPath:dir];
		for(NSString *c in content) {
			NSString *cc = [dir stringByAppendingPathComponent:c];
			NSString *ccc = [cc stringByAppendingPathComponent:@"Contents"];
			NSString *library = [ccc stringByAppendingPathComponent:@"Library"];
			NSString *librarySpotlight = [library stringByAppendingPathComponent:@"Spotlight"];
			for(NSString *importer in [[NSFileManager defaultManager] directoryContentsAtPath:librarySpotlight]) {
				NSString *pathImporter = [librarySpotlight stringByAppendingPathComponent:importer];
				[paths addObject:pathImporter];
			}
		}
	}

	directories = NSSearchPathForDirectoriesInDomains (NSAllLibrariesDirectory, NSAllDomainsMask, YES);
	for(NSString *dir in directories) {
		NSString *spotlight = [dir stringByAppendingPathComponent:@"Spotlight"];
		NSArray *content = [[NSFileManager defaultManager] directoryContentsAtPath:spotlight];
		for(NSString *c in content) {
			NSString *dc = [spotlight stringByAppendingPathComponent:c];
			[paths addObject:dc];
		}
	}
	
	NSPredicate *importerPredicate = [NSPredicate predicateWithFormat: @"SELF endswith %@", @".mdimporter"];
    NSArray *filteredPaths = [paths filteredArrayUsingPredicate:importerPredicate];

	//NSLog(@"filteredPaths %@", filteredPaths);

	NSMutableArray *plists = [[NSMutableArray alloc] init];
	for(NSString *fp in filteredPaths) {
		NSBundle *b = [NSBundle bundleWithPath:fp];
		NSDictionary *infoPlist = [b infoDictionary];
		NSArray *docTypes = [infoPlist objectForKey:@"CFBundleDocumentTypes"];
		for(NSDictionary *d in docTypes) {
			NSArray *icts = [d objectForKey:@"LSItemContentTypes"];
			for(NSString *uti in icts) {
				[s addObject:uti];
			}
		}
	}
	/*
	[utisController addObjects:[s allObjects]];

	NSArray *myUTIs = [[utisController arrangedObjects] sortedArrayUsingSelector:@selector(compare:)];
	NSLog([myUTIs description]);
	*/
	[paths release];
	[plists release];
	[s autorelease];
	
	return [[s allObjects] sortedArrayUsingSelector:@selector(compare:)];
}


@end
