//
//  TumblrSlideshowViewController2.h
//  pixiViewer
//
//  Created by nya on 10/03/06.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PixivSlideshowViewController.h"


@class PixAccount;

@interface TumblrSlideshowViewController2 : PixivSlideshowViewController {
	NSString *name;
}

@property(readwrite, nonatomic, retain) NSString *name;

@end
