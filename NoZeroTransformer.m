//
//  NoZeroTransformer.m
//  SpotLook
//
//  Created by Nicolas Seriot on 15.03.08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "NoZeroTransformer.h"


@implementation NoZeroTransformer

+ (BOOL)allowsReverseTransformation {
    return NO;
}

+ (Class)transformedValueClass {
    return [NSString class];
}

- (id)transformedValue:(id)value {
    if ([value intValue] == 0) {
        return nil;
    }
	return [value description];
}

@end
