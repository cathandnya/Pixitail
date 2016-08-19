//
//  ScrapMediumParser.m
//  pixiViewer
//
//  Created by Naomoto nya on 11/12/24.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import "ScrapingMediumParser.h"
#import "ScrapingMetadata.h"


@implementation ScrapingMediumParser

@synthesize info, scrapingInfo;

- (void) startDocument {
	self.rootTag = [[[ScrapingTag alloc] initWithDictionary:[scrapingInfo valueForKeyPath:@"scrap"]] autorelease];
	[super startDocument];
}

- (void) dealloc {
	self.info = nil;
	self.scrapingInfo = nil;
	[super dealloc];
}

- (void) endDocument {
	NSMutableDictionary *mdic = (NSMutableDictionary *)[super evalResult:[scrapingInfo valueForKeyPath:@"eval"]];
	self.info = mdic;
}

@end
