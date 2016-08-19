//
//  NijieMediumParser.m
//  pixiViewer
//
//  Created by Naomoto nya on 12/06/27.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "NijieMediumParser.h"
#import "ScrapingMetadata.h"

@implementation NijieMediumParser

@synthesize illustID;

- (void) dealloc {
	self.illustID = nil;
	[super dealloc];
}

- (void) endDocument {
	NSMutableDictionary *mdic = (NSMutableDictionary *)[super evalResult:[self.scrapingInfo valueForKeyPath:@"eval"]];
	
	NSString *str = [mdic objectForKey:@"MediumURLString"];
	if (str) {
		[mdic setObject:[str stringByReplacingOccurrencesOfString:@"main/" withString:@""] forKey:@"BigURLString"];
	}
	
	NSArray *imgs = [mdic objectForKey:@"Images"];
	if (imgs.count > 0 && [mdic objectForKey:@"BigURLString"]) {
		NSMutableArray *images = [NSMutableArray array];
		[images addObject:[NSDictionary dictionaryWithObject:[mdic objectForKey:@"BigURLString"] forKey:@"URLString"]];
		for (NSDictionary *d in imgs) {
			[images addObject:[NSDictionary dictionaryWithObject:[d objectForKey:@"URL"] forKey:@"URLString"]];
		}
		
		[mdic setObject:images forKey:@"Images"];
	}
	if (imgs && imgs.count == 0) {
		[mdic removeObjectForKey:@"Images"];
	}
	
	self.info = mdic;
}

@end
