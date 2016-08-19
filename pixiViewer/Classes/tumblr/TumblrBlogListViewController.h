//
//  TumblrBlogListViewController.h
//  pixiViewer
//
//  Created by nya on 10/06/05.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DefaultViewController.h"


@class PixAccount;
@interface TumblrBlogListViewController : DefaultTableViewController {
	PixAccount *account;
}

@property(readwrite, nonatomic, retain) PixAccount *account;

@end


@interface TumblrBlogAddViewController : DefaultViewController {
	UITextField *textField;
	id delegate;
}

@property(readwrite, nonatomic, retain) IBOutlet UITextField *textField;
@property(readwrite, nonatomic, assign) id delegate;

@end

