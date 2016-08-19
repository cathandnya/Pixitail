//
//  ApplicationInformationBigViewController.m
//  pixiViewer
//
//  Created by nya on 10/05/12.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ApplicationInformationBigViewController.h"


@implementation ApplicationInformationBigViewController

- (void) dealloc {
	[super dealloc];
}

- (ImageCache *) cache {
	return nil;
}

- (void) startParser {
}

- (NSString *) referer {
	return nil;
}

- (PixService *) pixiv {
	return nil;
}

- (long) reload {
	UIImage *img = [UIImage imageNamed:@"Default_big.png"];
	if (img) {
		[self setImage:img];
		[self updateDisplay];
	}
	return 0;
}

@end
