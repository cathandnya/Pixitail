//
//  BigURLDownloader.m
//  pixiViewer
//
//  Created by nya on 11/01/19.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "BigURLDownloader.h"
#import "BigParser.h"


@implementation BigURLDownloader

@synthesize parserClassName, bigSourceURL, object, delegate, imageURLs, referer;

- (void) dealloc {
	self.bigSourceURL = nil;
	self.referer = nil;
	
	[super dealloc];
}

#pragma mark-

- (void) clean {
	[self cancel];
}

- (void) failed:(NSError *)err {
	[self clean];
	
	[delegate performSelector:@selector(bigURLDownloader:finished:) withObject:self withObject:err];
}

- (void) completed {
	[self clean];

	[delegate performSelector:@selector(bigURLDownloader:finished:) withObject:self withObject:nil];
}

#pragma mark-

- (void) download {
	connection = [[CHHtmlParserConnection alloc] initWithURL:[NSURL URLWithString:bigSourceURL]];
	connection.delegate = self;
	connection.referer = self.referer;
	
	parser = [(BigParser *)[NSClassFromString(self.parserClassName) alloc] initWithEncoding:NSUTF8StringEncoding];

	[connection startWithParser:parser];
}

- (void) cancel {
	[connection cancel];
	[connection release];
	connection = nil;
	[parser release];
	parser = nil;
}

#pragma mark-

- (void) connection:(CHHtmlParserConnection *)con finished:(long)err {
	if (con == connection) {
		[imageURLs release];
		imageURLs = nil;
		if ([parser respondsToSelector:@selector(urlStrings)]) {
			imageURLs = [[parser performSelector:@selector(urlStrings)] retain];
		} else if ([parser respondsToSelector:@selector(urlString)]) {
			id url = [parser performSelector:@selector(urlString)];
			if (url) {
				imageURLs = [[NSArray arrayWithObject:url] retain];
			}
		} else if ([parser respondsToSelector:@selector(info)] && [[parser performSelector:@selector(info)] objectForKey:@"Images"]) {
			NSMutableArray *mary = [NSMutableArray array];
			for (NSDictionary *d in [[parser performSelector:@selector(info)] objectForKey:@"Images"]) {
				NSString *str = [d objectForKey:@"URLString"];
				if (str) {
					[mary addObject:str];
				}
			}
			imageURLs = [mary retain];
		}
		
		if ([imageURLs count] > 0) {
			[self completed];
		} else {
			[self failed:[NSError errorWithDomain:@"BigImageDownloader" code:err userInfo:[NSDictionary dictionary]]];
		}
	}
}

@end
