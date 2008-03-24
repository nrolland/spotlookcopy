// http://developer.apple.com/samplecode/PredicateEditorSample/listing5.html

#import "NSPredicate+SL.h"

@implementation NSPredicate (SL)

+(NSPredicate *) spotlightFriendlyPredicate:(id)predicate {
    if ([predicate isEqual:[NSPredicate predicateWithValue:YES]] || [predicate isEqual:[NSPredicate predicateWithValue:NO]]) {
		return nil;
	}  else if ([predicate isKindOfClass:[NSCompoundPredicate class]]) {
		NSCompoundPredicateType type = [predicate compoundPredicateType];
		NSMutableArray *cleanSubpredicates = [NSMutableArray array];
		for (NSPredicate *dirtySubpredicate in [predicate subpredicates]) {
			NSPredicate *cleanSubpredicate = [NSPredicate spotlightFriendlyPredicate:dirtySubpredicate];
			if (cleanSubpredicate) [cleanSubpredicates addObject:cleanSubpredicate];
		}
		
		if ([cleanSubpredicates count] == 0) {
			return nil;
		} else {
			if ([cleanSubpredicates count] == 1 && type != NSNotPredicateType) {
				return [cleanSubpredicates objectAtIndex:0];
			} else {
				return [[[NSCompoundPredicate alloc] initWithType:type subpredicates:cleanSubpredicates] autorelease];
			}
		}
    } else {
		return predicate;
	}

}

@end
