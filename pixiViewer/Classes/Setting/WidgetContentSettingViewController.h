//
//  PixivWidgetSettingViewController.h
//  pixiViewer
//
//  Created by nya on 2014/10/14.
//
//

#import <UIKit/UIKit.h>
#import "AccountManager.h"
#import "DefaultViewController.h"

@interface WidgetContentSettingViewController : DefaultTableViewController
@property(strong) NSArray *widgets;
@property(strong) PixAccount *account;
@property(weak) id delegate;
@end
