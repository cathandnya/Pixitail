//
//  PixivMediumCommentParser.m
//  pixiViewer
//
//  Created by nya on 10/08/31.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PixivMediumCommentParser.h"
#import "ScrapingMetadata.h"
#import "PixitailConstants.h"


@implementation PixivMediumCommentParser

@synthesize comments;

- (void) dealloc {
	[comments release];
	
	[super dealloc];
}

- (void) startDocument {
	comments = [NSMutableArray new];
	[super startDocument];
}

- (id) initWithEncoding:(NSStringEncoding)enc async:(BOOL)b {
	self = [super initWithEncoding:enc async:b];
	if (self) {
		self.rootTag = [[[ScrapingTag alloc] initWithDictionary:[[PixitailConstants sharedInstance] valueForKeyPath:@"comments.scrap"]] autorelease];
	}
	return self;
}

- (id) initWithEncoding:(NSStringEncoding)enc {
	self = [super initWithEncoding:enc];
	if (self) {
		self.rootTag = [[[ScrapingTag alloc] initWithDictionary:[[PixitailConstants sharedInstance] valueForKeyPath:@"comments.scrap"]] autorelease];
	}
	return self;
}

- (void) endDocument {
	//NSMutableDictionary *mdic = (NSMutableDictionary *)[super evalResult:[[PixitailConstants sharedInstance] valueForKeyPath:@"comments.eval"]];
	//DLog(@"%@", [mdic description]);
	for (ScrapingResult *res in self.results) {
		NSString *name = nil;
		NSString *date = nil;
		NSString *comment = nil;
		
		if (res.scrapedBodys.count > 0) {
			NSArray *ary = [res.scrapedBodys objectAtIndex:0];
			if (ary.count > 0) {
				comment = [[ary objectAtIndex:0] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
			}
		}
		for (ScrapingResult *r in res.children) {
			NSString *s = nil;
			if (r.scrapedBodys.count > 0) {
				NSArray *ary = [r.scrapedBodys objectAtIndex:0];
				if (ary.count > 0) {
					s = [ary objectAtIndex:0];
				}
			}
			if ([r.ID isEqual:@"a"]) {
				name = s;
			} else if ([r.ID isEqual:@"span"]) {
				date = s;
			}
		}
		
		NSMutableDictionary *mdic = [NSMutableDictionary dictionary];
		if (name) [mdic setObject:name forKey:@"UserName"];
		if (date) [mdic setObject:date forKey:@"DateString"];
		if (comment) [mdic setObject:comment forKey:@"Comment"];
		[comments addObject:mdic];
	}
}

#if 0
- (void) endDocument {
}

- (void) startElementName:(NSString *)name attributes:(NSDictionary *)attributes {
	if ([name isEqualToString:@"p"] && [[attributes objectForKey:@"class"] isEqualToString:@"worksComment"]) {
		state |= PixivMediumParserState_InOneCommentDivP;

		NSMutableArray	*ary = comments;
		if (ary) {
			[ary addObject:[NSMutableDictionary dictionary]];
		}
	} else if ((state & PixivMediumParserState_InOneCommentDivP) && [name isEqualToString:@"br"]) {		
		NSMutableArray	*ary = comments;
		if (ary && [ary count] > 0) {
			NSMutableDictionary	*oneComment = [ary lastObject];
			if ([oneComment objectForKey:@"UserName"] != nil && [oneComment objectForKey:@"DateString"] != nil && [oneComment objectForKey:@"Comment"] == nil) {
				state |= PixivMediumParserState_InOneCommentDivPText;
				tmpString = [[NSMutableString alloc] init];
			}
		}		
	} else if ([name isEqualToString:@"a"]) {
		if ((state & PixivMediumParserState_InOneCommentDivP) && [[attributes objectForKey:@"href"] rangeOfString:@"member.php"].location >= 0) {
			state |= PixivMediumParserState_InOneCommentDivPName;
			tmpString = [[NSMutableString alloc] init];
		}
	} else if ([name isEqualToString:@"span"]) {
		if ((state & PixivMediumParserState_InOneCommentDivP) && [[attributes objectForKey:@"class"] isEqualToString:@"worksCommentDate"]) {
			state |= PixivMediumParserState_InOneCommentDivPTime;
			tmpString = [[NSMutableString alloc] init];
		}
	}
}

- (void) endElementName:(NSString *)name {
	if ((state & PixivMediumParserState_InOneCommentDivP) && [name isEqualToString:@"p"]) {
		if (state & PixivMediumParserState_InOneCommentDivPText) {
			NSMutableArray	*ary = comments;
			if (ary && [ary count] > 0) {
				NSMutableDictionary	*oneComment = [ary lastObject];
				[oneComment setObject:tmpString forKey:@"Comment"];
			}
			[tmpString release];
			tmpString = nil;
			state &= ~PixivMediumParserState_InOneCommentDivPText;
		}
		
		state &= ~PixivMediumParserState_InOneCommentDivP;
	} else if ([name isEqualToString:@"a"]) {
		if (state & PixivMediumParserState_InOneCommentDivPName) {
			NSMutableArray	*ary = comments;
			if (ary && [ary count] > 0) {
				NSMutableDictionary	*oneComment = [ary lastObject];
				[oneComment setObject:tmpString forKey:@"UserName"];
			}
			[tmpString release];
			tmpString = nil;
			state &= ~PixivMediumParserState_InOneCommentDivPName;
		}
	} else if ([name isEqualToString:@"span"]) {
		if (state & PixivMediumParserState_InOneCommentDivPTime) {
			NSMutableArray	*ary = comments;
			if (ary && [ary count] > 0) {
				NSMutableDictionary	*oneComment = [ary lastObject];
				[oneComment setObject:tmpString forKey:@"DateString"];
			}
			[tmpString release];
			tmpString = nil;
			state &= ~PixivMediumParserState_InOneCommentDivPTime;
		}
	}
}

- (void) characters:(const unsigned char *)ch length:(int)len {
	if (tmpString) {
		[tmpString appendString:[[[NSString alloc] initWithData:[NSData dataWithBytesNoCopy:(void *)ch length:len freeWhenDone:NO] encoding:NSUTF8StringEncoding] autorelease]];
	}
}
#endif

@end
