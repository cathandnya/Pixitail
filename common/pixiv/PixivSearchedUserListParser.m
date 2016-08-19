//
//  PixivSearchedUserListParser.m
//  pixiViewer
//
//  Created by nya on 10/03/22.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PixivSearchedUserListParser.h"


typedef enum {
	PixivUserListParserState_Initial =		0x0001,
	PixivUserListParserState_InUserA =		0x0002,
	PixivUserListParserState_InPageA =		0x0004,
} PixivUserListParserState;


@implementation PixivSearchedUserListParser

@synthesize hasNext;
/*
- (void) dealloc {
	[super dealloc];
}

- (void) startDocument {
	[super startDocument];
}

- (void) endDocument {
	[super endDocument];
}

- (void) startElementName:(NSString *)name attributes:(NSDictionary *)attributes {
	if ([name isEqual:@"a"]) {
		NSString *href = [attributes objectForKey:@"href"];
		if ([href hasPrefix:@"member.php?"]) {
			NSScanner *s = [NSScanner scannerWithString:href];
			NSString *tmp = nil;
			NSString *mid = nil;
			BOOL b;
			b = [s scanUpToString:@"id=" intoString:&tmp];
			b = [s scanString:@"id=" intoString:&tmp];
			b = [s scanUpToString:@"&" intoString:&tmp];
			if (b && tmp) {
				mid = tmp;
			}
			
			if (mid) {
				if (infoTmp_) {
					if ([[infoTmp_ objectForKey:@"UserID"] isEqual:mid]) {
						stringTmp_ = [[NSMutableString alloc] init];
					}
				} else {
					infoTmp_ = [[NSMutableDictionary alloc] init];
				}
				[infoTmp_ setObject:mid forKey:@"UserID"];
			
				state_ |= PixivUserListParserState_InUserA;
			}
		} else if ([href hasPrefix:@"search_user.php?"]) {
			state_ |= PixivUserListParserState_InPageA;
		}
	} else if ((PixivUserListParserState_InUserA & state_) && [name isEqual:@"img"]) {
		[infoTmp_ setObject:[attributes objectForKey:@"src"] forKey:@"ImageURLString"];
	}
}

- (void) endElementName:(NSString *)name {
	if ([name isEqual:@"a"]) {
		if (stringTmp_) {
			[infoTmp_ setObject:stringTmp_ forKey:@"UserName"];
			[stringTmp_ release];
			stringTmp_ = nil;
			
			[list addObject:infoTmp_];
			[infoTmp_ release];
			infoTmp_ = nil;
		}
	}
}

- (void) characters:(const unsigned char *)ch length:(int)len {
	if (stringTmp_) {
		[stringTmp_ appendString:[[[NSString alloc] initWithData:[NSData dataWithBytesNoCopy:(void *)ch length:len freeWhenDone:NO] encoding:encoding] autorelease]];
	} else if (PixivUserListParserState_InPageA & state_) {
		NSString *str = [[[NSString alloc] initWithData:[NSData dataWithBytesNoCopy:(void *)ch length:len freeWhenDone:NO] encoding:encoding] autorelease];
		if ([str rangeOfString:@"次の20件"].location != NSNotFound) {
			hasNext = YES;
		}
	}
}
*/
@end
