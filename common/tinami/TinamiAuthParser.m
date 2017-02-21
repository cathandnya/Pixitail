//
//  TinamiAuthParser.m
//  pixiViewer
//
//  Created by nya on 10/02/23.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TinamiAuthParser.h"


@implementation TinamiAuthParser

@synthesize status, errorMessage, creatorID, authKey;

- (void) dealloc {
	[status release];
	[errorMessage release];
	[creatorID release];
    [stringBuffer release];
    self.authKey = nil;
	
	[super dealloc];
}

- (void) startDocument {
}

- (void) endDocument {
}

- (void) startElementName:(NSString *)name attributes:(NSDictionary *)attributes {
	if ([name isEqual:@"rsp"]) {
		self.status = [attributes objectForKey:@"stat"];
	} else if ([name isEqual:@"err"]) {
		self.errorMessage = [attributes objectForKey:@"msg"];
	} else if ([name isEqual:@"creator"]) {
		self.creatorID = [attributes objectForKey:@"id"];
    } else if ([name isEqual:@"auth_key"]) {
        stringBuffer = [[NSMutableString alloc] init];
	}
}


- (void) endElementName:(NSString *)name {
    if ([name isEqual:@"auth_key"]) {
        self.authKey = [stringBuffer stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
}

- (void) characters:(const unsigned char *)ch length:(int)len {
    [stringBuffer appendString:[[[NSString alloc] initWithData:[NSData dataWithBytesNoCopy:(void *)ch length:len freeWhenDone:NO] encoding:encoding] autorelease]];
}

@end
