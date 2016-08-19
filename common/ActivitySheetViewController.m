//
//  ActivitySheetViewController.m
//
//  Created by nya on 11/02/16.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "ActivitySheetViewController.h"


@implementation ActivitySheetViewController

@synthesize activityView, progressView, label;

+ (ActivitySheetViewController *) activityController {
	return [[[ActivitySheetViewController alloc] initWithNibName:@"ActivitySheetViewController" bundle:nil] autorelease];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.view.alpha = 0.0;
}

- (void) viewDidUnload {
	[super viewDidUnload];
	
	self.activityView = nil;
	self.progressView = nil;
	self.label = nil;
}

- (void) dealloc {
	self.activityView = nil;
	self.progressView = nil;
	self.label = nil;

	[super dealloc];
}

- (void) hide {
	self.view.alpha = 0.0;
}

- (void) show {
	self.view.alpha = 1.0;
}

@end
