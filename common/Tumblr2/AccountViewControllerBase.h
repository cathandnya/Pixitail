//
//  AccountViewController.h
//  Tumbltail
//
//  Created by nya on 10/09/19.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TextFieldCell.h"


@class ActivitySheetViewController;


@interface AccountViewControllerBase : UITableViewController<TextFieldCellDelegate> {
	NSString *username;
	NSString *password;
	ActivitySheetViewController *activityController;
}

@property(readwrite, nonatomic, copy) NSString *username;
@property(readwrite, nonatomic, copy) NSString *password;

- (void) showProgressWithTitle:(NSString *)str;
- (void) hideProgress;

@end
