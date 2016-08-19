//
//  TinamiUserlistParser.m
//  pixiViewer
//
//  Created by nya on 10/03/14.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TinamiUserlistParser.h"


@implementation TinamiUserlistParser

@synthesize method;
@synthesize list;
@synthesize maxPage;

- (void) dealloc {
	[tmpDic release];
	[tmpStr release];
	[method release];
	[list release];
	
	[super dealloc];
}

- (void) startDocument {
}

- (void) endDocument {
}

- (void) startElementName:(NSString *)name attributes:(NSDictionary *)attributes {
	if ([name isEqual:@"creators"]) {
		list = [[NSMutableArray alloc] init];
		if ([attributes objectForKey:@"pages"]) {
			maxPage = [[attributes objectForKey:@"pages"] intValue];
		}
	} else if ([name isEqual:@"creator"]) {
		tmpDic = [[NSMutableDictionary alloc] init];
		if ([attributes objectForKey:@"id"]) {
			[tmpDic setObject:[attributes objectForKey:@"id"] forKey:@"UserID"];
		}
	} else if ([name isEqual:@"name"]) {
		tmpStr = [[NSMutableString alloc] init];
	} else if ([name isEqual:@"thumbnail"]) {
		tmpStr = [[NSMutableString alloc] init];
	}
}


- (void) endElementName:(NSString *)name {
	if ([name isEqual:@"creator"]) {
		[list addObject:tmpDic];
		[tmpDic release];
		tmpDic = nil;
	} else if ([name isEqual:@"name"]) {
		[tmpDic setObject:tmpStr forKey:@"UserName"];
		[tmpStr release];
		tmpStr = nil;
	} else if ([name isEqual:@"thumbnail"]) {
		NSString *str = tmpStr;
		if ([str hasPrefix:@"/"]) {
			// 相対パス？
			str = [@"http://www.tinami.com" stringByAppendingString:str];
		}
		[tmpDic setObject:str forKey:@"ImageURLString"];
		[tmpStr release];
		tmpStr = nil;
	}
}

- (void) characters:(const unsigned char *)ch length:(int)len {
	if (tmpStr) {
		[tmpStr appendString:[[[NSString alloc] initWithData:[NSData dataWithBytesNoCopy:(void *)ch length:len freeWhenDone:NO] encoding:NSUTF8StringEncoding] autorelease]];
	}
}

@end
