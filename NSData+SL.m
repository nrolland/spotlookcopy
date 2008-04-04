//
//  NSData+SL.m
//  SpotLook
//
//  Created by Nicolas Seriot on 04.04.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "NSData+SL.h"
#import <openssl/md5.h>


@implementation NSData (SL)

// http://www.cocoadev.com/index.pl?MDFive
- (NSString *)md5 {
	unsigned char* digest = MD5([self bytes], [self length], NULL);
	if (digest) {
		NSMutableString *ms = [NSMutableString string];
		int i;
		for (i = 0; i < MD5_DIGEST_LENGTH; i++) {
			[ms appendFormat: @"%02x", (int)(digest[i])];
		}
		return [[ms copy] autorelease];
	} else {
		/* digest failed */
		NSLog(@"digest failed");
		return nil;
	}
}

@end
