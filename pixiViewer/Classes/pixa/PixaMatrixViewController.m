//
//  PixaMatrixViewController.m
//  pixiViewer
//
//  Created by nya on 09/09/22.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PixaMatrixViewController.h"
#import "PixaMatrixParser.h"
#import "PixaMediumViewController.h"
#import "PixaSlideshowViewController.h"
#import "Pixa.h"
#import "ImageDiskCache.h"
#import "AccountManager.h"
#import "PixiViewerAppDelegate.h"
#import "AlwaysSplitViewController.h"


@implementation PixaMatrixViewController

- (ImageCache *) cache {
	return [ImageCache pixaSmallCache];
}

- (NSString *) referer {
	return @"http://www.pixa.cc/";
}

- (PixService *) pixiv {
	return [Pixa sharedInstance];
}

- (long) reload {
	long	err = [[Pixa sharedInstance] allertReachability];
	if (err) {
		return err;
	}
	/*
	if (err == -1) {
		[self pixiv].username = account.username;
		[self pixiv].password = account.password;
	
		err = [[self pixiv] login:self];
		if (err) {
			UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"ログインに失敗しました。" message:@"" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil] autorelease];
			[alert show];
			return err;
		} else {
			[self showProgress:YES withTitle:@"ログイン中..." tag:1000];
		}
		return 0;
	} else if (err) {
		return err;
	}
	 */
	
	if (storedContents) {
		[super restoreContents];
		return 0;
	}
	
	PixaMatrixParser		*parser = [[PixaMatrixParser alloc] initWithEncoding:NSUTF8StringEncoding async:NO];
	CHHtmlParserConnection	*con;
	
	showsNextButton_ = NO;

	pictureIsFound_ = NO;
	parser.delegate = self;
	parser.method = self.method;
	con = [[CHHtmlParserConnection alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.pixa.cc/%@page=%d", self.method, loadedPage_ + 1]]];
	
	con.referer = [self referer];
	con.delegate = self;
	parser_ = parser;
	connection_ = con;
	
	[con startWithParser:parser];
	[self.tableView reloadData];
	return 0;
}


- (void) selectImage:(ButtonImageView *)sender {
//- (void) matrixView:(CHMatrixView *)view action:(id)senderObject {	
	id senderObject = sender.object;
	PixaMediumViewController *controller = [[PixaMediumViewController alloc] init];
	controller.illustID = [senderObject objectForKey:@"IllustID"];
	controller.account = self.account;
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		PixiViewerAppDelegate *app = (PixiViewerAppDelegate *)[UIApplication sharedApplication].delegate;
		UINavigationController *nc = [[[UINavigationController alloc] initWithRootViewController:controller] autorelease];
		app.alwaysSplitViewController.detailViewController = nc;
	} else {
		[self.navigationController pushViewController:controller animated:YES];
	}
	[controller release];
}

- (IBAction) doSlideshow:(BOOL)random reverse:(BOOL)rev {
	PixivSlideshowViewController *controller = [[PixaSlideshowViewController alloc] initWithNibName:@"PixivSlideshowViewController" bundle:nil];
	controller.method = self.method;
	[controller setPage:loadedPage_];
	[controller setMaxPage:maxPage_];
	[controller setContents:contents_ random:random reverse:rev];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		PixiViewerAppDelegate *app = (PixiViewerAppDelegate *)[UIApplication sharedApplication].delegate;
		[app pushViewController:controller animated:YES];
	} else {
		[self.navigationController pushViewController:controller animated:YES];
	}
	[controller release];
}


- (BOOL) enableShuffle {
	return NO;
}

- (BOOL) enableAdd {
	return NO;
}

@end
