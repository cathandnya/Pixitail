//
//  TinamiMediumViewController.m
//  pixiViewer
//
//  Created by nya on 10/02/24.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TinamiMediumViewController.h"
#import "ImageDiskCache.h"
#import "Tinami.h"
#import "TinamiContentParser.h"
#import "TinamiCommentParser.h"
#import "TinamiBigViewController.h"
#import "TinamiMatrixViewController.h"
#import "TinamiMangaViewController.h"
#import "AccountManager.h"
#import "TinamiNovelViewController.h"
#import "PixiViewerAppDelegate.h"
#import "AlwaysSplitViewController.h"
#import "ImageLoaderManager.h"


@implementation TinamiMediumViewController

@synthesize method;

- (void) dealloc {
	[commentConnection_ cancel];
	commentConnection_ = nil;
	[commentParser_ release];
	commentParser_ = nil;
	[method release];
	[super dealloc];
}

- (ImageCache *) cache {
	if ([[info_ objectForKey:@"ContentType"] isEqual:@"novel"]) {
		return [ImageCache tinamiSmallCache];
	} else {
		return [ImageCache tinamiMediumCache];
	}
}

- (PixService *) pixiv {
	return [Tinami sharedInstance];
}

- (NSString *) referer {
	return @"http://www.tinami.com/";
}

- (ImageLoaderManager *) imageLoaderManager {
	ImageLoaderManager *loader = [ImageLoaderManager loaderWithType:ImageLoaderType_Tinami];
	loader.referer = [self referer];
	return loader;
}

- (NSString *) serviceName {
	return @"TINAMI";
}

- (NSString *) ratingTitle {
	if ([[self pixiv] isRating:self.illustID]) {
		return nil;
	} else {
		return [[info_ objectForKey:@"RatingEnable"] boolValue] ? @"支援" : nil;
	}
}

- (void) update:(NSDictionary *)info {
	NSMutableDictionary *minfo = [[info mutableCopy] autorelease];
	[minfo setObject:self.illustID forKey:@"IllustID"];
	[super update:minfo];
}

- (void)viewDidUnload {
	[commentConnection_ cancel];
	commentConnection_ = nil;
	[commentParser_ release];
	commentParser_ = nil;
	
	[super viewDidUnload];
}

- (id) parser {
	return [[[TinamiContentParser alloc] initWithEncoding:NSUTF8StringEncoding] autorelease];
}

- (CHHtmlParserConnection *) connection {
	return [[[CHHtmlParserConnection alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://api.tinami.com/content/info?api_key=%@&cont_id=%@&models=1&dates=1", TINAMI_API_KEY, self.illustID]]] autorelease];
}

- (void) connection:(CHHtmlParserConnection *)con finished:(long)err {
	if (con == connection_) {
		//[[self.view viewWithTag:1234] removeFromSuperview];

		if ([[[parser_ info] objectForKey:@"Status"] isEqual:@"bookmark_user_only"] && [[parser_ info] objectForKey:@"ErrorMessage"]) {
			// お気に入り追加の必要がある
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[[parser_ info] objectForKey:@"ErrorMessage"] message:@"投稿したクリエイターをお気に入り登録すると見ることができます。お気に入り登録しますか？" delegate:self cancelButtonTitle:@"登録しない" otherButtonTitles:@"登録する", nil];
			alert.tag = 100;
			if (!alertShowing) {
				[alert show];
				alertShowing = YES;
			}
			[alert release];
			
			[info_ release];
			info_ = [[parser_ info] mutableCopy];
			
			[connection_ release];
			connection_ = nil;
			[parser_ release];
			parser_ = nil;
			return;
		} else if ([[[parser_ info] objectForKey:@"Status"] isEqual:@"user_only"] && [[parser_ info] objectForKey:@"ErrorMessage"]) {
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[[parser_ info] objectForKey:@"ErrorMessage"] message:@"TINAMIにユーザ登録しますか？（Safariを起動します）" delegate:self cancelButtonTitle:@"登録しない" otherButtonTitles:@"登録する", nil];
			alert.tag = 101;
			if (!alertShowing) {
				[alert show];
				alertShowing = YES;
			}
			[alert release];
			
			[connection_ release];
			connection_ = nil;
			[parser_ release];
			parser_ = nil;

			return;
		}
	
		[super connection:con finished:err];
		if (err == 0) {
			TinamiCommentParser		*parser = [[TinamiCommentParser alloc] initWithEncoding:NSUTF8StringEncoding];
			CHHtmlParserConnection	*con = [[CHHtmlParserConnection alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://api.tinami.com/content/comment/list?api_key=%@&cont_id=%@", TINAMI_API_KEY, self.illustID]]];
	
			con.referer = [self referer];
			con.delegate = self;
			commentParser_ = parser;
			commentConnection_ = con;
	
			[con startWithParser:parser];
		}
	} else if (con == commentConnection_) {
		[commentConnection_ release];
		commentConnection_ = nil;
		
		NSMutableDictionary *info = [info_ mutableCopy];
		[info setObject:commentParser_.comments forKey:@"OneComments"];
		[info autorelease];
		
		// キャッシュ
		[[self pixiv] addEntries:info forIllustID:self.illustID];
		
		[self updateInfo:info];
		[parser_ release];
		parser_ = nil;
	}
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	alertShowing = NO;
	if (alertView.tag == 100) {
		if (buttonIndex == 1) {
			// お気に入り追加
			UIAlertView	*alert = nil;
			long		err;

			NSMutableDictionary	*mdic = [[info_ mutableCopy] autorelease];
			[mdic setObject:@"bookmark" forKey:@"Type"];

			err = [[self pixiv] addToBookmark:[info_ objectForKey:@"UserID"] withInfo:mdic handler:self];
			if (err) {
				alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Add to favorite failed.", @"") message:@"" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];				
			}

			if (alert) {
				[alert show];
				[alert release];	
			} else {
				addButtonIndex_ = buttonIndex;
				needsReloadAfterAdd = YES;
			}
		} else {
			[self.navigationController popViewControllerAnimated:YES];
		}
	} else if (alertView.tag == 101) {
		if (buttonIndex == 1) {
			// ユーザ登録
			[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.tinami.com/entry/iphone/form"]];
		} else {
			[self.navigationController popViewControllerAnimated:YES];
		}
	}
}

- (BOOL) isFavoriteUser {
	if ([info_ objectForKey:@"IsFavoriteUser"]) {
		return [[info_ objectForKey:@"IsFavoriteUser"] boolValue];
	} else {
		return NO;
	}
}

- (BOOL) isBookmark {
	if ([info_ objectForKey:@"IsBookmark"]) {
		return [[info_ objectForKey:@"IsBookmark"] boolValue];
	} else {
		return NO;
	}
}

- (void) updateToolbar {
	if ([info_ count] == 0) {
		for (UIBarButtonItem *item in self.toolbarItems) {
			if (item.action == @selector(next)) {
				item.enabled = ([self nextIID] != nil);
			} else if (item.action == @selector(prev)) {
				item.enabled = ([self prevIID] != nil);
			} else {
				item.enabled = NO;
			}
		}
	} else {
		[super updateToolbar];
		if (self.account.anonymous || ([self isFavoriteUser] && [self isBookmark])) {
			for (UIBarButtonItem *item in self.toolbarItems) {
				if ([item action] == @selector(addToBookmark:)) {
					item.enabled = NO;
				}
			}			
		}
	}
}

#pragma mark-

- (void) imageButtonAction:(id)obj {
	if ([info_ objectForKey:@"Images"]) {
		/*
		NSMutableArray *ary = [NSMutableArray array];
		for (NSDictionary *i in [info_ objectForKey:@"Images"]) {
			[ary addObject:[i objectForKey:@"URLString"]];
		}
		*/
		
		TinamiMangaViewController *controller = nil;
		controller = [[TinamiMangaViewController alloc] init];
		controller.illustID = self.illustID;
		//[controller setURLs:ary];
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			PixiViewerAppDelegate *app = (PixiViewerAppDelegate *)[UIApplication sharedApplication].delegate;
			[app pushViewController:controller animated:YES];
		} else {
			[self.navigationController pushViewController:controller animated:YES];
		}
		[controller release];
	} else if ([[info_ objectForKey:@"ContentType"] isEqualToString:@"novel"]) {
		TinamiNovelViewController *controller = [[TinamiNovelViewController alloc] init];
		controller.pages = [info_ objectForKey:@"Pages"];
		controller.title = [info_ objectForKey:@"Title"];
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			PixiViewerAppDelegate *app = (PixiViewerAppDelegate *)[UIApplication sharedApplication].delegate;
			[app pushViewController:controller animated:YES];
		} else {
			[self.navigationController pushViewController:controller animated:YES];
		}
		[controller release];
	} else {
		TinamiBigViewController *controller = nil;
		controller = [[TinamiBigViewController alloc] initWithNibName:@"PixivBigViewController" bundle:nil];
		controller.illustID = self.illustID;
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			PixiViewerAppDelegate *app = (PixiViewerAppDelegate *)[UIApplication sharedApplication].delegate;
			[app pushViewController:controller animated:YES];
		} else {
			[self.navigationController pushViewController:controller animated:YES];
		}
		[controller release];
	}
}

- (NSString *) type {
	NSScanner *scanner = [NSScanner scannerWithString:self.method];
	NSString *tmp;
	BOOL b;
	
	if ([self.method hasPrefix:@"cont_type[]="]) {
		b = YES;
	} else {
		if ([self.method rangeOfString:@"cont_type[]="].location != NSNotFound) {
			b = [scanner scanUpToString:@"cont_type[]=" intoString:&tmp];
		} else {
			b = NO;
		}
	}
	if (b) {
		[scanner scanUpToString:@"&" intoString:&tmp];
		return tmp;
	}
	
	scanner = [NSScanner scannerWithString:self.method];
	if ([self.method hasPrefix:@"category"]) {
		b = YES;
	} else {
		if ([self.method rangeOfString:@"category"].location != NSNotFound) {
			b = [scanner scanUpToString:@"category" intoString:&tmp];
		} else {
			b = NO;
		}
	}
	if (b) {
		[scanner scanString:@"category=" intoString:nil];
		[scanner scanUpToString:@"&" intoString:&tmp];
		return [@"cont_type[]=" stringByAppendingString:tmp];
	}
	return nil;
}

- (void) tagButtonAction:(id)sender {
	NSString			*title = [((UIButton *)sender) titleForState:UIControlStateNormal];
	NSData				*data = [title dataUsingEncoding:NSUTF8StringEncoding];
	NSMutableString		*meth = [NSMutableString stringWithString:@"content/search?tags="];
	int					i;
	NSString			*type = [self type];
	
	for (i = 0; i < [data length]; i++) {
		[meth appendFormat:@"%%%02X", ((unsigned char *)[data bytes])[i]];
	}
	
	if (type) {
		[meth appendFormat:@"&%@", type];
	}
	
	TinamiMatrixViewController *controller = [[TinamiMatrixViewController alloc] init];
	controller.method = meth;
	controller.navigationItem.title = ((UIButton *)sender).titleLabel.text;
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

- (void) assist {
	[[self pixiv] rating:1 withInfo:info_];	
	//[self showProgress:YES withTitle:nil tag:200];
}

- (void) rating:(id)sender {
    [self assist];
    /*
	if (actionSheet_) [actionSheet_ dismissWithClickedButtonIndex:[actionSheet_ cancelButtonIndex] animated:NO];

	UIActionSheet	*alert = [[UIActionSheet alloc] initWithTitle:@"この作品を支援しますか？" delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:@"支援する", nil];
	alert.tag = 1000;
	if (([[UIDevice currentDevice] respondsToSelector:@selector(userInterfaceIdiom)] ? [[UIDevice currentDevice] userInterfaceIdiom] : 0) != 0) {
		[alert showFromBarButtonItem:sender animated:YES];
	} else {
		[alert showFromToolbar:self.navigationController.toolbar];
	}
	actionSheet_ = alert;
	[alert release];
     */
}

- (IBAction) addToBookmark:(id)sender {
	if (actionSheet_) [actionSheet_ dismissWithClickedButtonIndex:[actionSheet_ cancelButtonIndex] animated:NO];

	UIActionSheet	*alert;	
	if (![self isFavoriteUser] && ![self isBookmark]) {
		alert = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Are you sure to add to favolite?", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Collection", nil), @"お気に入りクリエイター", nil];
	} else if ([self isFavoriteUser]) {
		alert = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Are you sure to add to favolite?", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Collection", nil), nil];
	} else if ([self isBookmark]) {
		alert = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Are you sure to add to favolite?", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:@"お気に入りクリエイター", nil];
	} else {
		alert = nil;
	}
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

	needsReloadAfterAdd = NO;
	
	NSString *title = [sheet buttonTitleAtIndex:buttonIndex];
	if ([title isEqual:NSLocalizedString(@"Collection", nil)]) {
		buttonIndex = 0;
	} else if ([title isEqual:@"お気に入りクリエイター"]) {
		buttonIndex = 1;
	} else {
		buttonIndex = 2;
	}

	// 追加
	NSMutableDictionary	*mdic = [[info_ mutableCopy] autorelease];
	if (buttonIndex == 0) {
		// コレクション
		[mdic setObject:@"collection" forKey:@"Type"];
			
		[[self pixiv] addToBookmark:self.illustID withInfo:mdic];
	} else if (buttonIndex == 1) {
		// ブックマーク
		[mdic setObject:@"bookmark" forKey:@"Type"];

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
    alert = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Go to the web of this illust", nil), @"共有...", @"通報", nil];
	alert.destructiveButtonIndex = 2;
	if (([[UIDevice currentDevice] respondsToSelector:@selector(userInterfaceIdiom)] ? [[UIDevice currentDevice] userInterfaceIdiom] : 0) != 0) {
		[alert showFromBarButtonItem:sender animated:YES];
	} else {
		[alert showFromToolbar:self.navigationController.toolbar];
	}
	actionSheet_ = alert;
	[alert release];
}

- (IBAction) showUserIllust {
	NSString *type = [self type];
	NSString *typeString = nil;
	
	if ([type isEqual:@"cont_type[]=1"]) {
		typeString = @"イラスト";
	} else if ([type isEqual:@"cont_type[]=2"]) {
		typeString = @"マンガ";
	} else if ([type isEqual:@"cont_type[]=3"]) {
		typeString = @"モデル";
	} else if ([type isEqual:@"cont_type[]=5"]) {
		typeString = @"コスプレ";
	} else if ([type isEqual:@"cont_type[]=4"]) {
		typeString = @"小説";
	} else {
		typeString = @"作品";
	}

	TinamiMatrixViewController *controller = [[TinamiMatrixViewController alloc] init];
	controller.method = [NSString stringWithFormat:@"content/search?%@&prof_id=%@", type, [info_ objectForKey:@"UserID"]];
	controller.navigationItem.title = [NSString stringWithFormat:@"%@の%@", [info_ objectForKey:@"UserName"], typeString];
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
/*
	PixivMatrixViewController *controller = [[PixaMatrixViewController alloc] init];
	controller.method = [NSString stringWithFormat:@"search/pixaru/%@?", self.illustID];
	controller.navigationItem.title = [NSString stringWithFormat:NSLocalizedString(@"Go to pixaru search", nil)];
	[self.navigationController pushViewController:controller animated:YES];
	[controller release];
*/
}

- (IBAction) goToWeb {	
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.tinami.com/view/%@", self.illustID]]];
}

- (NSURL *) reportURL {
	return [NSURL URLWithString:[NSString stringWithFormat:@"http://www.tinami.com/allegation/%@", self.illustID]];
}

- (void) pixService:(PixService *)sender ratingFinished:(long)err {
	NSString *msg;
	[self hideProgress];
	
	if (err >= 0) {
		msg = NSLocalizedString(@"Assist ok.", nil);

		NSMutableDictionary *info = [info_ mutableCopy];
		[info setObject:[NSNumber numberWithInteger:err] forKey:@"valuation"];
		[info setObject:[NSNumber numberWithBool:NO] forKey:@"RatingEnable"];
		[info autorelease];
		
		[self updateInfo:info];
		[self updateToolbar];
	} else {
		msg = NSLocalizedString(@"Assist failed.", nil);
	}
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:msg message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
	[alert show];
	[alert release];
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
		case 2:
			[self report];
			break;
		default:
			break;
		}
	}
}

- (void)actionSheet:(UIActionSheet *)sheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	actionSheet_ = nil;
	if (sheet.tag == 1000) {
		// 支援
		if (buttonIndex == 0) {
			[self assist];
		}
	} else {
		[super actionSheet:sheet clickedButtonAtIndex:buttonIndex];
	}
}

- (void) pixService:(PixService *)sender addBookmarkFinished:(long)err {
	UIAlertView	*alert = nil;

	[self hideProgress];
	if (addButtonIndex_ == 0) {
		// コレクション
		if (err) {
			alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Add to collection failed.", @"") message:@"" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];				
		} else {
			alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Add to collection ok.", @"") message:@"" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];	
			
			NSMutableDictionary *dic = [info_ mutableCopy];
			[dic setObject:[NSNumber numberWithBool:YES] forKey:@"IsBookmark"];
			[info_ release];
			info_ = dic;
			
			[[self pixiv] addEntries:info_ forIllustID:self.illustID];
		}
	} else if (addButtonIndex_ == 1) {
		// ブックマーク
		if (err) {
			alert = [[UIAlertView alloc] initWithTitle:@"お気に入りクリエイターへの追加に失敗しました。" message:@"" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];				
		} else {
			if (needsReloadAfterAdd) {
				// 再ロード
				[self reload];
			} else {
				alert = [[UIAlertView alloc] initWithTitle:@"お気に入りクリエイターへ追加しました。" message:@"" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];	
			}
			
			NSMutableDictionary *dic = [info_ mutableCopy];
			[dic setObject:[NSNumber numberWithBool:YES] forKey:@"IsFavoriteUser"];
			[info_ release];
			info_ = dic;

			[[self pixiv] addEntries:info_ forIllustID:self.illustID];
		}
	} 
	addButtonIndex_ = -1;
	
	needsReloadAfterAdd = NO;
	
	[alert show];
	[alert release];	
	
	[self updateToolbar];
}

- (UIBarButtonItem *) ratingButton {
	return nil;
}

- (BOOL) ratingEnabled {
	return YES;
}

- (BOOL) commentEnabled {
	return YES;
}

- (NSString *) tumblrServiceName {
	return @"<a href=\"http://www.tinami.com/\">TINAMI</a>";
}

- (NSString *) url {
	return [NSString stringWithFormat:@"http://www.tinami.com/view/%@", self.illustID];
}

- (NSString *) parserClassName {
	return @"TinamiContentParser";
}

- (NSString *) sourceURL {
	return [NSString stringWithFormat:@"http://www.tinami.com/view/%@", self.illustID];
}

- (NSData *) saveImageData {
	if ([[info_ objectForKey:@"ContentType"] isEqual:@"novel"]) {
		return nil;
	} else if ([info_ objectForKey:@"Images"]) {
		return nil;
	} else {
		return [[self cache] imageDataForKey:self.illustID];
	}
}

- (NSArray *) saveImageURLs {
	if ([[info_ objectForKey:@"ContentType"] isEqual:@"novel"]) {
		return nil;
	} else if ([info_ objectForKey:@"Images"]) {
		NSMutableArray *ary = [NSMutableArray array];
		for (NSDictionary *d in [info_ objectForKey:@"Images"]) {
			[ary addObject:[d objectForKey:@"URLString"]];
		}
		return ary;
	} else {
		id obj = [info_ objectForKey:@"BigURLString"];
		if (obj) {
			return [NSArray arrayWithObject:obj];
		} else {
			return nil;
		}
	}
}

@end
