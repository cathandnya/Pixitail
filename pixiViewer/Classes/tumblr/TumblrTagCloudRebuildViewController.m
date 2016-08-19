//
//  TumblrTagCloudRebuildViewController.m
//  pixiViewer
//
//  Created by nya on 10/05/29.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TumblrTagCloudRebuildViewController.h"
#import "TumblrParser.h"
#import "CHHtmlParserConnection.h"
#import "AccountManager.h"
#import "TagCloud.h"
#import "PixService.h"


@implementation TumblrTagCloudRebuildViewController

@synthesize button, progressView, progressLabel;
@synthesize account, name;

- (void) updateDisplay {
	if (connection) {
		[button setTitle:@"停止" forState:UIControlStateNormal];
		self.navigationItem.rightBarButtonItem.enabled = NO;
		progressView.hidden = NO;
		progressLabel.hidden = NO;
	} else {
		[button setTitle:@"再構築" forState:UIControlStateNormal];
		self.navigationItem.rightBarButtonItem.enabled = YES;
		progressView.hidden = YES;
		progressLabel.hidden = YES;
		progressLabel.text = @"";
	}
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

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
	self.title = @"タグクラウドの再構築";
	
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:)] autorelease];
}

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];

	self.button = nil;
	self.progressView = nil;
	self.progressLabel = nil;
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	[self updateDisplay];
}

- (void)dealloc {
	self.button = nil;
	self.progressView = nil;
	self.progressLabel = nil;

	[connection cancel];
	[connection release];
	connection = nil;
	[parser release];
	parser = nil;

    [super dealloc];
}

- (void) done:(id)sender {
	[self dismissModalViewControllerAnimated:YES];
}

- (void) loadNext {
	parser = [[TumblrParser alloc] initWithEncoding:NSUTF8StringEncoding];
	parser.delegate = self;
	
	NSString *authString;
	authString = [NSString stringWithFormat:@"&email=%@&password=%@", encodeURIComponent(account.username), encodeURIComponent(account.password)];
	
	if (index > 0) {
		connection = [[CHHtmlParserConnection alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@.tumblr.com/api/%@type=photo&start=%d&num=25%@", encodeURIComponent(name), @"read?", index, authString]]];
	} else {
		connection = [[CHHtmlParserConnection alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@.tumblr.com/api/%@type=photo&num=25%@", encodeURIComponent(name), @"read?", authString]]];		
	}
	
	connection.delegate = self;
	[connection startWithParser:parser];
}

- (IBAction) rebuild {
	if (connection) {
		[connection cancel];
		[connection release];
		connection = nil;
		[parser release];
		parser = nil;
	} else {
		[[TagCloud sharedInstance] cleanTagsForType:@"Tumblr" user:self.account.username];
	
		[self loadNext];
	}
	
	[self updateDisplay];
}

#pragma mark-

- (void) matrixParser:(id)p foundPicture:(NSDictionary *)pic {
	for (NSString *tag in [pic objectForKey:@"Tags"]) {
		DLog(@"add tag: %@", tag);
		[[TagCloud sharedInstance] add:tag forType:@"Tumblr" user:account.username];
	}

	index++;
	progressView.progress = (double)index / [parser maxPage];
	progressLabel.text = [NSString stringWithFormat:@"%d / %d", index, [parser maxPage]];
}

- (void) matrixParser:(id)p finished:(long)err {
}

- (void) connection:(CHHtmlParserConnection *)con finished:(long)err {
	int maxPage = parser.maxPage;

	[connection cancel];
	[connection release];
	connection = nil;
	[parser release];
	parser = nil;
	
	if (err) {
		// 失敗
		UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"再構築に失敗しました。" message:@"しばらくしてから再度お試しください。" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil] autorelease];
		[alert show];
	} else {
		if (index < maxPage) {
			// 次
			[self loadNext];
		} else {
			// おわた
			UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"再構築が完了しました。" message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil] autorelease];
			[alert show];
		}
	}

	[self updateDisplay];
}

@end
