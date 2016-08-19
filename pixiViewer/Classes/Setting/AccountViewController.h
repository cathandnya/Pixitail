//
//  AccountViewController.h
//  pixiViewer
//
//  Created by nya on 09/12/16.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "DefaultViewController.h"
#import "PixService.h"


@class PixAccount;

@interface AccountViewController : DefaultTableViewController<UITextFieldDelegate, UIAlertViewDelegate, PixServiceLoginHandler> {
	PixAccount *account;
	PixAccount *originalAccount;

	UITextField *idField;
	UITextField *passField;
	UITextField *hostnameField;
	
	NSArray *rows;
	NSArray *sectionTitles;
}

@property(readwrite, nonatomic, copy) PixAccount *account;

- (IBAction) done;
- (IBAction) cancel;

@end

