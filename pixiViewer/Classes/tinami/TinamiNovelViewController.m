//
//  TinamiNovelViewController.m
//  pixiViewer
//
//  Created by nya on 10/04/02.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TinamiNovelViewController.h"
#import "Tinami.h"
#import "ImageDiskCache.h"


@implementation TinamiNovelViewController

@synthesize pages;

- (void) dealloc {
	[pages release];
	[webView release];
	[super dealloc];
}

- (void) viewDidLoad {
	[super viewDidLoad];
	
	if (webView == nil) {
		UIWebView *wview = self.view ? [[UIWebView alloc] initWithFrame:self.view.frame] : [[UIWebView alloc] init];
		webView = wview;
	}
	self.view = webView;
		
	[self reload];
}

- (void) updateDisplay {
		NSMutableArray	*tmp = [NSMutableArray array];
		UIBarButtonItem	*item;
		UILabel			*label;
		
		item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRewind target:self action:@selector(prev)];
		[tmp addObject:item];
		[item setEnabled:0 < currentPage];
		[item release];

		item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
		[tmp addObject:item];
		[item release];
		
		label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 40)];
		label.textAlignment = UITextAlignmentCenter;
		label.text = [NSString stringWithFormat:@"%@ / %@", @(currentPage + 1), @([pages count])];
		label.backgroundColor = [UIColor clearColor];
		label.textColor = [UIColor whiteColor];
		item = [[UIBarButtonItem alloc] initWithCustomView:label];
		[label release];
		[tmp addObject:item];
		[item release];

		item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
		[tmp addObject:item];
		[item release];
		
		if (currentPage + 1 < [pages count]) {
			item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFastForward target:self action:@selector(next)];
		} else {
			item = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"replay.png"] style:UIBarButtonItemStylePlain target:self action:@selector(next)];
		}
		[tmp addObject:item];
		[item release];
		
		[self setToolbarItems:tmp animated:NO];
}

- (void) viewDidUnload {
	[super viewDidUnload];
	
	self.view = nil;
}

- (void)viewDidAppear:(BOOL)animated {	
	[super viewDidAppear:animated];
	
	[self.navigationController setNavigationBarHidden:NO animated:NO];
	[self.navigationController setToolbarHidden:NO animated:NO];
	[self updateDisplay];
}

- (void) viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	[self.navigationController setNavigationBarHidden:YES animated:YES];
	[self.navigationController setToolbarHidden:YES animated:YES];
}

- (void) reload {
	NSString *html = [pages objectAtIndex:currentPage];

	html = [NSString stringWithFormat:@"<html><body>　<br>　<br>%@　<br>　<br></body></html>", html];

	[webView loadHTMLString:html baseURL:nil];
	[self updateDisplay];
}

- (void) next {
	if (currentPage + 1 < [pages count]) {
		currentPage++;
		[self reload];
	} else {
		currentPage = 0;
		[self reload];
	}
}

- (void) prev {
	if (0 < currentPage) {
		currentPage--;
		[self reload];
	}
}

#pragma mark-

- (NSMutableDictionary *) storeInfo {
	NSMutableDictionary *info = [super storeInfo];
	
	[info setObject:[NSNumber numberWithInteger:currentPage] forKey:@"CurrentPage"];
	[info setObject:pages forKey:@"Pages"];

	return info;
}

- (BOOL) needsStore {
	return YES;
}

- (BOOL) restore:(NSDictionary *)info {
	id obj;
	
	obj = [info objectForKey:@"Pages"];
	if (obj == nil) {
		return NO;
	}
	self.pages = obj;

	obj = [info objectForKey:@"CurrentPage"];
	if (obj == nil) {
		return NO;
	}
	currentPage = [obj intValue];

	return YES;
}

@end
