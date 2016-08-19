//
//  TumblrSlideshowViewController2.m
//  pixiViewer
//
//  Created by nya on 10/03/06.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TumblrSlideshowViewController2.h"
#import "AccountManager.h"
#import "TumblrParser.h"
#import "TumblrMediumViewController.h"
#import "Tumblr.h"
#import "ImageDiskCache.h"


@implementation TumblrSlideshowViewController2

@synthesize name;

- (void) dealloc {
	[name release];
	[super dealloc];
}

- (NSString *) referer {
	return nil;
}

- (NSString *) matrixURL {
	if ([self.method hasPrefix:@"read"]) {
		return [NSString stringWithFormat:@"http://%@.tumblr.com/api/%@type=photo&num=20&email=%@&password=%@&start=%d", name, self.method, encodeURIComponent(account.username), encodeURIComponent(account.password), loadedPage_];
	} else {
		return [NSString stringWithFormat:@"http://www.tumblr.com/api/%@?type=photo&num=20&email=%@&password=%@&start=%d", self.method, encodeURIComponent(account.username), encodeURIComponent(account.password), loadedPage_];
	}
}

- (NSString *) mediumURL:(NSString *)iid {
	NSArray *comp = [iid componentsSeparatedByString:@"_"];
	if ([comp count] == 2) {
		return [NSString stringWithFormat:@"http://%@.tumblr.com/api/read?id=%@", [comp objectAtIndex:0], [comp objectAtIndex:1]];
	} else {
		return [NSString stringWithFormat:@"http://%@.tumblr.com/api/read?id=%@", encodeURIComponent(name), iid];
	}
}

- (MediumParser *) mediumParser {
	return (MediumParser *)[[[TumblrParser alloc] initWithEncoding:NSUTF8StringEncoding] autorelease];
}

- (MatrixParser *) matrixParser {
	return (MatrixParser *)[[[TumblrParser alloc] initWithEncoding:NSUTF8StringEncoding] autorelease];
}

- (id) mediumViewController {
	return [[[TumblrMediumViewController alloc] init] autorelease];
}

- (PixService *) pixiv {
	return [Tumblr instance];
}

- (ImageCache *) cache {
	return [ImageCache tumblrBigCache];
}

@end
