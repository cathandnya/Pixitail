//
//  TumblrSlideshowViewController.m
//  pixiViewer
//
//  Created by nya on 10/01/28.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TumblrSlideshowViewController.h"
#import "AccountManager.h"
#import "TumblrParser.h"
#import "TwitterParser.h"
#import "TumblrMediumViewController.h"
#import "Tumblr.h"
#import "ImageDiskCache.h"


@implementation TumblrSlideshowViewController

@synthesize maxID;

- (void) dealloc {
	[maxID release];
	
	[super dealloc];
}

- (NSString *) referer {
	return nil;
}

- (NSString *) matrixURL {
	if (maxID) {
		return [NSString stringWithFormat:@"http://www.tumblr.com/statuses/home_timeline.xml?count=40&max_id=%@", maxID];
	} else {
		return [NSString stringWithFormat:@"http://www.tumblr.com/statuses/home_timeline.xml?count=40"];
	}
}

- (NSString *) mediumURL:(NSString *)iid {
	NSArray *comp = [iid componentsSeparatedByString:@"_"];
	if ([comp count] == 2) {
		return [NSString stringWithFormat:@"http://%@.tumblr.com/api/read?id=%@", [comp objectAtIndex:0], [comp objectAtIndex:1]];
	} else {
		return nil;
	}
}

- (MediumParser *) mediumParser {
	return (MediumParser *)[[[TumblrParser alloc] initWithEncoding:NSUTF8StringEncoding] autorelease];
}

- (MatrixParser *) matrixParser {
	return (MatrixParser *)[[[TwitterParser alloc] initWithEncoding:NSUTF8StringEncoding] autorelease];
}

- (id) mediumViewController {
	return [[[TumblrMediumViewController alloc] init] autorelease];
}

- (PixService *) pixiv {
	return [Tumblr instance];
}

- (void) matrixParser:(MatrixParser *)parser foundPicture:(NSMutableDictionary *)pic {
	self.maxID = [pic objectForKey:@"StatusID"];
	
	[super matrixParser:parser foundPicture:pic];
}

- (ImageCache *) cache {
	return [ImageCache tumblrBigCache];
}

@end
