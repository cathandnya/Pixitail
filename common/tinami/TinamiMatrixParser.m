//
//  TinamiMatrixParser.m
//  pixiViewer
//
//  Created by nya on 10/02/24.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TinamiMatrixParser.h"


@implementation TinamiMatrixParser

@synthesize delegate;
@synthesize maxPage;

- (void) dealloc {
	[info_ release];
	
	[super dealloc];
}

- (void) startDocument {
}

- (void) endDocument {
	[delegate matrixParser:self finished:0];
}

- (void) startElementName:(NSString *)name attributes:(NSDictionary *)attributes {
	if ([name isEqual:@"contents"]) {
		maxPage = [[attributes objectForKey:@"pages"] intValue];
	} else if ([name isEqual:@"content"]) {
		info_ = [[NSMutableDictionary alloc] init];
		if ([attributes objectForKey:@"id"]) {
			[info_ setObject:[attributes objectForKey:@"id"] forKey:@"IllustID"];
		}
	} else if ([name isEqual:@"thumbnail_150x150"]) {
        NSString *url = [attributes objectForKey:@"url"];
		if (url) {
            if ([url hasPrefix:@"//"]) {
                url = [@"http:" stringByAppendingString:url];
            }
			[info_ setObject:url forKey:@"ThumbnailURLString"];
		}
	}
}


- (void) endElementName:(NSString *)name {
	if ([name isEqual:@"contents"]) {
		//[delegate matrixParser:self finished:0];
	} else if ([name isEqual:@"content"]) {
		[delegate matrixParser:self foundPicture:info_];
		[info_ release];
		info_ = nil;
	}
}

- (void) characters:(const unsigned char *)ch length:(int)len {
}

@end
