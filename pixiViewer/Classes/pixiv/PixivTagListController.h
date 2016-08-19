//
//  PixivTagListController.h
//  pixiViewer
//
//  Created by nya on 09/10/19.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "DefaultViewController.h"
#import "PixivTagAddViewController.h"


@class PixAccount;

@interface PixivTagListController : DefaultTableViewController<PixivTagAddViewControllerDelegate> {
	NSMutableArray	*tags_;
	PixAccount *account;
}

@property(retain, nonatomic, readwrite) PixAccount *account;

@end
