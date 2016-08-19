//
//  OAuthViewController.m
//  EchoPro
//
//  Created by nya on 09/08/05.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "OAuthViewController.h"


static void CHShowAlert(NSString *title, NSString *message) {
	UIAlertView	*alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(title, title) message:NSLocalizedString(message, message) delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[alert show];
	[alert release];
}


@implementation OAuthViewController

@synthesize label, webView, pinField;
@synthesize url;

 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
		self.navigationController.navigationBar.delegate = self;
    }
    return self;
}

// Implement loadView to create a view hierarchy programmatically, without using a nib.
//- (void)loadView {
//}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	webView.delegate = self;

    [super viewDidLoad];

	UIBarButtonItem	*cancel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelWeb)];
	UIBarButtonItem	*done = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Auth", nil) style:UIBarButtonItemStyleDone target:self action:@selector(doneWeb)];
	self.navigationItem.leftBarButtonItem = cancel;
	self.navigationItem.rightBarButtonItem = done;
	[cancel release];
	[done release];
	
	label.text = NSLocalizedString(@"Copy PIN number displayed above.", nil);
	[webView loadRequest:[NSURLRequest requestWithURL:self.url]];
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	[super viewDidUnload];
	
	self.label = nil;
	self.webView = nil;
	self.pinField = nil;
}

- (void)viewWillDisappear:(BOOL)animated {
	if (webView.loading) {
		[webView.delegate webViewDidFinishLoad:webView];
		webView.delegate = nil;
	}

	[super viewWillDisappear:animated];
}

- (void)dealloc {
	self.label = nil;
	self.webView = nil;
	self.pinField = nil;
	
	[url release];

    [super dealloc];
}


- (void) setDelegate:(id<OAuthViewControllerDelegate>)del {
	delegate = del;
}


- (void)actionSheet:(UIActionSheet *)sheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == 0) {
		// OK
		[delegate oauthViewController:self didEnd:pinField.text];
	}
}

- (IBAction) doneWeb {
	[pinField resignFirstResponder];
	
	NSString		*pin = pinField.text;
	if ([pin length] == 7) {
		[self actionSheet:nil clickedButtonAtIndex:0];
		/*
		UIActionSheet	*alert = [[UIActionSheet alloc] initWithTitle:[NSString stringWithFormat:NSLocalizedString(@"PIN is valid?\n %@", nil), pin] delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:@"OK", nil];
	
		[alert showInView:self.view];
		[alert release];
		 */
	} else {
		// なんか違うものが入ってる
		CHShowAlert(@"PIN is invalid length", nil);
	}
}

- (IBAction) cancelWeb {
	[delegate oauthViewController:self didEnd:nil];
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorStartNotification" object:self];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:self];
}

#pragma mark-

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	return NO;
}

@end
