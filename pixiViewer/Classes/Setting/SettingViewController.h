//
//  SettingViewController.h
//  pixiViewer
//
//  Created by nya on 10/02/11.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "DefaultViewController.h"
#import "OAuthViewController.h"
#import "MultiSelectionViewController.h"
#import "ActivitySheetViewController.h"
#import "PasscodeLockViewController.h"
#import "SkyDrive.h"


@interface SettingViewController : DefaultTableViewController<OAuthViewControllerDelegate, UIAlertViewDelegate, MultiSelectionViewControllerDelegate, PasscodeLockViewControllerDelegate, SkyDriveLoginHandler> {
	UISwitch *disableSleepSwitch;
	UISwitch *showClockSwitch;
	UISwitch *autoRotateSwitch;
	UISwitch *saveFolderSwitch;
	UISwitch *saveTagsSwitch;
	UISwitch *saveTagsSwitchTumblr;
	UISwitch *tumblrTweetSwitch;
	
	ActivitySheetViewController *activityController;
}

@end


