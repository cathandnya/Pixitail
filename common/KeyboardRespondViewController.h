//
//  KeyboardRespondViewController.h
//
//  Created by Naomoto nya on 12/02/08.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface KeyboardRespondViewController : UIViewController<UITextFieldDelegate, UITextViewDelegate> {
	BOOL keyboardIsShown;
}

@end


@interface KeyboardRespondTableViewController : KeyboardRespondViewController<UITableViewDelegate, UITableViewDataSource>

@property (retain, nonatomic) IBOutlet UITableView *tableView;

@end
