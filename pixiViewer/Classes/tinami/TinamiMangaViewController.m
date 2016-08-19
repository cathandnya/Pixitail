//
//  TinamiMangaViewController.m
//  pixiViewer
//
//  Created by nya on 10/03/02.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TinamiMangaViewController.h"
#import "ImageDiskCache.h"
#import "Tinami.h"
#import "TinamiBigViewController.h"


@implementation TinamiMangaViewController

- (ImageCache *) cache {
	return [ImageCache tinamiBigCache];
}

//- (void) startParser {
//	assert(0);
//}

- (NSString *) referer {
	return @"http://www.tinami.com/";
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

- (Class) bigClass {
	return [TinamiBigViewController class];
}

@end
