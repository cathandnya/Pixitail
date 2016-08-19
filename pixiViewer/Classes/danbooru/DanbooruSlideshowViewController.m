//
//  DanbooruSlideshowViewController.m
//  pixiViewer
//
//  Created by  on 11/07/25.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import "DanbooruSlideshowViewController.h"
#import "DanbooruPostsParser.h"
#import "DanbooruMediumViewController.h"
#import "Danbooru.h"
#import "ImageDiskCache.h"
#import "AccountManager.h"

@implementation DanbooruSlideshowViewController

- (NSString *) referer {
	return [NSString stringWithFormat:@"http://%@/", account.hostname];
}

- (NSString *) matrixURL {
	return [NSString stringWithFormat:@"%@&limit=20&page=%d&login=%@&password_hash=%@", self.method, loadedPage_ + 1, encodeURIComponent(account.username), [Danbooru hashedPassword:account.password]];
}

- (NSString *) mediumURL:(NSString *)iid {
	return nil;
}

- (MediumParser *) mediumParser {
	return nil;
}

- (MatrixParser *) matrixParser {
	DanbooruPostsParser *parser = [[[DanbooruPostsParser alloc] init] autorelease];
	parser.urlBase = [NSString stringWithFormat:@"%@://%@", [[NSURL URLWithString:self.method] scheme], [[NSURL URLWithString:self.method] host]];
	return (MatrixParser *)parser;
}

- (id) mediumViewController {
	return [[[DanbooruMediumViewController alloc] init] autorelease];
}

- (PixService *) pixiv {
	return [Danbooru sharedInstance];
}

- (ImageCache *) cache {
	return [ImageCache danbooruMediumCache];
}

@end
