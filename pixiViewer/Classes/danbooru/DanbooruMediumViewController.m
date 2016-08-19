//
//  DanbooruMediumViewController.m
//  pixiViewer
//
//  Created by  on 11/07/25.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import "DanbooruMediumViewController.h"
#import "ImageDiskCache.h"
#import "Danbooru.h"
#import "DanbooruBigViewController.h"
#import "PixiViewerAppDelegate.h"
#import "AlwaysSplitViewController.h"
#import "DanbooruMatrixViewController.h"
#import "ImageLoaderManager.h"
#import "AccountManager.h"


@implementation DanbooruMediumViewController

- (ImageCache *) cache {
	return [ImageCache danbooruBigCache];
}

- (PixService *) pixiv {
	return [Danbooru sharedInstance];
}

- (NSString *) referer {
	return [NSString stringWithFormat:@"http://%@/", account.hostname];
}

- (ImageLoaderManager *) imageLoaderManager {
	ImageLoaderManager *loader = [ImageLoaderManager loaderWithType:ImageLoaderType_DanbooruMedium];
	loader.referer = [self referer];
	return loader;
}

- (NSString *) serviceName {
	return @"Danbooru";
}

- (NSMutableDictionary *) storeInfo {
	NSMutableDictionary *dic = [super storeInfo];
	
	[dic setObject:self.info forKey:@"Info"];
	
	return dic;
}

- (BOOL) restore:(NSDictionary *)dic {
	if (![super restore:dic]) {
		return NO;
	}
	
	self.info = [dic objectForKey:@"Info"];
	
	return YES;
}

- (long) reload {
	//[self update:self.info];
	[self performSelector:@selector(update:) withObject:self.info afterDelay:0.1];
	return 0;
}

- (void) imageButtonAction:(id)obj {
	DanbooruBigViewController *controller = nil;
	controller = [[DanbooruBigViewController alloc] initWithNibName:@"PixivBigViewController" bundle:nil];
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
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://%@/post/show/%@", account.hostname, self.illustID]]];
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
	Danbooru *service = (Danbooru *)[self pixiv];
	NSData				*data = [((UIButton *)sender).titleLabel.text dataUsingEncoding:NSUTF8StringEncoding];
	NSMutableString		*method = [NSMutableString stringWithFormat:@"http://%@/post/index.json?tags=", service.account.hostname];
	int					i;
	
	for (i = 0; i < [data length]; i++) {
		[method appendFormat:@"%%%02X", ((unsigned char *)[data bytes])[i]];
	}
	
	DanbooruMatrixViewController *controller = [[DanbooruMatrixViewController alloc] init];
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
	return [NSString stringWithFormat:@"<a href=\"http://%@\">%@</a>", account.hostname, account.hostname];
}

- (NSString *) url {
	return [NSString stringWithFormat:@"http://%@/post/show/%@", account.hostname, self.illustID];
}

- (NSString *) parserClassName {
	return nil;
}

- (NSString *) sourceURL {
	return [self.info objectForKey:@"source"];
}

- (NSArray *) saveImageURLs {
	return [NSArray arrayWithObject:[self.info objectForKey:@"BigURLString"]];
}

@end
