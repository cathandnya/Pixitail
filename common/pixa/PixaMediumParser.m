//
//  PixaMediumParser.m
//  pixiViewer
//
//  Created by nya on 09/09/22.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PixaMediumParser.h"


typedef enum {
	PixaMediumParserState_Initial			= 0x0000,
	PixaMediumParserState_Body				= 0x0001,
	PixaMediumParserState_InDivHeader		= 0x0002,
	PixaMediumParserState_InDivHeaderSpan	= 0x0004,
	PixaMediumParserState_InDivImage		= 0x0008,
	PixaMediumParserState_InDivImageA		= 0x0010,
	PixaMediumParserState_InProfileP		= 0x0020,
	PixaMediumParserState_InProfilePA		= 0x0040,
	PixaMediumParserState_InBookmarkSpan	= 0x0080,
	PixaMediumParserState_InBookmarkSpanA	= 0x0100,
} PixaMediumParserState;


@implementation PixaMediumParser

- (void) startDocument {
	state_ = PixaMediumParserState_Initial;
}

- (void) endDocument {
}

- (void) startElementName:(NSString *)name attributes:(NSDictionary *)attributes {
	//DLog(@"%@: %@", name, [attributes description]);
	if ((state_ == PixaMediumParserState_Initial) && [name isEqualToString:@"body"]) {
		state_ |= PixaMediumParserState_Body;
	} else if ((state_ & PixaMediumParserState_Body) && [name isEqualToString:@"div"]) {
		NSString	*ID = [attributes objectForKey:@"id"];
		if (ID && [ID isEqualToString:@"simple_header"]) {
			state_ |= PixaMediumParserState_InDivHeader;
		} else if (ID && [ID isEqualToString:@"image_view"]) {
			state_ |= PixaMediumParserState_InDivImage;
		}
	} else if ((state_ & PixaMediumParserState_InDivHeader) && [name isEqualToString:@"span"]) {
		stringTmp_ = [[NSMutableString alloc] init];
		state_ |= PixaMediumParserState_InDivHeaderSpan;
	} else if ((state_ & PixaMediumParserState_InDivImage) && [name isEqualToString:@"a"]) {
		NSString	*iid = [[attributes objectForKey:@"href"] lastPathComponent];
		if (iid) {
			[info setObject:iid forKey:@"IllustID"];
		}
		state_ |= PixaMediumParserState_InDivImageA;
	} else if ((state_ & PixaMediumParserState_InDivImage) && [name isEqualToString:@"img"]) {
		NSString	*src = [attributes objectForKey:@"src"];
		if (src) {
			[info setObject:src forKey:@"MediumURLString"];
		}
	} else if ((state_ & PixaMediumParserState_Body) && [name isEqualToString:@"p"]) {
		NSString	*cls = [attributes objectForKey:@"class"];
		if (cls && [cls isEqualToString:@"profile_name"]) {
			state_ |= PixaMediumParserState_InProfileP;
		}
	} else if ((state_ & PixaMediumParserState_InProfileP) && [name isEqualToString:@"a"]) {
		NSString	*uid = [[attributes objectForKey:@"href"] lastPathComponent];
		if (uid) {
			[info setObject:uid forKey:@"UserID"];
		}

		stringTmp_ = [[NSMutableString alloc] init];
		state_ |= PixaMediumParserState_InProfilePA;
	} else if ((state_ & PixaMediumParserState_Body) && [name isEqualToString:@"span"]) {
		NSString	*ID = [attributes objectForKey:@"id"];
		if (ID && [ID isEqualToString:@"status_bookmark"]) {
			state_ |= PixaMediumParserState_InBookmarkSpan;
		}
	} else if ((state_ & PixaMediumParserState_InBookmarkSpan) && [name isEqualToString:@"a"]) {
		NSString	*onclick = [attributes objectForKey:@"onclick"];
		if (onclick) {
			NSScanner	*scanner = [NSScanner scannerWithString:onclick];
			NSString	*authToken = nil;
			
			[scanner scanUpToString:@"encodeURIComponent(\'" intoString:nil];
			[scanner scanString:@"encodeURIComponent(\'" intoString:nil];
			[scanner scanUpToString:@"\')" intoString:&authToken];
			
			if (authToken) {
				[info setObject:authToken forKey:@"AuthenticityToken"];
			}
			state_ |= PixaMediumParserState_InBookmarkSpanA;
		}
	}
}


- (void) endElementName:(NSString *)name {
	if ((state_ & PixaMediumParserState_Body) && [name isEqualToString:@"body"]) {
		state_ &= ~PixaMediumParserState_Body;
	} else if ((state_ & PixaMediumParserState_InDivHeader) && [name isEqualToString:@"div"]) {
		state_ &= ~PixaMediumParserState_InDivHeader;
	} else if ((state_ & PixaMediumParserState_InDivHeaderSpan) && [name isEqualToString:@"span"]) {
		if ([info objectForKey:@"Title"] == nil) {
			[info setObject:stringTmp_ forKey:@"Title"];
		} else if ([info objectForKey:@"Comment"] == nil) {
			[info setObject:stringTmp_ forKey:@"Comment"];
		}
		[stringTmp_ release];
		stringTmp_ = nil;
		
		state_ &= ~PixaMediumParserState_InDivHeaderSpan;
	} else if ((state_ & PixaMediumParserState_InDivImage) && [name isEqualToString:@"div"]) {
		state_ &= ~PixaMediumParserState_InDivImage;
	} else if ((state_ & PixaMediumParserState_InDivImageA) && [name isEqualToString:@"a"]) {
		state_ &= ~PixaMediumParserState_InDivImageA;
	} else if ((state_ & PixaMediumParserState_InProfileP) && [name isEqualToString:@"p"]) {
		state_ &= ~PixaMediumParserState_InProfileP;
	} else if ((state_ & PixaMediumParserState_InProfilePA) && [name isEqualToString:@"a"]) {
		[info setObject:stringTmp_ forKey:@"UserName"];
	
		[stringTmp_ release];
		stringTmp_ = nil;
		
		state_ &= ~PixaMediumParserState_InProfilePA;
	} else if ((state_ & PixaMediumParserState_InBookmarkSpan) && [name isEqualToString:@"span"]) {
		state_ &= ~PixaMediumParserState_InBookmarkSpan;
	} else if ((state_ & PixaMediumParserState_InBookmarkSpanA) && [name isEqualToString:@"a"]) {
		state_ &= ~PixaMediumParserState_InBookmarkSpanA;
	}
}

- (void) characters:(const unsigned char *)ch length:(int)len {
	if (stringTmp_) {
		[stringTmp_ appendString:[[[NSString alloc] initWithData:[NSData dataWithBytesNoCopy:(void *)ch length:len freeWhenDone:NO] encoding:encoding] autorelease]];
	}
}

@end
