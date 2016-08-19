//
//  TumblrBigViewController.m
//  pixiViewer
//
//  Created by nya on 10/01/25.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TumblrBigViewController.h"
#import "ImageDiskCache.h"
#import "Tumblr.h"
#import "TumblrMediumViewController.h"
#import "TumblrMatrixViewController.h"
#import "ImageLoaderManager.h"


@implementation TumblrBigViewController

@synthesize info;

- (void) dealloc {
	self.info = nil;
	[super dealloc];
}

- (ImageCache *) cache {
	return [ImageCache tumblrBigCache];
}

- (void) startParser {
}

- (NSString *) referer {
	return nil;
}

- (ImageLoaderManager *) imageLoaderManager {
	ImageLoaderManager *loader = [ImageLoaderManager loaderWithType:ImageLoaderType_Tumblr];
	loader.referer = [self referer];
	return loader;
}

- (PixService *) pixiv {
	return [Tumblr instance];
}

- (long) reload {
	long	err = [[self pixiv] allertReachability];
	if (err) {
		return err;
	}
	
	if ([info objectForKey:@"BigURLString"]) {
		[urlString_ release];
		urlString_ = [[info objectForKey:@"BigURLString"] retain];
		//[self update];
	} else {
		//[self startParser];
	}
	[self update];
	
	return 0;
}

/*
- (long) reload {
	UIImage *img = [[self cache] imageForKey:self.illustID];
	if (img) {
		[self setImage:img];
		[self updateDisplay];
		//[self.navigationController setToolbarHidden:YES animated:YES];
		return 0;
	}	
	
	UIProgressView	*act = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
	CGRect	frame = [act frame];
	frame.size.width = [self.view frame].size.width * 2.0 / 3.0;
	frame.origin.x = ([self.view frame].size.width - frame.size.width) / 2.0;
	frame.origin.y = ([self.view frame].size.height - frame.size.height) / 2.0;
	[act setFrame:frame];
	[act setTag:100];
	act.alpha = 0.8;
	act.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
	act.progress = 0.0;
	[self.view addSubview:act];
	//[act startAnimating];
	[act release];
	[self scrollView].alpha = 0.25;

	if ([info objectForKey:@"BigURLString"]) {
		[urlString_ release];
		urlString_ = [[info objectForKey:@"BigURLString"] retain];
		[self update];
	} else {

	}
	return 0;
}
*/

- (NSString *) serviceName {
	return @"Tumblr";
}

- (NSString *)url {
	if ([info objectForKey:@"url"]) {
		return [info objectForKey:@"url"];
	} else if ([info objectForKey:@"ShortenURL"]) {
		return [info objectForKey:@"ShortenURL"];
	} else {
		return nil;
	}
}

- (TumblrBigViewController *) nextController {
	NSDictionary *dic = [[[self parentMedium] parentMatrix] nextInfo:self.illustID];
	if ([self infoIsValid:dic]) {
		TumblrBigViewController *controller = [[[[self class] alloc] initWithNibName:@"PixivBigViewController" bundle:nil] autorelease];
		controller.info = dic;
		controller.illustID = [self nextIID];
		return controller;
	}
	return nil;
}

- (TumblrBigViewController *) prevController {
	NSDictionary *dic = [[[self parentMedium] parentMatrix] prevInfo:self.illustID];
	if ([self infoIsValid:dic]) {
		TumblrBigViewController *controller = [[[[self class] alloc] initWithNibName:@"PixivBigViewController" bundle:nil] autorelease];
		controller.info = dic;
		controller.illustID = [self prevIID];
		return controller;
	}
	return nil;
}

- (void) next {
	TumblrBigViewController *vc = [self nextController];
	if (vc) {
		[self replaceViewController:vc];
	}

	[[self parentMedium] next];
}

- (void) prev {
	TumblrBigViewController *vc = [self prevController];
	if (vc) {
		[self replaceViewController:vc];
	}

	[[self parentMedium] prev];
}

@end
