//
//  ActivitySheetViewController.h
//
//  Created by nya on 11/02/16.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SheetViewController.h"


@interface ActivitySheetViewController : SheetViewController {
	UIActivityIndicatorView *activityView;
	UIProgressView *progressView;
	UILabel *label;
}

@property(readwrite, nonatomic, retain) IBOutlet UIActivityIndicatorView *activityView;
@property(readwrite, nonatomic, retain) IBOutlet UIProgressView *progressView;
@property(readwrite, nonatomic, retain) IBOutlet UILabel *label;

+ (ActivitySheetViewController *) activityController;

@end
