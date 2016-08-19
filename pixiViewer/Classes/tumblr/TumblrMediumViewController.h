//
//  TumblrMediumViewController.h
//  pixiViewer
//
//  Created by nya on 10/01/25.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PixivMediumViewController.h"
#import "Tumblr.h"
#import "TumblrTagEditViewController.h"


@class PixAccount;

@interface TumblrMediumViewController : PixivMediumViewController<TumblrReblogDelegate, TumblrLikeDelegate, TumblrTagEditViewControllerDelegate, TumblrDeleteDelegate> {
	NSArray *newTags;
	BOOL enableTagEdit;
}

@property(retain, nonatomic, readwrite) NSDictionary *info;
@property(assign, nonatomic, readwrite) BOOL enableTagEdit;

@end
