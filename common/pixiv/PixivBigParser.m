//
//  PixivBigParser.m
//  pixiViewer
//
//  Created by nya on 09/08/19.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PixivBigParser.h"
#import "ScrapingMetadata.h"
#import "PixitailConstants.h"


@implementation PixivBigParser

@synthesize urlString;

- (id) initWithEncoding:(NSStringEncoding)enc async:(BOOL)b {
	self = [super initWithEncoding:enc async:b];
	if (self) {
		self.rootTag = [[[ScrapingTag alloc] initWithDictionary:[[PixitailConstants sharedInstance] valueForKeyPath:@"big.scrap"]] autorelease];
	}
	return self;
}

- (id) initWithEncoding:(NSStringEncoding)enc {
	self = [super initWithEncoding:enc];
	if (self) {
		self.rootTag = [[[ScrapingTag alloc] initWithDictionary:[[PixitailConstants sharedInstance] valueForKeyPath:@"big.scrap"]] autorelease];
	}
	return self;
}

- (void) dealloc {
	self.urlString = nil;
	[super dealloc];
}

- (void) endDocument {
	NSDictionary *mdic = [super evalResult:[[PixitailConstants sharedInstance] valueForKeyPath:@"big.eval"]];
	self.urlString = [mdic objectForKey:@"url"];
}

#if 0
- (void) startElementName:(NSString *)name attributes:(NSDictionary *)attributes {
	DLog(@"%@: %@", name, [attributes description]);
	if (state_ == PixivBigParserState_Initial && [name isEqualToString:@"body"]) {
		state_ |= PixivBigParserState_InBody;
	} else if ((state_ & PixivBigParserState_InBody) && [name isEqualToString:@"div"]) {
		state_ |= PixivBigParserState_InDiv;
	} else if ((state_ & PixivBigParserState_InDiv) && [name isEqualToString:@"a"]) {
		state_ |= PixivBigParserState_InA;
	} else if ((state_ & PixivBigParserState_InA) && [name isEqualToString:@"img"]) {
		self.urlString = [attributes objectForKey:@"src"];
	}
}

- (void) endElementName:(NSString *)name {
	if ((state_ & PixivBigParserState_InBody) && [name isEqualToString:@"body"]) {
		state_ &= ~PixivBigParserState_InBody;
	} else if ((state_ & PixivBigParserState_InDiv) && [name isEqualToString:@"div"]) {
		state_ &= ~PixivBigParserState_InDiv;
	} else if ((state_ & PixivBigParserState_InA) && [name isEqualToString:@"a"]) {
		state_ &= ~PixivBigParserState_InA;
	}
}

- (void) characters:(const unsigned char *)ch length:(int)len {
	//DLog([[[NSString alloc] initWithData:[NSData dataWithBytesNoCopy:(void *)ch length:len freeWhenDone:NO] encoding:encoding] autorelease]);
}
#endif

@end
