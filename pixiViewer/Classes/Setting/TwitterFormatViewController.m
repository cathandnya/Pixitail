    //
//  TwitterFormatViewController.m
//  pixiViewer
//
//  Created by nya on 10/04/25.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TwitterFormatViewController.h"


@implementation TwitterFormatViewController

@synthesize textView, authorLabelLabel, authorDescLabel, titleLabelLabel, titleDescLabel;

- (void) load {
	if ([[NSUserDefaults standardUserDefaults] objectForKey:@"TwitterFormat"]) {
		textView.text = [[NSUserDefaults standardUserDefaults] stringForKey:@"TwitterFormat"];
	} else {
#ifdef PIXITAIL
		textView.text = NSLocalizedString(@"Twitter format pixitail", nil);
#else
		textView.text = NSLocalizedString(@"Twitter format", nil);
#endif
	}
}

- (void) save {
	[[NSUserDefaults standardUserDefaults] setObject:textView.text forKey:@"TwitterFormat"];
}

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
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
	
	self.view.backgroundColor = [UIColor grayColor];
	self.title = @"フォーマット";
	
	[self load];
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
	
	[self save];
	self.textView = nil;
	
	self.authorLabelLabel = nil;
	self.authorDescLabel = nil;
	self.titleLabelLabel = nil;
	self.titleDescLabel = nil;
}

- (void)dealloc {
	[self save];
	self.textView = nil;
	
	self.authorLabelLabel = nil;
	self.authorDescLabel = nil;
	self.titleLabelLabel = nil;
	self.titleDescLabel = nil;

    [super dealloc];
}

@end


@implementation TumblrFormatViewController

- (void) load {
	if ([[NSUserDefaults standardUserDefaults] objectForKey:@"TumblrFormat"]) {
		textView.text = [[NSUserDefaults standardUserDefaults] stringForKey:@"TumblrFormat"];
	} else {
		textView.text = NSLocalizedString(@"Tumblr format", nil);
	}
}

- (void) save {
	[[NSUserDefaults standardUserDefaults] setObject:textView.text forKey:@"TumblrFormat"];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	self.authorLabelLabel.hidden = YES;
	self.authorDescLabel.hidden = YES;
	self.titleLabelLabel.hidden = YES;
	self.titleDescLabel.hidden = YES;
}

@end
