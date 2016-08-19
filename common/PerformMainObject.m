//
//  PerformMainObject.m
//  pixiViewer
//
//  Created by nya on 10/07/17.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PerformMainObject.h"


@implementation PerformMainObject

@synthesize target, selector;

- (void) performMain:(id)arg {
	if (target) {
		[target performSelector:selector withObject:arg];
	}
}

@end
