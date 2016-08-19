//
//  PixaBigParser.m
//  pixiViewer
//
//  Created by nya on 09/09/22.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PixaBigParser.h"


@implementation PixaBigParser

- (void) startDocument {
}

- (void) endDocument {
}

- (void) startElementName:(NSString *)name attributes:(NSDictionary *)attributes {
	DLog(@"start: %@", name);
	if ([name isEqualToString:@"img"]) {
		self.urlString = [attributes objectForKey:@"src"];
	}
}


- (void) endElementName:(NSString *)name {
}

- (void) characters:(const unsigned char *)ch length:(int)len {
}

@end
