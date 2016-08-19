//
//  PixivMatrixParser.m
//  pixiViewer
//
//  Created by nya on 09/08/20.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PixivMatrixParser.h"
#import "ScrapingMetadata.h"
#import "PixitailConstants.h"


@implementation PixivMatrixParser

@synthesize delegate, maxPage, scrapingInfo;

- (id) initWithEncoding:(NSStringEncoding)enc async:(BOOL)b {
	self = [super initWithEncoding:enc async:b];
	if (self) {
		self.scrapingInfo = [[PixitailConstants sharedInstance] valueForKeyPath:@"matrix"];
	}
	return self;
}

- (void) dealloc {
	self.scrapingInfo = nil;
	[super dealloc];
}

#pragma mark-

- (NSString *) illustIDKey {
	return [self.scrapingInfo valueForKeyPath:@"eval.illust_id_key"];
}

- (NSArray *) thumbURLKeys {
	return [self.scrapingInfo valueForKeyPath:@"eval.thumb_keys"];
}

- (void) startDocument {
	self.rootTag = [[[ScrapingTag alloc] initWithDictionary:[self.scrapingInfo valueForKeyPath:@"scrap"]] autorelease];
	[super startDocument];
}

- (void) endDocument {
	NSDictionary *mdic = [super evalResult:[self.scrapingInfo valueForKeyPath:@"eval"]];
	
	for (NSDictionary *d in [mdic objectForKey:@"Illusts"]) {
		if ([d objectForKey:@"ThumbnailURLString"] && [d objectForKey:@"IllustID"]) {
			[self.delegate matrixParser:self foundPicture:d];
		}
	}	
	if ([[mdic objectForKey:@"Pages"] count] > 0) {
		self.maxPage = [[[[mdic objectForKey:@"Pages"] sortedArrayUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
			return [[NSNumber numberWithInt:[obj1 intValue]] compare:[NSNumber numberWithInt:[obj2 intValue]]];
		}] lastObject] intValue];
	} else {
		self.maxPage = INT_MAX;
	}

	[delegate matrixParser:self finished:0];
}

@end
