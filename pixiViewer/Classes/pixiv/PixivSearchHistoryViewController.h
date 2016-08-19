//
//  PixivSearchHistoryViewController.h
//  pixiViewer
//
//  Created by nya on 09/11/28.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DefaultViewController.h"


@class PixAccount;

@interface PixivSearchHistoryViewController : DefaultTableViewController {
	PixAccount *account;
}

@property(retain, nonatomic, readwrite) PixAccount *account;

- (NSArray *) list;

@end
