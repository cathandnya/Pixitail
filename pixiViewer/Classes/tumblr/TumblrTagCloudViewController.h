//
//  TumblrTagCloudViewController.h
//  pixiViewer
//
//  Created by nya on 10/05/29.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "DefaultViewController.h"


@class PixAccount;


@interface TumblrTagCloudViewController : DefaultTableViewController<UIActionSheetDelegate> {
	PixAccount *account;
	NSString *name;

	NSArray *list;
}

@property(readwrite, nonatomic, retain) PixAccount *account;
@property(readwrite, nonatomic, retain) NSString *name;

@end
