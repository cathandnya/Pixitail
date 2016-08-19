//
//  TumblrTagBookmarkViewController.h
//  pixiViewer
//
//  Created by nya on 10/05/30.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PixivTagAddViewController.h"
#import "DefaultViewController.h"


@class PixAccount;


@interface TumblrTagBookmarkViewController : DefaultTableViewController<PixivTagAddViewControllerDelegate> {
	PixAccount *account;
	NSString *name;
}

@property(readwrite, nonatomic, retain) PixAccount *account;
@property(readwrite, nonatomic, retain) NSString *name;

@end
