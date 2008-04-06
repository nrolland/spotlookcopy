//
//  NSWorkspace+SL.m
//  SpotLook
//
//  Created by Nicolas Seriot on 03.04.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "NSWorkspace+SL.h"


@implementation NSWorkspace (SL)

- (void)triggerFoundUtisInSpotlightImporter:(NSString *)path delegate:(id)sender {
	NSBundle *b = [NSBundle bundleWithPath:path];
	NSDictionary *infoPlist = [b infoDictionary];
	NSArray *docTypes = [infoPlist objectForKey:@"CFBundleDocumentTypes"];
	for(NSDictionary *d in docTypes) {
		NSArray *icts = [d objectForKey:@"LSItemContentTypes"];
		for(NSString *uti in icts) {
			NSString *utiDescription = (NSString *)UTTypeCopyDescription((CFStringRef)uti);
			//NSLog(@"%@ %@", uti, utiDescription);
			[sender didFindUti:uti description:utiDescription];
		}
	}
}

// coded while watching TV, sorry for the style
- (void)searchForUTIInSpotlightImporters:(id)sender {
	
	NSArray *libDirs = NSSearchPathForDirectoriesInDomains (NSAllLibrariesDirectory, NSAllDomainsMask, YES);
	for(NSString *libDir in libDirs) {
		NSString *spotlight = [libDir stringByAppendingPathComponent:@"Spotlight"];
		for(NSString *importer in [[NSFileManager defaultManager] directoryContentsAtPath:spotlight]) {
			NSString *importerPath = [spotlight stringByAppendingPathComponent:importer];
			[self triggerFoundUtisInSpotlightImporter:importerPath delegate:sender];
		}
	}
	
	NSArray *appDirs = NSSearchPathForDirectoriesInDomains (NSAllApplicationsDirectory, NSAllDomainsMask, YES);
	for(NSString *appDir in appDirs) {
		NSArray *apps = [[[NSFileManager defaultManager] directoryContentsAtPath:appDir] pathsMatchingExtensions:[NSArray arrayWithObject:@"app"]];
		for(NSString *app in apps) {
			NSString *appPath = [appDir stringByAppendingPathComponent:app];
			NSString *spotlight = [[[appPath stringByAppendingPathComponent:@"Contents"] stringByAppendingPathComponent:@"Library"] stringByAppendingPathComponent:@"Spotlight"];
			for(NSString *importer in [[NSFileManager defaultManager] directoryContentsAtPath:spotlight]) {
				NSString *importerPath = [spotlight stringByAppendingPathComponent:importer];
				[self triggerFoundUtisInSpotlightImporter:importerPath delegate:sender];
			}
		}
	}
	
}


@end
