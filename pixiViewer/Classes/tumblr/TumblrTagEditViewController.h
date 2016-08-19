//
//  TumblrTagEditViewController.h
//  pixiViewer
//
//  Created by nya on 10/05/30.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PixivTagAddViewController.h"
#import "DefaultViewController.h"


@class TumblrTagEditViewController;
@class PixAccount;


@protocol TumblrTagEditViewControllerDelegate
- (void) tagEditView:(TumblrTagEditViewController *)sender done:(BOOL)b;
@end


@interface TumblrTagEditViewController : DefaultTableViewController<PixivTagAddViewControllerDelegate> {
	PixAccount *account;
	NSArray *tags;
	NSMutableArray *list;
	id<TumblrTagEditViewControllerDelegate> delegate;
}

@property(readwrite, nonatomic, retain) PixAccount *account;
@property(readwrite, nonatomic, retain) NSArray *tags;
@property(readwrite, nonatomic, assign) id<TumblrTagEditViewControllerDelegate> delegate;

@end
