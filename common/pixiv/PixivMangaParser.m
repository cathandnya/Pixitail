//
//  PixivMangaParser.m
//  pixiViewer
//
//  Created by nya on 09/09/18.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PixivMangaParser.h"
#import "ScrapingMetadata.h"
#import "PixitailConstants.h"


@implementation PixivMangaParser

@synthesize urlStrings;

- (void) dealloc {
	[urlStrings release];
	
	[super dealloc];
}

- (id) initWithEncoding:(NSStringEncoding)enc async:(BOOL)b {
	self = [super initWithEncoding:enc async:b];
	if (self) {
		self.rootTag = [[[ScrapingTag alloc] initWithDictionary:[[PixitailConstants sharedInstance] valueForKeyPath:@"manga.scrap"]] autorelease];
		
		self.urlStrings = [NSMutableArray array];
	}
	return self;
}

- (id) initWithEncoding:(NSStringEncoding)enc {
	self = [super initWithEncoding:enc];
	if (self) {
		self.rootTag = [[[ScrapingTag alloc] initWithDictionary:[[PixitailConstants sharedInstance] valueForKeyPath:@"manga.scrap"]] autorelease];

		self.urlStrings = [NSMutableArray array];
	}
	return self;
}

- (void) endDocument {
	DLog(@"end");
}


#if 0
- (void) startDocument {
	state_ = PixivMangaParserState_Initial;
	urlStrings = [[NSMutableArray alloc] init];
}

- (void) endDocument {
}

- (void) startElementName:(NSString *)name attributes:(NSDictionary *)attributes {
	DLog(@"%@: %@", name, [attributes description]);
	if (state_ == PixivMangaParserState_Initial && [name isEqualToString:@"body"]) {
		state_ |= PixivMangaParserState_InBody;
	} else if ((state_ & PixivMangaParserState_InBody) && [name isEqualToString:@"div"] && ([[attributes objectForKey:@"class"] hasPrefix:@"image-container"])) {
		state_ |= PixivMangaParserState_InImageContainer;
	} else if ((state_ & PixivMangaParserState_InImageContainer) && [name isEqualToString:@"img"]) {
		NSString	*src = [attributes objectForKey:@"src"];
		if (src && ![src hasPrefix:@"http://source."]) {
			NSString	*mode = [attributes objectForKey:@"data-mode"];
			if ([mode isEqual:@"2"] && [urlStrings count] > 1) {
				[urlStrings insertObject:src atIndex:urlStrings.count - 2];
			} else {
				[urlStrings addObject:src];
			}
		}
	}
}

- (void) endElementName:(NSString *)name {
	if ((state_ & PixivMangaParserState_InBody) && [name isEqualToString:@"body"]) {
		state_ &= ~PixivMangaParserState_InBody;
	} else if ((state_ & PixivMangaParserState_InImageContainer) && [name isEqualToString:@"div"]) {
		state_ &= ~PixivMangaParserState_InImageContainer;
	}
}

- (void) characters:(const unsigned char *)ch length:(int)len {
	// DLog([[[NSString alloc] initWithData:[NSData dataWithBytesNoCopy:(void *)ch length:len freeWhenDone:NO] encoding:encoding] autorelease]);
	/*
	if (tmpString_) {
		[tmpString_ appendString:[[[NSString alloc] initWithData:[NSData dataWithBytesNoCopy:(void *)ch length:len freeWhenDone:NO] encoding:encoding] autorelease]];
	}
	*/
}
#endif

@end
