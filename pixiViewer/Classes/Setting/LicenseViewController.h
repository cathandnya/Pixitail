//
//  LicenseViewController.h
//  EchoPro
//
//  Created by nya on 09/08/13.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "DefaultViewController.h"


@class LicenseViewController;
@protocol LicenseViewControllerDelegate
- (void) licenseViewControllerDidEnd:(LicenseViewController *)sender;
@end


@interface LicenseViewController : DefaultViewController {
	id<LicenseViewControllerDelegate> delegate;
}

@property(nonatomic, assign) id<LicenseViewControllerDelegate> delegate;

@end
