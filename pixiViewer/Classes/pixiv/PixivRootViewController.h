//
//  PixivRootViewController.h
//  pixiViewer
//
//  Created by nya on 09/08/22.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PixService.h"


@interface PixivRootViewController : UITableViewController<UIActionSheetDelegate, PixServiceLoginHandler> {
	NSIndexPath		*selectedIndex_;
	UIActionSheet	*actionSheet_;
	
	NSDictionary *account;
}

@property(readwrite, retain, nonatomic) NSDictionary *account;

@end
