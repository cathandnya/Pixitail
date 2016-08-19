//
//  TinamiRatingResponseParser.m
//  pixiViewer
//
//  Created by nya on 10/03/06.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TinamiRatingResponseParser.h"


@implementation TinamiRatingResponseParser

@synthesize rate;

- (void) startDocument {
}

- (void) endDocument {
}

- (void) startElementName:(NSString *)name attributes:(NSDictionary *)attributes {
	if ([name isEqual:@"rsp"] && ![[attributes objectForKey:@"stat"] isEqual:@"ok"]) {
		rate = -1;
	} else if (rate == 0 && [name isEqual:@"status"]) {
		rate = [[attributes objectForKey:@"supports"] intValue];
	}
}


- (void) endElementName:(NSString *)name {
}

- (void) characters:(const unsigned char *)ch length:(int)len {
}

@end
