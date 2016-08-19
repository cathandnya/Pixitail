//
//  ScrapingMangaViewController.m
//  pixiViewer
//
//  Created by Naomoto nya on 11/12/31.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import "ScrapingMangaViewController.h"
#import "ScrapingService.h"
#import "ImageDiskCache.h"
#import "ImageLoaderManager.h"
#import "ScrapingBigViewController.h"


@implementation ScrapingMangaViewController

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

- (NSString *) url {
	return [NSString stringWithFormat:[self.service.constants valueForKeyPath:@"urls.medium"], self.illustID];
}

- (Class) bigClass {
	return [ScrapingBigViewController class];
}


@end
