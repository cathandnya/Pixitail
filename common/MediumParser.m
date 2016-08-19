//
//  MediumParser.m
//  pixiViewer
//
//  Created by nya on 09/09/22.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MediumParser.h"


@implementation MediumParser

@synthesize info;

- (id) initWithEncoding:(NSStringEncoding)enc {
	self = [super initWithEncoding:enc];
	if (self) {	
		info = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (void) dealloc {
	[info release];
	info = nil;
	
	[super dealloc];
}

@end
