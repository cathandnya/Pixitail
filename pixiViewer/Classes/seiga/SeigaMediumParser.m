//
//  SeigaMediumParser.m
//  pixiViewer
//
//  Created by Naomoto nya on 11/12/22.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import "SeigaMediumParser.h"
#import "SeigaConstants.h"
#import "ScrapingMetadata.h"
#import "RegexKitLite.h"


@implementation SeigaMediumParser

@synthesize info;

- (id) initWithEncoding:(NSStringEncoding)enc async:(BOOL)b {
	self = [super initWithEncoding:enc async:b];
	if (self) {
		self.rootTag = [[[ScrapingTag alloc] initWithDictionary:[[SeigaConstants sharedInstance] valueForKeyPath:@"medium.scrap"]] autorelease];
	}
	return self;
}

- (id) initWithEncoding:(NSStringEncoding)enc {
	self = [super initWithEncoding:enc];
	if (self) {
		self.rootTag = [[[ScrapingTag alloc] initWithDictionary:[[SeigaConstants sharedInstance] valueForKeyPath:@"medium.scrap"]] autorelease];
	}
	return self;
}

#pragma mark-

- (void) startDocument {
	[super startDocument];
}

- (void) dealloc {
	self.info = nil;
	[super dealloc];
}

- (void) endDocument {
	NSMutableDictionary *mdic = (NSMutableDictionary *)[super evalResult:[[SeigaConstants sharedInstance] valueForKeyPath:@"medium.eval"]];
	self.info = mdic;
}

@end
