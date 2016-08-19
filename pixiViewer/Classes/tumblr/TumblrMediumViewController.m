//
//  TumblrMediumViewController.m
//  pixiViewer
//
//  Created by nya on 10/01/25.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TumblrMediumViewController.h"
#import "ImageDiskCache.h"
#import "TumblrBigViewController.h"
#import "ProgressViewController.h"
#import "AccountManager.h"
#import "TumblrMatrixViewController.h"
#import "TumblrParser.h"
#import "Twitter.h"
#import "TumblrMatrixViewController2.h"
#import "TagCloud.h"
#import "Reachability.h"
#import "PixiViewerAppDelegate.h"
#import "AlwaysSplitViewController.h"
#import "ImageLoaderManager.h"


@implementation TumblrMediumViewController

@dynamic info;
@synthesize enableTagEdit;

- (void) dealloc {
	[newTags release];
	[super dealloc];
}

- (void) setInfo:(NSDictionary *)info {
	if (info != info_) {
		[info_ release];
		info_ = [info retain];
	}
}

- (NSDictionary *) info {
	return info_;
}

- (ImageCache *) cache {
	return [ImageCache tumblrMediumCache];
}

- (PixService *) pixiv {
	return [Tumblr instance];
}

- (NSString *) referer {
	return nil;
}

- (ImageLoaderManager *) imageLoaderManager {
	ImageLoaderManager *loader = [ImageLoaderManager loaderWithType:ImageLoaderType_Tumblr];
	return loader;
}

- (NSString *) serviceName {
	return @"Tumblr";
}

- (void)viewDidLoad {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadNotify:) name:@"TumblrInfoUpdated" object:nil];
	
	[super viewDidLoad];
}

- (void)viewDidUnload {
	[super viewDidUnload];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (long) reload {
	if ([[Reachability reachabilityForInternetConnection] currentReachabilityStatus] == 0) {
		return 2;
	}
	if ([Tumblr instance].logined == NO) {
		return -1;
	}
	/*
		[Tumblr instance].username = account.username;
		[Tumblr instance].password = account.password;
	
		long err = [[Tumblr instance] login:self];
		if (err) {
			UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"ログインに失敗しました。" message:@"" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil] autorelease];
			[alert show];
			return err;
		} else {
			[self showProgress:YES withTitle:@"ログイン中..." tag:1000];
		}
		return 0;
	}
	 */
	
	UIScrollView *scrollView = (UIScrollView *)self.tableView;
	scrollView.contentSize = self.view.frame.size;
	[scrollView scrollsToTop];
	
	/*
	if ([self.view viewWithTag:1234] == nil) {
		UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
		CGRect r = activity.frame;
		r.origin.x = (self.view.frame.size.width - r.size.width) / 2.0;
		r.origin.y = (390 - r.size.height) / 2.0;
		activity.frame = r;
		activity.tag = 1234;
		activity.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
		[self.view addSubview:activity];
		[activity startAnimating];
		[activity release];
	}
	*/
	
	NSDictionary	*info = info_;
	if ([info objectForKey:@"MediumURLString"]) {
		//[self update:info];
		[self performSelector:@selector(update:) withObject:info afterDelay:0.1];
	} else {
		NSString *str;
		NSArray *comp = [self.illustID componentsSeparatedByString:@"_"];
		if ([comp count] == 2) {
			str = [NSString stringWithFormat:@"http://%@.tumblr.com/api/read?id=%@", [comp objectAtIndex:0], [comp objectAtIndex:1]];
		} else {
			str = [NSString stringWithFormat:@"http://%@.tumblr.com/api/read?id=%@", [Tumblr instance].name, self.illustID];
		}

		TumblrParser		*parser = [[TumblrParser alloc] initWithEncoding:NSUTF8StringEncoding];
		CHHtmlParserConnection	*con = [[CHHtmlParserConnection alloc] initWithURL:[NSURL URLWithString:str]];
	
		con.referer = [self referer];
		con.delegate = self;
		parser_ = parser;
		connection_ = con;
	
		[con startWithParser:parser];
	}
	return 0;
}

- (long) reloadNotify:(NSNotification *)notif {
	NSDictionary *uinfo = [notif userInfo];
	if ([[uinfo objectForKey:@"IllustID"] isEqualToString:self.illustID]) {
		[self update:uinfo];
	}
	[self updateSegment];
	return 0;
}

/*
- (void) next {
	[connection_ cancel];
	connection_ = nil;
	[parser_ release];
	parser_ = nil;
	
	[info_ release];
	info_ = nil;
	[self updateToolbar];
	
	for (UIView *v in [self.view subviews]) {
		[v removeFromSuperview];
	}
	// content size
	[(UIScrollView *)self.tableView setContentSize:self.view.frame.size];
	
	//[imageButton clear];
	//commentLabel.text = @"Loading...";
	
	self.info = [[self parentMatrix] nextInfo:self.illustID];
	self.illustID = [self nextIID];
	[self reload];
	[self updateSegment];
}

- (void) prev {
	[connection_ cancel];
	connection_ = nil;
	[parser_ release];
	parser_ = nil;

	[info_ release];
	info_ = nil;
	[self updateToolbar];
	
	for (UIView *v in [self.view subviews]) {
		[v removeFromSuperview];
	}
	// content size
	[(UIScrollView *)self.view setContentSize:self.view.frame.size];
	
	//[imageButton clear];
	//commentLabel.text = @"Loading...";
	
	self.info = [[self parentMatrix] prevInfo:self.illustID];
	self.illustID = [self prevIID];
	[self reload];
	[self updateSegment];
}
*/

- (void) imageButtonAction:(id)obj {
	TumblrBigViewController *controller = nil;
	controller = [[TumblrBigViewController alloc] initWithNibName:@"PixivBigViewController" bundle:nil];
	controller.illustID = self.illustID;
	controller.info = self.info;
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		PixiViewerAppDelegate *app = (PixiViewerAppDelegate *)[UIApplication sharedApplication].delegate;
		[app pushViewController:controller animated:YES];
	} else {
		[self.navigationController pushViewController:controller animated:YES];
	}
	[controller release];
}

- (IBAction) reblog {
}

- (void) add:(UIActionSheet *)sheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	UIAlertView	*alert = nil;
	long		err;

	// 追加
	NSMutableDictionary	*mdic = [[info_ mutableCopy] autorelease];
	if (buttonIndex == 0) {
		// コレクション
		[mdic setObject:[NSNumber numberWithBool:YES] forKey:@"IsOpen"];
		[mdic setObject:@"illust" forKey:@"Type"];
			
		err = [[self pixiv] addToBookmark:self.illustID withInfo:mdic handler:self];
		if (err) {
			alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Add to collection failed.", @"") message:@"" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];				
		}
	} else if (buttonIndex == 1) {
		// フォロー
		[mdic setObject:[NSNumber numberWithBool:NO] forKey:@"IsOpen"];
		[mdic setObject:@"user" forKey:@"Type"];

		err = [[self pixiv] addToBookmark:[info_ objectForKey:@"UserID"] withInfo:mdic handler:self];
		if (err) {
			alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Add to follow failed.", @"") message:@"" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];				
		}
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

	if (enableTagEdit) {
		UIActionSheet	*alert;
		alert = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:@"このPostを削除", NSLocalizedString(@"Go to the web of this illust", nil), @"Twitterへポスト", nil];
		alert.tag = 200;
		if (([[UIDevice currentDevice] respondsToSelector:@selector(userInterfaceIdiom)] ? [[UIDevice currentDevice] userInterfaceIdiom] : 0) != 0) {
			[alert showFromBarButtonItem:sender animated:YES];
		} else {
			[alert showFromToolbar:self.navigationController.toolbar];
		}
		actionSheet_ = alert;
		[alert release];
	} else {
		UIActionSheet	*alert;
		alert = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:/*@"ユーザーのPostを表示", */NSLocalizedString(@"Go to the web of this illust", nil), @"Twitterへポスト", nil];
		alert.tag = 200;
		if (([[UIDevice currentDevice] respondsToSelector:@selector(userInterfaceIdiom)] ? [[UIDevice currentDevice] userInterfaceIdiom] : 0) != 0) {
			[alert showFromBarButtonItem:sender animated:YES];
		} else {
			[alert showFromToolbar:self.navigationController.toolbar];
		}
		actionSheet_ = alert;
		[alert release];
	}
}

- (IBAction) tumblr:(id)sender {
	if (actionSheet_) [actionSheet_ dismissWithClickedButtonIndex:[actionSheet_ cancelButtonIndex] animated:NO];

	UIActionSheet	*alert;
	if (1 || [[self.navigationController.viewControllers objectAtIndex:[self.navigationController.viewControllers count] - 2] isKindOfClass:[TumblrMatrixViewController class]]) {
		alert = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Reblog", nil)/*, NSLocalizedString(@"Reblog(Private)", nil)*/, [[info_ objectForKey:@"Liked"] isEqual:@"true"] ? @"Unlike" : NSLocalizedString(@"Like", nil), nil];
	} else {
		alert = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Like", nil), nil];
	}
	alert.tag = 100;
	if (([[UIDevice currentDevice] respondsToSelector:@selector(userInterfaceIdiom)] ? [[UIDevice currentDevice] userInterfaceIdiom] : 0) != 0) {
		[alert showFromBarButtonItem:sender animated:YES];
	} else {
		[alert showFromToolbar:self.navigationController.toolbar];
	}
	actionSheet_ = alert;
	[alert release];
}

- (IBAction) goToWeb {	
	//[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.pixa.cc/illustrations/show/%@", self.illustID]]];
}

- (NSString *)url {
	if ([info_ objectForKey:@"url"]) {
		return [info_ objectForKey:@"url"];
	} else if ([info_ objectForKey:@"ShortenURL"]) {
		return [info_ objectForKey:@"ShortenURL"];
	} else {
		return nil;
	}
}

- (NSString *) twitterDefaultString:(NSString *)url {
	NSString *str;
	if ([[NSUserDefaults standardUserDefaults] objectForKey:@"TumblrFormat"]) {
		str = [[NSUserDefaults standardUserDefaults] stringForKey:@"TumblrFormat"];
	} else {
		str = NSLocalizedString(@"Tumblr format", nil);
	}
	
	if ([str rangeOfString:@"%service"].location != NSNotFound) {
		str = [str stringByReplacingOccurrencesOfString:@"%service" withString:[self serviceName]];
	}
	if ([str rangeOfString:@"%url"].location != NSNotFound) {
		str = [str stringByReplacingOccurrencesOfString:@"%url" withString:url];
	}
	
	return str;
}

- (void) twitter {
	if ([Twitter sharedInstance].available == NO) {
		UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"Twitterアカウントの設定がありません" message:@"TOPの「設定」から認証してください。" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil] autorelease];
		[alert show];
		return;
	}
	
	NSString *url = [info_ objectForKey:@"ShortenURL"];
	if (url == nil) {
		url = shorten([self url]);
	}
	if (url == nil) {
		url = [self url];
	}

	PixivTagAddViewController *controller = [[PixivTagAddViewController alloc] initWithNibName:@"PixivTagAddViewController" bundle:nil];
	controller.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
	controller.delegate = self;
	controller.type = @"Twitter";
	controller.titleString = @"Twitter";
	controller.defaultString = [self twitterDefaultString:url];
	controller.maxCount = 140;
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) controller.modalPresentationStyle = UIModalPresentationFormSheet;
	[self presentModalViewController:controller animated:YES];
	[controller release];
}

- (NSString *) tagDefaultKey {
	return [NSString stringWithFormat:@"TumblrSavedTags_%@", self.account.username];
}

- (void) saveTags:(NSArray *)tags {
	[[NSUserDefaults standardUserDefaults] setObject:tags forKey:[self tagDefaultKey]];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSArray *) tags {
	return [[NSUserDefaults standardUserDefaults] objectForKey:[self tagDefaultKey]];
}

- (void) addTag:(NSString *)str {
	NSMutableArray *ary = [NSMutableArray arrayWithArray:[self tags]];
	if ([ary containsObject:str]) {
		[ary removeObject:str];
	}
	[ary insertObject:str atIndex:0];
	[self saveTags:ary];
}

- (void)actionSheet:(UIActionSheet *)sheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	actionSheet_ = nil;
	
	if (sheet.tag == 200 && buttonIndex != sheet.cancelButtonIndex) {
		buttonIndex -= (enableTagEdit ? 1 : 0);
	
		if (0 && buttonIndex == 0) {
			TumblrMatrixViewController2 *vc = [[[TumblrMatrixViewController2 alloc] init] autorelease];
			vc.title = [info_ objectForKey:@"tumblelog"];
			vc.method = @"read?";
			vc.name = [info_ objectForKey:@"tumblelog"];
			vc.account = self.account;
			vc.needsAuth = NO;
			if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
				PixiViewerAppDelegate *app = (PixiViewerAppDelegate *)[UIApplication sharedApplication].delegate;
				[(UINavigationController *)app.alwaysSplitViewController.rootViewController pushViewController:vc animated:![app.alwaysSplitViewController rootIsHidden]];
				[app.alwaysSplitViewController setRootHidden:NO animated:YES];
			} else {
				[self.navigationController pushViewController:vc animated:YES];
			}
		} else if (buttonIndex == -1) {
			[[Tumblr instance] deletePost:[info_ objectForKey:@"PostID"] handler:self];
			[self showProgress:YES withTitle:nil tag:4000];
		} else if (buttonIndex == 0) {
			if ([info_ objectForKey:@"url"]) {
				[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[info_ objectForKey:@"url"]]];
			} else if ([info_ objectForKey:@"ShortenURL"]) {
				[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[info_ objectForKey:@"ShortenURL"]]];
			}
		} else if (buttonIndex == 1) {
			[self twitter];
		}
	} else if (sheet.tag == 100) {
		NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:info_];
		[dic setObject:account.username forKey:@"email"];
		[dic setObject:account.password forKey:@"password"];
	
		if (1 || [[self.navigationController.viewControllers objectAtIndex:[self.navigationController.viewControllers count] - 2] isKindOfClass:[TumblrMatrixViewController class]]) {
			if (buttonIndex == 0/* || buttonIndex == 1*/) {
				if (buttonIndex == 1) {
					[dic setObject:[NSNumber numberWithBool:YES] forKey:@"Private"];
				}
			
                [[Tumblr instance] reblogInBackground:dic];
			} else if (buttonIndex == 1) {
				if ([[info_ objectForKey:@"Liked"] isEqual:@"true"]) {
					[dic setObject:[NSNumber numberWithBool:YES] forKey:@"Unlike"];
				}
				[[Tumblr instance] likeAPI:dic handler:self];
				[self showProgress:YES withTitle:nil tag:400];
			}
		} else {
			if (buttonIndex == 0) {
				[[Tumblr instance] likeAPI:dic handler:self];
				[self showProgress:YES withTitle:nil tag:300];
			}
		}
	} else if (sheet.tag == 888) {
		NSString *tag = nil;
		NSScanner *scan = [NSScanner scannerWithString:sheet.title];
		
		[scan scanUpToString:@"「" intoString:nil];
		[scan scanString:@"「" intoString:nil];
		[scan scanUpToString:@"」" intoString:&tag];
		if (tag) {
			[self addTag:tag];
		}
	} else {
		[super actionSheet:sheet clickedButtonAtIndex:buttonIndex];
	}
}

- (UIBarButtonItem *) ratingButton {
	return nil;
}

- (BOOL) ratingEnabled {
	return NO;
}

- (BOOL) commentEnabled {
	return enableTagEdit;
}

- (NSString *) tumblrServiceName {
	return nil;
}

- (void) tumblr:(Tumblr *)sender reblogFinished:(long)err {
	[self hideProgress];
	
	UIAlertView *alert;
	if (err == 0) {	
		alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Tumblr reblog ok.", nil) message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
		
		// タグクラウド更新
		for (NSString *str in [info_ objectForKey:@"Tags"]) {
			[[TagCloud sharedInstance] add:str forType:@"Tumblr" user:self.account.username];
		}
	} else {
		alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Tumblr reblog failed.", nil) message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
	}
	[alert show];
	[alert release];
}

- (void) tumblr:(Tumblr *)sender likeFinished:(long)err {
	[self hideProgress];
	
	UIAlertView *alert;
	if (err == 0) {	
		if ([[info_ objectForKey:@"Liked"] isEqual:@"true"]) {
			alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Tumblr unlike ok.", nil) message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
			
			[(NSMutableDictionary *)info_ removeObjectForKey:@"Liked"];
		} else {
			alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Tumblr like ok.", nil) message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];

			[(NSMutableDictionary *)info_ setObject:@"true" forKey:@"Liked"];
		}
	} else {
		if ([[info_ objectForKey:@"Liked"] isEqual:@"true"]) {
			alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Tumblr unlike failed.", nil) message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
		} else {
			alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Tumblr like failed.", nil) message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
		}
	}
	[alert show];
	[alert release];
}

- (void) tumblr:(Tumblr *)sender deleteFinished:(long)err {
	[self hideProgress];
	
	if (err) {
		UIAlertView *alert;
		alert = [[UIAlertView alloc] initWithTitle:@"削除に失敗しました" message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
	
		[alert show];
		[alert release];
	} else {
		[[self parentMatrix] performSelector:@selector(removeContent:) withObject:info_];
		[self.navigationController popViewControllerAnimated:YES];
	}
}

- (void) progressCancel:(ProgressViewController *)sender {
	switch (sender.tag) {
	case 300:
		[[Tumblr instance] reblogCancel];
		break;
	case 400:
		[[Tumblr instance] likeCancel];
		break;
	case 3000:
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(retryEdit) object:nil];
		[[Tumblr instance] writePhotoCancel];
	case 4000:
		[[Tumblr instance] deletePostCancel];
		break;
	default:
		break;
	}
	
	[self hideProgress];
}

- (void) comment {
	TumblrTagEditViewController *controller = [[TumblrTagEditViewController alloc] initWithStyle:UITableViewStyleGrouped];
	controller.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
	controller.delegate = self;
	controller.tags = [info_ objectForKey:@"Tags"];
	controller.account = account;
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) controller.modalPresentationStyle = UIModalPresentationFormSheet;
	[self presentModalViewController:[[[UINavigationController alloc] initWithRootViewController:controller] autorelease] animated:YES];
	[controller release];
}

- (void) tagEditView:(TumblrTagEditViewController *)sender done:(BOOL)b {
	[self dismissModalViewControllerAnimated:YES];
	if (b) {
		NSMutableString *str = [NSMutableString string];
		for (NSString *name in sender.tags) {
			if ([name length] > 0) {
				[str appendFormat:@"%@", name];
			}
			if (name != [sender.tags lastObject]) {
				[str appendString:@","];
			}
		}
		
		NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:
			[info_ objectForKey:@"IllustID"],	@"PostID",
			str,								@"Tags",
			[info_ objectForKey:@"PhotoLink"],	@"URL",
			[info_ objectForKey:@"Caption"],	@"Caption",
			nil];
	
		[newTags release];
		newTags = [[str componentsSeparatedByString:@","] retain];
		
		[[Tumblr instance] writePhotoInBackground:nil withInfo:dic];
		//[[Tumblr instance] writePhoto:nil withInfo:dic handler:self];
		//[self showProgress:YES withTitle:nil tag:3000];
	}
}

- (void) retryEdit {
	NSMutableString *str = [NSMutableString string];
	for (NSString *name in newTags) {
		if ([name length] > 0) {
			[str appendFormat:@"%@", name];
		}
		if (name != [newTags lastObject]) {
			[str appendString:@","];
		}
	}
		
	NSDictionary *dic = [NSDictionary dictionaryWithObjectsAndKeys:
		[info_ objectForKey:@"IllustID"],	@"PostID",
		str,								@"Tags",
		[info_ objectForKey:@"PhotoLink"],	@"URL",
		[info_ objectForKey:@"Caption"],	@"Caption",
		nil];
	
	//[[Tumblr instance] writePhoto:nil withInfo:dic handler:self];
	[[Tumblr instance] writePhotoInBackground:nil withInfo:dic];
}

- (void) tumblr:(Tumblr *)sender writePhotoFinished:(long)err {	
	UIAlertView *alert = nil;
	if (err == 201) {	
		alert = [[UIAlertView alloc] initWithTitle:@"タグを編集しました。" message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
		
		// タグクラウド更新
		for (NSString *str in [info_ objectForKey:@"Tags"]) {
			[[TagCloud sharedInstance] remove:str forType:@"Tumblr" user:self.account.username];
		}
		for (NSString *str in newTags) {
			[[TagCloud sharedInstance] add:str forType:@"Tumblr" user:self.account.username];
		}
		
		NSMutableDictionary *dic = [info_ isKindOfClass:[NSMutableDictionary class]] ? (NSMutableDictionary *)info_ : [[info_ mutableCopy] autorelease];
		[dic setObject:newTags forKey:@"Tags"];
		[self updateInfo:dic];
		
		// キャッシュ更新
		//[[self pixiv] removeEntriesForIllustID:self.illustID];
		//[[self pixiv] addEntries:dic forIllustID:self.illustID];
		
		[newTags release];
		newTags = nil;

		[self hideProgress];
	} else {
		//alert = [[UIAlertView alloc] initWithTitle:@"タグの編集に失敗しました。" message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
		[self performSelector:@selector(retryEdit) withObject:nil afterDelay:0.5];
		return;
	}
	[alert show];
	[alert release];
}

- (void) tagButtonAction:(id)sender {
	NSString *tag = [(UIButton*)sender titleForState:UIControlStateNormal];
	TumblrMatrixViewController2 *vc = [[[TumblrMatrixViewController2 alloc] init] autorelease];
	vc.title = tag;
	vc.method = [NSString stringWithFormat:@"read?tagged=%@&", encodeURIComponent(tag)];
	vc.name = [Tumblr instance].name;
	vc.account = self.account;
	vc.needsAuth = YES;
	vc.account = account;
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		PixiViewerAppDelegate *app = (PixiViewerAppDelegate *)[UIApplication sharedApplication].delegate;
		[(UINavigationController *)app.alwaysSplitViewController.rootViewController pushViewController:vc animated:![app.alwaysSplitViewController rootIsHidden]];
		[app.alwaysSplitViewController setRootHidden:NO animated:YES];
	} else {
		[self.navigationController pushViewController:vc animated:YES];
	}
	
	/*
	UIActionSheet *action = [[[UIActionSheet alloc] initWithTitle:[NSString stringWithFormat:@"タグ「%@」を追加しますか？", [(UIButton*)sender titleForState:UIControlStateNormal]] delegate:self cancelButtonTitle:@"キャンセル" destructiveButtonTitle:nil otherButtonTitles:@"追加する", nil] autorelease];
	action.tag = 888;
	[action showFromToolbar:self.navigationController.toolbar];
	*/
}

- (IBAction) showUserIllust {
	if ([info_ objectForKey:@"User"] == nil) {
		return;
	}
	
	TumblrMatrixViewController2 *controller = [[TumblrMatrixViewController2 alloc] init];
	controller.title = [NSString stringWithFormat:@"%@.tumblr.com", [info_ objectForKey:@"User"]];
	controller.method = @"read?";
	controller.name = [info_ objectForKey:@"User"];
	controller.account = self.account;
	controller.needsAuth = NO;

	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		PixiViewerAppDelegate *app = (PixiViewerAppDelegate *)[UIApplication sharedApplication].delegate;
		[(UINavigationController *)app.alwaysSplitViewController.rootViewController pushViewController:controller animated:![app.alwaysSplitViewController rootIsHidden]];
		[app.alwaysSplitViewController setRootHidden:NO animated:YES];
	} else {
		[self.navigationController pushViewController:controller animated:YES];
	}
	[controller release];
}

#pragma mark-

- (BOOL) needsStore {
	return self.info != nil;
}

- (NSMutableDictionary *) storeInfo {
	NSMutableDictionary *info = [super storeInfo];
	
	[info setObject:self.info forKey:@"ContentInfo"];
	
	return info;
}

- (BOOL) restore:(NSDictionary *)info {
	if ([super restore:info] == NO) {
		return NO;
	}

	self.info = [info objectForKey:@"ContentInfo"];

	return YES;
}

- (NSString *) parserClassName {
	return @"TumblrParser";
}

- (NSString *) sourceURL {
	return [info_ objectForKey:@"BigURLString"];
}

- (NSArray *) saveImageURLs {
	id obj = [info_ objectForKey:@"BigURLString"];
	if (obj) {
		return [NSArray arrayWithObject:obj];
	} else {
		return nil;
	}
}

@end
