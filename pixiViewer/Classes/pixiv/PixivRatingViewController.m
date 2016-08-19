//
//  PixivRatingViewController.m
//  pixiViewer
//
//  Created by nya on 09/11/28.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PixivRatingViewController.h"


@implementation PixivRatingViewController

@synthesize _picker, _navItem;
@synthesize ratingDelegate ,titleString;

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	if (self.titleString) {
		_navItem.title = self.titleString;
	}
	
	[_picker selectRow:9 inComponent:0 animated:NO];
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	[_navItem release];
	_navItem = nil;
	[_picker release];
	_picker = nil;
}


- (void)dealloc {
	[_navItem release];
	_navItem = nil;
	[_picker release];
	_picker = nil;
	
	self.titleString = nil;

    [super dealloc];
}

#pragma mark-

- (IBAction) done {
	[self.ratingDelegate ratingView:self done:[_picker selectedRowInComponent:0] + 1];
}

- (IBAction) cancel {
	[self.ratingDelegate ratingViewCancel:self];
}

#pragma mark-

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
	return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
	return 10;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
	return NSLocalizedString(([NSString stringWithFormat:@"Rate %@", @(row + 1)]), nil);
}

@end
