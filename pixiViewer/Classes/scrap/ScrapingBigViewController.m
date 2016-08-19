//
//  ScrapingBigViewController.m
//  pixiViewer
//
//  Created by Naomoto nya on 11/12/24.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import "ScrapingBigViewController.h"
#import "ScrapingService.h"
#import "ImageDiskCache.h"
#import "ImageLoaderManager.h"


@implementation ScrapingBigViewController

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

- (void) startParser {
	//assert(0);
}

- (ImageLoaderManager *) imageLoaderManager {
	ImageLoaderManager *loader = [ImageLoaderManager loaderWithName:serviceName];
	loader.referer = [self referer];
	return loader;
}

- (NSString *) serviceName {
	return NSLocalizedString(serviceName, nil);
}

- (NSString *) url {
	return [NSString stringWithFormat:[self.service.constants valueForKeyPath:@"urls.big"], self.illustID];
}

- (Class) mangaClass {
	return nil;
}

- (NSDictionary *) infoForIllustID:(NSString *)iid {
	NSMutableDictionary *mdic = [NSMutableDictionary dictionaryWithDictionary:[[self pixiv] infoForIllustID:iid]];
	if (![mdic objectForKey:@"BigURLString"] && [self.service.constants valueForKeyPath:@"urls.big"]) {
		[mdic setObject:[NSString stringWithFormat:[self.service.constants valueForKeyPath:@"urls.big"], self.illustID] forKey:@"BigURLString"];
	}
	return mdic;
}

@end
