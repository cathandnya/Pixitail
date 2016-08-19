//
//  TumblrSlideshowViewController.h
//  pixiViewer
//
//  Created by nya on 10/01/28.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PixivSlideshowViewController.h"


@class PixAccount;

@interface TumblrSlideshowViewController : PixivSlideshowViewController {
	NSString *maxID;
}

@property(readwrite, nonatomic, retain) NSString *maxID;

@end
