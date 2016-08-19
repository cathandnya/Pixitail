//
//  TinamiCommentParser.m
//  pixiViewer
//
//  Created by nya on 10/02/24.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TinamiCommentParser.h"


@implementation TinamiCommentParser

@synthesize comments;

- (void) dealloc {
	[comments release];
	[tmpString release];
	
	[super dealloc];
}

- (void) startDocument {
}

- (void) endDocument {
}

- (void) startElementName:(NSString *)name attributes:(NSDictionary *)attributes {
	if ([name isEqual:@"comments"]) {
		comments = [[NSMutableArray alloc] init];
	} else if ([name isEqual:@"comment"]) {
		NSMutableDictionary *info = [NSMutableDictionary dictionary];
		if ([attributes objectForKey:@"authorname"]) [info setObject:[attributes objectForKey:@"authorname"] forKey:@"UserName"];
		if ([attributes objectForKey:@"datecreate"]) [info setObject:[attributes objectForKey:@"datecreate"] forKey:@"DateString"];
		if ([attributes objectForKey:@"id"]) [info setObject:[attributes objectForKey:@"id"] forKey:@"CommentID"];
		[comments addObject:info];
		
		tmpString = [[NSMutableString alloc] init];
	}
}


- (void) endElementName:(NSString *)name {
	if ([name isEqual:@"comment"] && [comments count] > 0) {
		NSMutableDictionary *info = [comments lastObject];
		[info setObject:[tmpString stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]] forKey:@"Comment"];
		[tmpString release];
		tmpString = nil;
	}
}

- (void) characters:(const unsigned char *)ch length:(int)len {
	if (tmpString) {
		[tmpString appendString:[[[NSString alloc] initWithData:[NSData dataWithBytesNoCopy:(void *)ch length:len freeWhenDone:NO] encoding:NSUTF8StringEncoding] autorelease]];
	}
}

@end
