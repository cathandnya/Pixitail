//
//  DanbooruBigViewController.m
//  pixiViewer
//
//  Created by  on 11/07/25.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import "DanbooruBigViewController.h"
#import "ImageDiskCache.h"
#import "Danbooru.h"
#import "ImageLoaderManager.h"
#import "Danbooru.h"
#import "AccountManager.h"

@implementation DanbooruBigViewController

- (ImageCache *) cache {
	return [ImageCache danbooruBigCache];
}

- (void) startParser {
	//assert(0);
}

- (NSString *) referer {
	return nil;
}

- (ImageLoaderManager *) imageLoaderManager {
	ImageLoaderManager *loader = [ImageLoaderManager loaderWithType:ImageLoaderType_DanbooruBig];
	loader.referer = [self referer];
	return loader;
}

- (PixService *) pixiv {
	return [Danbooru sharedInstance];
}

- (NSString *) serviceName {
	return @"Danbooru";
}

- (NSString *) url {
	Danbooru *service = (Danbooru *)[self pixiv];
	return [NSString stringWithFormat:@"http://%@/post/show/%@", service.account.hostname, self.illustID];
}

- (Class) mangaClass {
	return nil;
}

- (NSDictionary *) infoForIllustID:(NSString *)iid {
	return [[self pixiv] infoForIllustID:iid];
}

@end
