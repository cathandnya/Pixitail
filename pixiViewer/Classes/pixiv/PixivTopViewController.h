//
//  PixivTopViewController.h
//  pixiViewer
//
//  Created by nya on 10/02/11.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "DefaultViewController.h"
#import "PixService.h"


@class PixAccount;


@interface PixivTopViewController : DefaultTableViewController<UIActionSheetDelegate, UIAlertViewDelegate> {	
	PixAccount *account;
}

@property(readwrite, retain, nonatomic) PixAccount *account;

- (PixService *) pixiv;
- (void)setup;

- (NSUInteger) indexForIndexPath:(NSIndexPath *)path;

@end


NSString *tagMethodWithTag(NSString *tag);
