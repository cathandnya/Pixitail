//
//  AlertView.m
//
//  Created by nya on 10/11/29.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "AlertView.h"


@implementation AlertView

@synthesize object;

- (void) dealloc {
	self.object = nil;
	[super dealloc];
}

@end
