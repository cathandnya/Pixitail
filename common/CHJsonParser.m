//
//  CHJsonParser.m
//  pixiViewer
//
//  Created by  on 11/07/25.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import "CHJsonParser.h"

@implementation CHJsonParser

- (void) dealloc {
	[data release];
	[super dealloc];
}

- (void) addData:(NSData *)d {
	if (!data) {
		data = [[NSMutableData alloc] init];
	}
	[data appendData:d];
}

- (void) parse {
	
}

- (void) addDataEnd {
	[self parse];
	[data release];
	data = nil;
}

@end
