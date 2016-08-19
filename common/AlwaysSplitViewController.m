//
//  AlwaysSplitViewController.m
//  Pictures
//
//  Created by nya on 11/01/02.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "AlwaysSplitViewController.h"


@interface AlwaysSplitViewController(Private)
- (void) updateRootHideButton;
@end


@implementation AlwaysSplitViewController

@synthesize rootViewController, detailViewController;

#pragma mark -
#pragma mark Initialization

/*
- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization.
    }
    return self;
}
*/


#pragma mark -
#pragma mark View lifecycle

- (void) setRootViewController:(UIViewController *)vc {
	[self view];
	if (rootViewController) {
		[rootViewController.view removeFromSuperview];
		[rootViewController release];
	}
	rootViewController = [vc retain];

	CGRect r = rootView.frame;
	r.origin = CGPointZero;
	self.rootViewController.view.frame = r;
	self.rootViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	
	[self addChildViewController:self.rootViewController];
	[rootView addSubview:self.rootViewController.view];
	[self.rootViewController didMoveToParentViewController:self];
}

- (void) setDetailViewController:(UIViewController *)vc {
	[self view];
	if (detailViewController) {
		[detailViewController.view removeFromSuperview];
		[detailViewController release];
	}
	detailViewController = [vc retain];

	CGRect r = detailView.frame;
	r.origin = CGPointZero;
	self.detailViewController.view.frame = r;
	self.detailViewController.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

	[self addChildViewController:self.detailViewController];
	[detailView addSubview:self.detailViewController.view];
	[self.detailViewController didMoveToParentViewController:self];
	
	[self updateRootHideButton];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	CGRect r = self.view.frame;
	r.origin = CGPointZero;
	//r.origin.y = [UIApplication sharedApplication].statusBarFrame.size.height;
	//r.size.height -= r.origin.y;
	r.size.width = 320;
	rootView = [[UIView alloc] initWithFrame:r];
	rootView.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
		
	r.origin.x = 320 + 1;
	r.size.width = self.view.frame.size.width - 320 - 1;
	detailView = [[UIView alloc] initWithFrame:r];
	detailView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		
	[self.view addSubview:rootView];
	[self.view addSubview:detailView];

	self.view.backgroundColor = [UIColor blackColor];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	
	[self.rootViewController viewWillAppear:animated];
	[self.detailViewController viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

	[self.rootViewController viewDidAppear:animated];
	[self.detailViewController viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

	[self.rootViewController viewWillDisappear:animated];
	[self.detailViewController viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];

	[self.rootViewController viewDidDisappear:animated];
	[self.detailViewController viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	return YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	[super didRotateFromInterfaceOrientation:fromInterfaceOrientation];
	
	[self.rootViewController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
	[self.detailViewController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
	return UIStatusBarStyleLightContent;
}

#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
	[self.rootViewController didReceiveMemoryWarning];
	[self.detailViewController didReceiveMemoryWarning];
}

- (void)viewDidUnload {
	[super viewDidUnload];
	
	[rootView release];
	[detailView release];
	[self.rootViewController viewDidUnload];
	[self.detailViewController viewDidUnload];
}


- (void)dealloc {
	[rootView release];
	[detailView release];
	
	self.rootViewController = nil;
	self.detailViewController = nil;
	
    [super dealloc];
}

#pragma mark-

- (void) updateRootHideButton {
	if ([detailViewController isKindOfClass:[UINavigationController class]]) {
		UINavigationController *nc = (UINavigationController *)detailViewController;
		if (nc.viewControllers.count > 0) {
			UIViewController *vc = [nc.viewControllers objectAtIndex:0];
			if ([self rootIsHidden]) {
				vc.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@">" style:UIBarButtonItemStyleBordered target:self action:@selector(rootHideToggle:)] autorelease];
			} else {
				vc.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"<" style:UIBarButtonItemStyleBordered target:self action:@selector(rootHideToggle:)] autorelease];
			}
		}
	}
}

- (BOOL) rootIsHidden {
	return CGRectGetMaxX(rootView.frame) <= 0;
}

- (void) setRootHidden:(BOOL)hide animated:(BOOL)b {
	if ([self rootIsHidden] && !hide) {
		[UIView animateWithDuration:0.3 animations:^{
			CGRect r;
			
			r = rootView.frame;
			r.origin.x = 0;
			rootView.frame = r;
			
			r = self.view.frame;
			r.origin = CGPointZero;
			r.size.width -= CGRectGetWidth(rootView.frame) + 1;
			r.origin.x = CGRectGetWidth(rootView.frame) + 1;
			detailView.frame = r;
		} completion:^(BOOL finished) {
			[self updateRootHideButton];
		}];
	} else if (![self rootIsHidden] && hide) {
		[UIView animateWithDuration:0.3 animations:^{
			CGRect r;
			
			r = rootView.frame;
			r.origin.x = 0 - CGRectGetWidth(r);
			rootView.frame = r;
			
			r = self.view.frame;
			r.origin = CGPointZero;
			detailView.frame = r;
		} completion:^(BOOL finished) {
			[self updateRootHideButton];
		}];
	}
}

- (void) rootHideToggle:(id)sender {
	[self setRootHidden:![self rootIsHidden] animated:YES];
}

@end

