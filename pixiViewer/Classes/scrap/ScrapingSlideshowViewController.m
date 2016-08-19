//
//  ScrapingSlideshowViewController.m
//  pixiViewer
//
//  Created by Naomoto nya on 11/12/31.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import "ScrapingSlideshowViewController.h"
#import "ScrapingService.h"
#import "ImageDiskCache.h"
#import "ScrapingMediumViewController.h"
#import "ScrapingMatrixParser.h"
#import "ScrapingMediumParser.h"


@implementation ScrapingSlideshowViewController

@synthesize serviceName;
@dynamic service;

- (void) dealloc {
	self.serviceName = nil;
	[super dealloc];
}

- (PixService *) pixiv {
	return [ScrapingService serviceFromName:serviceName];
}

- (ScrapingService *) service {
	return (ScrapingService *)[self pixiv];
}

- (ImageCache *) cache {
	return [ImageCache mediumCacheForName:serviceName];
}

- (NSString *) referer {
	return [self.service.constants valueForKeyPath:@"urls.base"];
}

- (NSString *) matrixURL {
	return [NSString stringWithFormat:@"%@%@&page=%d", [self.service.constants valueForKeyPath:@"urls.base"], self.method, loadedPage_ + 1];
}

- (NSString *) mediumURL:(NSString *)iid {
	return [NSString stringWithFormat:[self.service.constants valueForKeyPath:@"urls.medium"], iid];
}

- (MediumParser *) mediumParser {
	Class parserClass = NSClassFromString([NSString stringWithFormat:@"%@MediumParser", serviceName]);
	if (parserClass == nil) {
		parserClass = [ScrapingMediumParser class];
	}
	ScrapingMediumParser *parser = [[parserClass alloc] initWithEncoding:NSUTF8StringEncoding];
	parser.scrapingInfo = [self.service.constants valueForKey:@"medium"];
	return (MediumParser *)[parser autorelease];
}

- (MatrixParser *) matrixParser {
	Class parserClass = NSClassFromString([NSString stringWithFormat:@"%@MatrixParser", serviceName]);
	if (parserClass == nil) {
		parserClass = [ScrapingMatrixParser class];
	}
	ScrapingMatrixParser *parser = [[parserClass alloc] initWithEncoding:NSUTF8StringEncoding];
	parser.scrapingInfo = [self.service.constants valueForKey:@"matrix"];
	return (MatrixParser *)[parser autorelease];
}

- (id) mediumViewController {
	Class class = NSClassFromString([NSString stringWithFormat:@"%@MediumViewController", serviceName]);
	if (!class) {
		class = [ScrapingMediumViewController class];
	}
	ScrapingMediumViewController *controller = [[class alloc] init];
	return [controller autorelease];
}

@end
