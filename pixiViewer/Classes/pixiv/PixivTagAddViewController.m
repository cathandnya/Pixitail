//
//  PixivTagAddViewController.m
//  pixiViewer
//
//  Created by nya on 09/10/19.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PixivTagAddViewController.h"


@implementation PixivTagAddViewController
@synthesize baseView;

@synthesize delegate, titleString, defaultString, type, maxCount;
@synthesize textView_, doneButton_, navItem_, countLabel;

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

- (void) updateCount {
	if (maxCount > 0) {
		NSInteger count = [textView_.text length];
		
		self.countLabel.text = [NSString stringWithFormat:@"%@ / %d", @(count), maxCount];
		doneButton_.enabled = (0 < count && count <= maxCount);
	} else {
		self.countLabel.text = @"";
	}
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];

	if (self.titleString) {
		navItem_.title = self.titleString;
	}
	if (self.defaultString) {
		textView_.text = self.defaultString;
	}
	
	[textView_ becomeFirstResponder];
	[self performSelector:@selector(selectDelay) withObject:nil afterDelay:0.2];
	
	[self updateCount];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:YES];
	
	[self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void) selectDelay {
	textView_.selectedRange = NSMakeRange(0, 0);
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
    [self setBaseView:nil];
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
	[textView_ release];
	textView_ = nil;
	[navItem_ release];
	navItem_ = nil;
	[doneButton_ release];
	doneButton_ = nil;
	self.countLabel = nil;
}


- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[textView_ release];
	[navItem_ release];
	[doneButton_ release];
	[countLabel release];
	[titleString release];
	[defaultString release];
	[type release];

    [baseView release];
    [super dealloc];
}

/*
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	if ([[NSUserDefaults standardUserDefaults] objectForKey:@"Autorotate"]) {
		return [[NSUserDefaults standardUserDefaults] boolForKey:@"Autorotate"];
	} else {
		return YES;
	}
}
*/

- (IBAction) cancel {
	[delegate tagAddViewCancel:self];
}

- (IBAction) done {
	[delegate tagAddView:self done:[NSDictionary dictionaryWithObject:textView_.text forKey:@"Tag"]];
}

- (void)textViewDidChange:(UITextView *)textView {
	[self updateCount];
}

#pragma mark-

- (void) update:(NSDictionary *)dic {
	if (UIUserInterfaceIdiomPad == UI_USER_INTERFACE_IDIOM()) {
		return;
	}
	
	NSTimeInterval ti = [[dic objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];	
	CGRect keyboardFrameEnd = [self.view convertRect:[[dic objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue] fromView:nil];
	
	CGRect r;
	r.origin.x = 0;
	r.origin.y = 44;
	r.size.width = CGRectGetWidth(self.view.frame);
	r.size.height = CGRectGetHeight(self.view.frame) - CGRectGetHeight(keyboardFrameEnd) - r.origin.y;
	
	if (ti > 0) {
		[UIView animateWithDuration:ti animations:^{
			baseView.frame = r;
		} completion:^(BOOL finished) {
		}];
	} else {
		baseView.frame = r;
	}
}

- (void) keyboardWillShow:(NSNotification *)notif {
	if (UIUserInterfaceIdiomPad == UI_USER_INTERFACE_IDIOM()) {
		return;
	}
	
	[self update:[notif userInfo]];
}

- (void) keyboardDidShow:(NSNotification *)notif {
}

- (void) keyboardWillHide:(NSNotification *)notif {
}

- (void) keyboardDidHide:(NSNotification *)notif {
}

@end
