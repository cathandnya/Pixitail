//
//  ScrapingMatrixParser.m
//  pixiViewer
//
//  Created by Naomoto nya on 11/12/24.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//


#import "ScrapingMatrixParser.h"
#import "ScrapingMetadata.h"


@implementation ScrapingMatrixParser

@synthesize delegate, maxPage, scrapingInfo;

- (id) initWithEncoding:(NSStringEncoding)enc {
	self = [super initWithEncoding:enc];
	if (self) {
	}
	return self;
}

- (void) dealloc {
	self.scrapingInfo = nil;
	[super dealloc];
}

#pragma mark-

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
