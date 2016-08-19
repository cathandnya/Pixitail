//
//  SeigaConstants.m
//  pixiViewer
//
//  Created by Naomoto nya on 11/12/22.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import "SeigaConstants.h"


#define VERS	(13)


@implementation SeigaConstants

+ (ConstantsManager *) sharedInstance {
	static ConstantsManager *obj = nil;
	if (obj == nil) {
		obj = [[SeigaConstants alloc] init];
	}
	return obj;
}

- (NSString *) defaultConstantsPath {
	return [[NSBundle mainBundle] pathForResource:@"seiga" ofType:@"plist"];
}

- (id) init {
	self = [super init];
	if (self) {
		if (VERS > self.vers) {
			[self setConstants:[NSDictionary dictionaryWithContentsOfFile:[self defaultConstantsPath]]];
			[self setVers:VERS];
		}
	}
	return self;
}

- (NSString *) versURL {
	//return nil;
	return @"http://dl.dropbox.com/u/7748830/seiga.vers";
}

- (NSString *) constantsURL {
	return @"http://dl.dropbox.com/u/7748830/seiga.plist";
}

@end
