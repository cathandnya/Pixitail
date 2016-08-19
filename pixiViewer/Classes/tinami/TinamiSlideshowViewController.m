//
//  TinamiSlideshowViewController.m
//  pixiViewer
//
//  Created by nya on 10/02/27.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TinamiSlideshowViewController.h"
#import "TinamiContentParser.h"
#import "TinamiMatrixParser.h"
#import "TinamiMediumViewController.h"
#import "Tinami.h"
#import "ImageDiskCache.h"


@implementation TinamiSlideshowViewController

- (NSString *) referer {
	return @"http://www.tinami.com/";
}

- (NSString *) matrixURL {
	return [NSString stringWithFormat:@"http://api.tinami.com/%@&api_key=%@&page=%d", self.method, TINAMI_API_KEY, loadedPage_ + 1];
}

- (NSString *) mediumURL:(NSString *)iid {
	return [NSString stringWithFormat:@"http://api.tinami.com/content/info?api_key=%@&cont_id=%@", TINAMI_API_KEY, iid];
}

- (MediumParser *) mediumParser {
	return (MediumParser *)[[[TinamiContentParser alloc] initWithEncoding:NSUTF8StringEncoding] autorelease];
}

- (MatrixParser *) matrixParser {
	return (MatrixParser *)[[[TinamiMatrixParser alloc] initWithEncoding:NSUTF8StringEncoding] autorelease];
}

- (id) mediumViewController {
	return [[[TinamiMediumViewController alloc] init] autorelease];
}

- (PixService *) pixiv {
	return [Tinami sharedInstance];
}

- (ImageCache *) cache {
	return [ImageCache tinamiMediumCache];
}

@end
