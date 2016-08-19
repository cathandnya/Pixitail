//
//  EvernoteAccountViewController.h
//  Tumbltail
//
//  Created by nya on 10/11/27.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TextFieldCell.h"
#import "DefaultViewController.h"


@interface EvernoteAccountViewController : DefaultTableViewController<TextFieldCellDelegate> {
	NSString *username;
	NSString *password;
}

@property(readwrite, nonatomic, copy) NSString *username;
@property(readwrite, nonatomic, copy) NSString *password;

@end
