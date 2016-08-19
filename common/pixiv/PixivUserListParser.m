//
//  PixivUserListParser.m
//  pixiViewer
//
//  Created by nya on 09/10/20.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PixivUserListParser.h"
#import "ScrapingMetadata.h"
#import "PixitailConstants.h"


@implementation PixivUserListParser

@synthesize method;
@synthesize list;
@synthesize maxPage;
@synthesize scrapingInfo;

- (id) initWithEncoding:(NSStringEncoding)enc async:(BOOL)b {
	self = [super initWithEncoding:enc async:b];
	if (self) {
		self.scrapingInfo = [[PixitailConstants sharedInstance] valueForKeyPath:@"user_list"];
		list = [[NSMutableArray alloc] init];
	}
	return self;
}

- (id) initWithEncoding:(NSStringEncoding)enc {
	self = [super initWithEncoding:enc];
	if (self) {
		self.scrapingInfo = [[PixitailConstants sharedInstance] valueForKeyPath:@"user_list"];
		list = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void) dealloc {
	self.method = nil;
	self.scrapingInfo = nil;
	[list release];
	[super dealloc];
}

- (void) startDocument {
	self.rootTag = [[[ScrapingTag alloc] initWithDictionary:[self.scrapingInfo valueForKeyPath:@"scrap"]] autorelease];
	[super startDocument];
}

- (void) endDocument {
	NSDictionary *mdic = [super evalResult:[scrapingInfo valueForKeyPath:@"eval"]];
	
	for (NSDictionary *d in [mdic objectForKey:@"Users"]) {
		if ([d objectForKey:@"ImageURLString"] && [[d objectForKey:@"UserID"] length] > 0 && [d objectForKey:@"UserName"]) {
			[list addObject:d];
		}
	}
	self.maxPage = [[[[mdic objectForKey:@"Pages"] sortedArrayUsingSelector:@selector(compare:)] lastObject] intValue];
}

#if 0
- (void) dealloc {
	[list release];
	[super dealloc];
}

- (void) startDocument {
	list = [[NSMutableArray alloc] init];
	state_ = PixivUserListParserState_Initial;
}

- (void) endDocument {
}

- (void) startElementName:(NSString *)name attributes:(NSDictionary *)attributes {
	if ((state_ == PixivUserListParserState_Initial) && [name isEqualToString:@"li"] && [[attributes objectForKey:@"class"] hasPrefix:@"list_person"]) {
		state_ |= PixivUserListParserState_InLi;
		infoTmp_ = [[NSMutableDictionary alloc] init];
	} else if ((state_ & PixivUserListParserState_InLiSpan) && [name isEqualToString:@"a"]) {
		state_ |= PixivUserListParserState_InLiSpanA;
		stringTmp_ = [[NSMutableString alloc] init];
	} else if ((state_ & PixivUserListParserState_InLi) && [name isEqualToString:@"a"] && [[attributes objectForKey:@"href"] rangeOfString:@"member.php"].location != NSNotFound) {
		state_ |= PixivUserListParserState_InLiA;
		
		if ([infoTmp_ count] == 0) {
			NSArray	*ary = [[attributes objectForKey:@"href"] componentsSeparatedByString:@"?"];
			if ([ary count] >= 2) {
				NSDictionary	*dic = CHHtmlParserParseParam([ary objectAtIndex:1]);
				if ([dic objectForKey:@"id"]) {
					[infoTmp_ setObject:[NSNumber numberWithInt:[[dic objectForKey:@"id"] intValue]] forKey:@"UserID"];
				}
			}
		}
	} else if ((state_ & PixivUserListParserState_InLiA) && [name isEqualToString:@"img"]) {
		if ([attributes objectForKey:@"src"]) {
			[infoTmp_ setObject:[attributes objectForKey:@"src"] forKey:@"ImageURLString"];
		}
	} else if ((state_ & PixivUserListParserState_InLi) && [infoTmp_ objectForKey:@"UserName"] == nil && [name isEqualToString:@"span"]) {
		state_ |= PixivUserListParserState_InLiSpan;

	} else if ((state_ & PixivUserListParserState_Initial) && [name isEqualToString:@"div"] && [[attributes objectForKey:@"class"] isEqualToString:@"pages"]) {
		state_ |= PixivUserListParserState_InPager;
	} else if (((state_ & PixivUserListParserState_InPager) != 0) && [name isEqualToString:@"a"] && [[attributes objectForKey:@"href"] rangeOfString:@"bookmark.php"].location != NSNotFound) {
		NSArray	*ary = [[attributes objectForKey:@"href"] componentsSeparatedByString:@"?"];
		if ([ary count] >= 2) {
			NSDictionary	*dic = CHHtmlParserParseParam([ary objectAtIndex:1]);
			if ([dic objectForKey:@"p"]) {
				maxPage = [[dic objectForKey:@"p"] intValue];
			}
		}
	}
}

- (void) endElementName:(NSString *)name {
	if ((state_ & PixivUserListParserState_InLi) && [name isEqualToString:@"li"]) {
		[list addObject:infoTmp_];
		[infoTmp_ release];
		infoTmp_ = nil;

		state_ &= ~PixivUserListParserState_InLi;
	} else if ((state_ & PixivUserListParserState_InLiSpanA) && [name isEqualToString:@"a"]) {
		state_ &= ~PixivUserListParserState_InLiSpanA;
		if (stringTmp_) {
			[infoTmp_ setObject:stringTmp_ forKey:@"UserName"];
			[stringTmp_ release];
			stringTmp_ = nil;
		}
	} else if ((state_ & PixivUserListParserState_InLiA) && [name isEqualToString:@"a"]) {
		state_ &= ~PixivUserListParserState_InLiA;
	} else if ((state_ & PixivUserListParserState_InLiSpan) && [name isEqualToString:@"span"]) {
		state_ &= ~PixivUserListParserState_InLiSpan;
	} else if ((state_ & PixivUserListParserState_InPager) && [name isEqualToString:@"div"]) {
		state_ &= ~PixivUserListParserState_InPager;
	}
}

- (void) characters:(const unsigned char *)ch length:(int)len {
	if (stringTmp_) {
		[stringTmp_ appendString:[[[NSString alloc] initWithData:[NSData dataWithBytesNoCopy:(void *)ch length:len freeWhenDone:NO] encoding:encoding] autorelease]];
	}
}
#endif

@end
