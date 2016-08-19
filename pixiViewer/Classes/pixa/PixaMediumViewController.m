//
//  PixaMediumViewController.m
//  pixiViewer
//
//  Created by nya on 09/09/22.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PixaMediumViewController.h"
#import "PixaMediumParser.h"
#import "PixaBigViewController.h"
#import "PixaMatrixViewController.h"
#import "Pixa.h"
#import "ImageDiskCache.h"
#import "AccountManager.h"
#import "PixiViewerAppDelegate.h"
#import "AlwaysSplitViewController.h"
#import "ImageLoaderManager.h"


@implementation PixaMediumViewController

- (ImageCache *) cache {
	return [ImageCache pixaMediumCache];
}

- (PixService *) pixiv {
	return [Pixa sharedInstance];
}

- (NSString *) referer {
	return @"http://www.pixa.cc/";
}

- (ImageLoaderManager *) imageLoaderManager {
	ImageLoaderManager *loader = [ImageLoaderManager loaderWithType:ImageLoaderType_PixaMedium];
	loader.referer = [self referer];
	return loader;
}

- (NSString *) serviceName {
	return @"PiXA";
}

/*
- (long) reload {
	long	err = [[Pixa sharedInstance] allertReachability];
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
		return err;
	} else if (err) {
		return err;
	}
	
	UIScrollView *scrollView = (UIScrollView *)self.view;
	scrollView.contentSize = CGSizeMake(320, 400);
	[scrollView scrollsToTop];
	
	NSDictionary	*info = [[Pixa sharedInstance] infoForIllustID:self.illustID];
	if ([info objectForKey:@"MediumURLString"]) {
		//[self update:info];
		[self performSelector:@selector(update:) withObject:info afterDelay:0.1];
	} else {
		PixaMediumParser		*parser = [[PixaMediumParser alloc] initWithEncoding:NSUTF8StringEncoding];
		CHHtmlParserConnection	*con = [[CHHtmlParserConnection alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.pixa.cc/illustrations/show/%@", self.illustID]]];
	
		con.referer = [self referer];
		con.delegate = self;
		parser_ = parser;
		connection_ = con;
	
		[con startWithParser:parser];
	}
	return 0;
}
 */

- (id) parser {
	return [[[PixaMediumParser alloc] initWithEncoding:NSUTF8StringEncoding] autorelease];
}

- (CHHtmlParserConnection *) connection {
	return [[[CHHtmlParserConnection alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.pixa.cc/illustrations/show/%@", self.illustID]]] autorelease];
}

- (void) imageButtonAction:(id)obj {
	PixaBigViewController *controller = nil;
	controller = [[PixaBigViewController alloc] initWithNibName:@"PixivBigViewController" bundle:nil];
	controller.illustID = self.illustID;
	//controller.account = account;
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		PixiViewerAppDelegate *app = (PixiViewerAppDelegate *)[UIApplication sharedApplication].delegate;
		[app pushViewController:controller animated:YES];
	} else {
		[self.navigationController pushViewController:controller animated:YES];
	}
	[controller release];
}

- (IBAction) addToBookmark:(id)sender {
	if (actionSheet_) [actionSheet_ dismissWithClickedButtonIndex:[actionSheet_ cancelButtonIndex] animated:NO];

	UIActionSheet	*alert = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Are you sure to add to favolite?", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Add to collection", nil), NSLocalizedString(@"Add to follow", nil), nil];
	if (([[UIDevice currentDevice] respondsToSelector:@selector(userInterfaceIdiom)] ? [[UIDevice currentDevice] userInterfaceIdiom] : 0) != 0) {
		[alert showFromBarButtonItem:sender animated:YES];
	} else {
		[alert showFromToolbar:self.navigationController.toolbar];
	}
	actionSheet_ = alert;
	[alert release];
}

- (void) add:(UIActionSheet *)sheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	UIAlertView	*alert = nil;

	// 追加
	NSMutableDictionary	*mdic = [[info_ mutableCopy] autorelease];
	if (buttonIndex == 0) {
		// コレクション
		[mdic setObject:[NSNumber numberWithBool:YES] forKey:@"IsOpen"];
		[mdic setObject:@"illust" forKey:@"Type"];
			
		[[self pixiv] addToBookmark:self.illustID withInfo:mdic];
	} else if (buttonIndex == 1) {
		// フォロー
		[mdic setObject:[NSNumber numberWithBool:NO] forKey:@"IsOpen"];
		[mdic setObject:@"user" forKey:@"Type"];

		[[self pixiv] addToBookmark:[info_ objectForKey:@"UserID"] withInfo:mdic];
	} 

	if (alert) {
		[alert show];
		[alert release];	
	} else {
		addButtonIndex_ = buttonIndex;
	}
}

- (IBAction) action:(id)sender {
	if (actionSheet_) [actionSheet_ dismissWithClickedButtonIndex:[actionSheet_ cancelButtonIndex] animated:NO];

	UIActionSheet	*alert;
    alert = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Go to pixaru search", nil), NSLocalizedString(@"Go to the web of this illust", nil), @"共有...", nil];
	if (([[UIDevice currentDevice] respondsToSelector:@selector(userInterfaceIdiom)] ? [[UIDevice currentDevice] userInterfaceIdiom] : 0) != 0) {
		[alert showFromBarButtonItem:sender animated:YES];
	} else {
		[alert showFromToolbar:self.navigationController.toolbar];
	}
	actionSheet_ = alert;
	[alert release];
}

- (IBAction) showUserIllust {
	PixivMatrixViewController *controller = [[PixaMatrixViewController alloc] init];
	controller.method = [NSString stringWithFormat:@"profiles/show/%@?", [info_ objectForKey:@"UserID"]];
	controller.navigationItem.title = [NSString stringWithFormat:NSLocalizedString(@"Illust by %@", nil), [info_ objectForKey:@"UserName"]];
	controller.account = account;
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		PixiViewerAppDelegate *app = (PixiViewerAppDelegate *)[UIApplication sharedApplication].delegate;
		[(UINavigationController *)app.alwaysSplitViewController.rootViewController pushViewController:controller animated:![app.alwaysSplitViewController rootIsHidden]];
		[app.alwaysSplitViewController setRootHidden:NO animated:YES];
	} else {
		[self.navigationController pushViewController:controller animated:YES];
	}
	[controller release];
}

- (IBAction) showPixaruIllust {
	PixivMatrixViewController *controller = [[PixaMatrixViewController alloc] init];
	controller.method = [NSString stringWithFormat:@"search/pixaru/%@?", self.illustID];
	controller.navigationItem.title = NSLocalizedString(@"Go to pixaru search", nil);
	controller.account = account;
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		PixiViewerAppDelegate *app = (PixiViewerAppDelegate *)[UIApplication sharedApplication].delegate;
		[(UINavigationController *)app.alwaysSplitViewController.rootViewController pushViewController:controller animated:![app.alwaysSplitViewController rootIsHidden]];
		[app.alwaysSplitViewController setRootHidden:NO animated:YES];
	} else {
		[self.navigationController pushViewController:controller animated:YES];
	}
	[controller release];
}

- (IBAction) goToWeb {	
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.pixa.cc/illustrations/show/%@", self.illustID]]];
}

- (void)action:(UIActionSheet *)sheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex != sheet.cancelButtonIndex) {
		switch (buttonIndex) {
		case 0:
			[self showPixaruIllust];
			break;
		case 1:
			[self goToWeb];
			break;
		case 2:
			[self twitter];
			break;
		default:
			break;
		}
	}
}

- (void) pixService:(PixService *)sender addBookmarkFinished:(long)err {
	UIAlertView	*alert = nil;
	if (addButtonIndex_ == 0) {
		// 公開
		if (err) {
			alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Add to collection failed.", @"") message:@"" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];				
		} else {
				alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Add to collection ok.", @"") message:@"" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];	
		}
	} else if (addButtonIndex_ == 1) {
		// 非公開
		if (err) {
			alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Add to follow failed.", @"") message:@"" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];				
		} else {
			alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Add to follow ok.", @"") message:@"" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];	
		}
	} 
	addButtonIndex_ = -1;
	
	[alert show];
	[alert release];	
}

- (UIBarButtonItem *) ratingButton {
	return nil;
}

- (BOOL) ratingEnabled {
	return NO;
}

- (BOOL) commentEnabled {
	return NO;
}

- (NSString *) tumblrServiceName {
	return @"<a href=\"http://www.pixa.cc/\">PiXA</a>";
}

- (NSString *) url {
	return [NSString stringWithFormat:@"http://www.pixa.cc/illustrations/show/%@", self.illustID];
}

- (NSString *) parserClassName {
	return @"PixaBigParser";
}

- (NSString *) sourceURL {
	return [NSString stringWithFormat:@"http://www.pixa.cc/illustrations/show_original/%@", self.illustID];
}

@end
