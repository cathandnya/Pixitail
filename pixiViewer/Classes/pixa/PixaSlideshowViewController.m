//
//  PixaSlideshowViewContrller.m
//  pixiViewer
//
//  Created by nya on 09/09/23.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PixaSlideshowViewController.h"
#import "PixaMediumParser.h"
#import "PixaMatrixParser.h"
#import "PixaMediumViewController.h"
#import "Pixa.h"
#import "ImageDiskCache.h"


@implementation PixaSlideshowViewController

- (NSString *) referer {
	return @"http://www.pixa.cc/";
}

- (NSString *) matrixURL {
	return [NSString stringWithFormat:@"http://www.pixa.cc/%@page=%d", self.method, loadedPage_ + 1];
}

- (NSString *) mediumURL:(NSString *)iid {
	return [NSString stringWithFormat:@"http://www.pixa.cc/illustrations/show/%@", iid];
}

- (MediumParser *) mediumParser {
	return [[[PixaMediumParser alloc] initWithEncoding:NSUTF8StringEncoding] autorelease];
}

- (MatrixParser *) matrixParser {
	return [[[PixaMatrixParser alloc] initWithEncoding:NSUTF8StringEncoding] autorelease];
}

- (PixivMediumViewController *) mediumViewController {
	return [[[PixaMediumViewController alloc] init] autorelease];
}

- (PixService *) pixiv {
	return [Pixa sharedInstance];
}

- (ImageCache *) cache {
	return [ImageCache pixaMediumCache];
}

@end
