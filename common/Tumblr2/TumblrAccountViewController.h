//
//  PixAccountViewController.h
//  Tumbltail
//
//  Created by nya on 10/11/27.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AccountViewControllerBase.h"
#import "TumblrAccountManager.h"
#import "Tumblr.h"


@class LoginRequest;


@interface TumblrAccountViewController : AccountViewControllerBase<UIActionSheetDelegate> {
	TumblrAccount *account;
	TumblrAccount *newAccount;
	LoginRequest *request;
}

@property(readwrite, nonatomic, retain) TumblrAccount *account;

@end
