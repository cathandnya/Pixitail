//
//  PixiViewerAppDelegate.h
//  pixiViewer
//
//  Created by nya on 09/08/17.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PixService.h"
#import "PasscodeLockViewController.h"


@class AlwaysSplitViewController;
@class PixivTopViewController;


@interface PixiViewerAppDelegate : UINavigationController <UIApplicationDelegate, UITableViewDelegate, PixServiceLoginHandler, UIAlertViewDelegate, PasscodeLockViewControllerDelegate> {
    UIWindow *window;
	
	AlwaysSplitViewController *alwaysSplitViewController;
	PasscodeLockViewController *lockViewController;
	
	UIAlertView *loginAlert;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property(readwrite, nonatomic, retain) AlwaysSplitViewController *alwaysSplitViewController;

- (void) login:(PixivTopViewController *)vc;

@end
