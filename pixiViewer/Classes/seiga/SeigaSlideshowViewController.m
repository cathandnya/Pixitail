//
//  SeigaSlideshowViewController.m
//  pixiViewer
//
//  Created by Naomoto nya on 11/12/22.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import "SeigaSlideshowViewController.h"
#import "Seiga.h"
#import "SeigaConstants.h"
#import "SeigaMediumParser.h"
#import "SeigaMatrixParser.h"
#import "SeigaMediumViewController.h"
#import "ImageDiskCache.h"


@implementation SeigaSlideshowViewController

- (NSString *) referer {
	return [[SeigaConstants sharedInstance] valueForKeyPath:@"urls.base"];
}

- (NSString *) matrixURL {
	return [NSString stringWithFormat:@"%@%@&page=%d", [[SeigaConstants sharedInstance] valueForKeyPath:@"urls.base"], self.method, loadedPage_ + 1];
}

- (NSString *) mediumURL:(NSString *)iid {
	return [NSString stringWithFormat:[[SeigaConstants sharedInstance] valueForKeyPath:@"urls.medium"], iid];
}

- (MediumParser *) mediumParser {
	return (MediumParser *)[[[SeigaMediumParser alloc] initWithEncoding:NSUTF8StringEncoding] autorelease];
}

- (MatrixParser *) matrixParser {
	return (MatrixParser *)[[[SeigaMatrixParser alloc] initWithEncoding:NSUTF8StringEncoding] autorelease];
}

- (id) mediumViewController {
	return [[[SeigaMediumViewController alloc] init] autorelease];
}

- (PixService *) pixiv {
	return [Seiga sharedInstance];
}

- (ImageCache *) cache {
	return [ImageCache seigaMediumCache];
}

@end
