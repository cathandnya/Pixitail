//
//  TinamiBigViewController.m
//  pixiViewer
//
//  Created by nya on 10/02/24.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TinamiBigViewController.h"
#import "Tinami.h"
#import "ImageDiskCache.h"
#import "TinamiMangaViewController.h"
#import "ImageLoaderManager.h"


@implementation TinamiBigViewController

- (ImageCache *) cache {
	return [ImageCache tinamiBigCache];
}

- (void) startParser {
	//assert(0);
}

- (NSString *) referer {
	return @"http://www.tinami.com/";
}

- (ImageLoaderManager *) imageLoaderManager {
	ImageLoaderManager *loader = [ImageLoaderManager loaderWithType:ImageLoaderType_Tinami];
	loader.referer = [self referer];
	return loader;
}

- (PixService *) pixiv {
	return [Tinami sharedInstance];
}

- (NSString *) serviceName {
	return @"TINAMI";
}

- (NSString *) url {
	return [NSString stringWithFormat:@"http://www.tinami.com/view/%@", self.illustID];
}

- (Class) mangaClass {
	return [TinamiMangaViewController class];
}

@end
