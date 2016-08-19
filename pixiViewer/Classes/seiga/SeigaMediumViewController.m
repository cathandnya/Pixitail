//
//  SeigaMediumViewController.m
//  pixiViewer
//
//  Created by Naomoto nya on 11/12/22.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import "SeigaMediumViewController.h"
#import "SeigaConstants.h"
#import "Seiga.h"
#import "SeigaMediumParser.h"
#import "ImageDiskCache.h"
#import "ImageLoaderManager.h"
#import "SeigaMatixViewController.h"
#import "PixiViewerAppDelegate.h"
#import "AlwaysSplitViewController.h"
#import "SeigaBigViewController.h"


@implementation SeigaMediumViewController

- (ImageCache *) cache {
	return [ImageCache seigaMediumCache];
}

- (PixService *) pixiv {
	return [Seiga sharedInstance];
}

- (NSString *) referer {
	return [[SeigaConstants sharedInstance] valueForKeyPath:@"urls.base"];
}

- (ImageLoaderManager *) imageLoaderManager {
	ImageLoaderManager *loader = [ImageLoaderManager loaderWithType:ImageLoaderType_SeigaMedium];
	loader.referer = [self referer];
	return loader;
}

- (NSString *) serviceName {
	return NSLocalizedString(@"Seiga", nil);
}

- (void) update:(NSDictionary *)info {
	NSMutableDictionary *minfo = [[info mutableCopy] autorelease];
	[minfo setObject:self.illustID forKey:@"IllustID"];
	[super update:minfo];
}

- (id) parser {
	return [[[SeigaMediumParser alloc] initWithEncoding:NSUTF8StringEncoding] autorelease];
}

- (CHHtmlParserConnection *) connection {
	//[[NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:[[SeigaConstants sharedInstance] valueForKeyPath:@"urls.medium"], self.illustID]]] returningResponse:nil error:nil] writeToFile:[NSHomeDirectory() stringByAppendingPathComponent:@"medium.html"] atomically:YES];
	
	return [[[CHHtmlParserConnection alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:[[SeigaConstants sharedInstance] valueForKeyPath:@"urls.medium"], self.illustID]]] autorelease];
}

- (void) imageButtonAction:(id)obj {
	SeigaBigViewController *controller = nil;
	controller = [[SeigaBigViewController alloc] initWithNibName:@"PixivBigViewController" bundle:nil];
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

- (IBAction) showUserIllust {
	SeigaMatixViewController *controller = [[SeigaMatixViewController alloc] init];
	controller.method = [NSString stringWithFormat:[[SeigaConstants sharedInstance] valueForKeyPath:@"urls.user"], [info_ objectForKey:@"UserID"]];
	controller.navigationItem.title = [NSString stringWithFormat:@"%@の%@", [info_ objectForKey:@"UserName"], @"イラスト"];
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
}

- (IBAction) action:(id)sender {
	if (actionSheet_) [actionSheet_ dismissWithClickedButtonIndex:[actionSheet_ cancelButtonIndex] animated:NO];
	
	UIActionSheet	*alert;
	alert = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Go to the web of this illust", nil), @"共有...", nil];
	if (([[UIDevice currentDevice] respondsToSelector:@selector(userInterfaceIdiom)] ? [[UIDevice currentDevice] userInterfaceIdiom] : 0) != 0) {
		[alert showFromBarButtonItem:sender animated:YES];
	} else {
		[alert showFromToolbar:self.navigationController.toolbar];
	}
	actionSheet_ = alert;
	[alert release];
}

- (IBAction) goToWeb {	
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[self url]]];
}

- (void)action:(UIActionSheet *)sheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex != sheet.cancelButtonIndex) {
		switch (buttonIndex) {
			case 0:
				[self goToWeb];
				break;
			case 1:
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

- (void) tagButtonAction:(id)sender {
	NSData				*data = [((UIButton *)sender).titleLabel.text dataUsingEncoding:NSUTF8StringEncoding];
	NSMutableString		*tag = [NSMutableString string];
	int					i;
	
	for (i = 0; i < [data length]; i++) {
		[tag appendFormat:@"%%%02X", ((unsigned char *)[data bytes])[i]];
	}
	NSString *method = [NSString stringWithFormat:[[SeigaConstants sharedInstance] valueForKeyPath:@"urls.tag"], tag];
	
	SeigaMatixViewController *controller = [[SeigaMatixViewController alloc] init];
	controller.method = method;
	controller.account = account;
	controller.navigationItem.title = ((UIButton *)sender).titleLabel.text;
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		PixiViewerAppDelegate *app = (PixiViewerAppDelegate *)[UIApplication sharedApplication].delegate;
		[(UINavigationController *)app.alwaysSplitViewController.rootViewController pushViewController:controller animated:![app.alwaysSplitViewController rootIsHidden]];
		[app.alwaysSplitViewController setRootHidden:NO animated:YES];
	} else {
		[self.navigationController pushViewController:controller animated:YES];
	}
	[controller release];
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
	return [NSString stringWithFormat:@"<a href=\"http://seiga.nicovideo.jp\">%@</a>", [self serviceName]];
}

- (NSString *) url {
	return [NSString stringWithFormat:[[SeigaConstants sharedInstance] valueForKeyPath:@"urls.medium"], self.illustID];
}

- (NSString *) parserClassName {
	return @"SeigaMediumParser";
}

- (NSString *) sourceURL {
	return [self.info objectForKey:@"source"];
}

- (NSArray *) saveImageURLs {
	return @[self.info[@"MediumURLString"]];
}

@end
