//
//  PixivMediumViewController.m
//  pixiViewer
//
//  Created by nya on 09/08/19.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PixivMediumViewController.h"
#import "PixivBigViewController.h"
#import "PixivMangaViewController.h"
#import "PixivMatrixViewController.h"
#import "PixivSlideshowViewController.h"
#import "Pixiv.h"
#import "PixivMediumParser.h"
#import "ImageDiskCache.h"
#import "ProgressViewController.h"
#import "AccountManager.h"
#import "Pixa.h"
#import "PixaMediumViewController.h"
#import "TinamiMediumViewController.h"
#import "Tinami.h"
#import "Reachability.h"
#import "TagCloud.h"
#import "MediumViewCell.h"
#import "PixiViewerAppDelegate.h"
#import "AlwaysSplitViewController.h"
#import "UserDefaults.h"
#import "DropBoxTail.h"
#import "EvernoteTail.h"
#import "CameraRoll.h"
#import "MediumImageCell.h"
#import "ImageLoaderManager.h"
#import "SharedAlertView.h"
#import "CHHtmlParserConnectionNoScript.h"
#import "PixitailConstants.h"
#import <Twitter/Twitter.h>
#import "SugarSync.h"
#import "GoogleDrive.h"
#import "SkyDrive.h"
#import "TumblrAccountManager.h"
#import "WebViewController.h"
#import "RegexKitLite.h"
#import "PixivUgoIllust.h"
#import "CHTumbletailActivity.h"


static UIImage *whiteDisclosureIndicatorImage();


@interface PixivMediumViewController()
@property(strong) PixivUgoIllust *ugoIllust;
@property(strong) PixivUgoIllustPlayer *ugoIllustPlayer;
@end


@implementation PixivMediumViewController

@synthesize illustID, account;
@synthesize info = info_;
@synthesize tableView = tableView_;
@synthesize scrollView = scrollView_;

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/

- (BOOL) ratingEnabled {
	return YES;
}

- (BOOL) commentEnabled {
	return YES;
}

- (ImageCache *) smallCache {
	return [[self parentMatrix] cache];
}

//- (ImageCache *) matrixViewGetCache:(CHMatrixView *)view {
//	return [self cache];
//}

- (Pixiv *) pixiv {
	return [Pixiv sharedInstance];
}

- (NSDictionary *) infoForIllustID:(NSString *)iid {
	return [[self pixiv] infoForIllustID:iid];
}

- (PixivMatrixViewController *) parentMatrix {
	PixivMatrixViewController *prev;
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		PixiViewerAppDelegate *app = (PixiViewerAppDelegate *)[UIApplication sharedApplication].delegate;
		prev = (PixivMatrixViewController *)((UINavigationController *)app.alwaysSplitViewController.rootViewController).visibleViewController;
	} else {
		prev  = ((PixivMatrixViewController *)[self.navigationController.viewControllers objectAtIndex:[self.navigationController.viewControllers indexOfObject:self] - 1]);
	}
	
	if ([prev isKindOfClass:[PixivMatrixViewController class]]) {
		return prev;
	} else {
		return nil;
	}
}

- (BOOL) isInUserBookmark {
	return [[self parentMatrix].method hasPrefix:@"bookmark.php?id="];
}

- (BOOL) isInBookmark {
	return (![self isInUserBookmark]) && [[self parentMatrix].method hasPrefix:@"bookmark.php"];
}

- (BOOL) isInUser {
	return [[self parentMatrix].method hasPrefix:@"member_illust.php"];
}

- (NSString *) nextIID {
	return [[self parentMatrix] nextIID:self.illustID];
}

- (NSString *) prevIID {
	return [[self parentMatrix] prevIID:self.illustID];
}

- (NSDictionary *) nextInfo {
	return [[self parentMatrix] nextInfo:self.illustID];
}

- (NSDictionary *) prevInfo {
	return [[self parentMatrix] prevInfo:self.illustID];
}

- (NSString *) referer {
	return @"http://www.pixiv.net/";
}

- (ImageLoaderManager *) imageLoaderManager {
	ImageLoaderManager *loader = [ImageLoaderManager loaderWithType:ImageLoaderType_PixivMedium];
	loader.referer = [self referer];
	return loader;
}

- (void) updateNavigationBar {
	if (progressShowing_) {
		[self.navigationItem setHidesBackButton:YES animated:YES];
	} else {
		[self.navigationItem setHidesBackButton:NO animated:YES];
	}
	
	[self updateSegment];
}

- (UIBarButtonItem *) composeButton {
	for (UIBarButtonItem *item in self.toolbarItems) {
        if ([item action] == @selector(composeAction:)) {
            return item;
        }
    }
    return nil;
}

- (void) updateToolbar {
	for (UIBarButtonItem *item in self.toolbarItems) {
		if (progressShowing_) {
			item.enabled = NO;
		} else {
			if ([item action] == @selector(rating)) {
				item.enabled = (info_ && [[info_ objectForKey:@"RatingEnable"] boolValue]);
			} else if ([item action] == @selector(comment)) {
				item.enabled = (self.account.anonymous == NO);
			} else if ([item action] == @selector(composeAction:)) {
				item.enabled = (self.account.anonymous == NO);
			} else if ([item action] == @selector(saveAction:)) {
				item.enabled = (info_ != nil && ![[info_ objectForKey:@"ContentType"] isEqual:@"novel"]);
            } else if ([item action] == @selector(prev)) {
                item.enabled = !progressShowing_ && ([self prevIID] != nil);
            } else if ([item action] == @selector(next)) {
                item.enabled = !progressShowing_ && ([self nextIID] != nil);
			} else if ([item action] == @selector(saveAction:)) {
				item.enabled = ((self.ugoIllust.isLoaded || [[self imageLoaderManager] imageIsLoadedForID:self.illustID]) && info_ && ![[info_ objectForKey:@"ContentType"] isEqual:@"novel"]);
			} else {
				item.enabled = YES;
			}
		}
	}
}

- (void) updateTableRows {
	NSMutableArray *mary = [NSMutableArray array];
	NSMutableArray *rows;
	
	rows = [NSMutableArray array];
	[rows addObject:@"Image"];
	[mary addObject:rows];
	
	if (!connection_) {
		rows = [NSMutableArray array];
		if ([info_ objectForKey:@"PhotoType"]) {
			[rows addObject:@"PhotoType"];
		}
		if ([info_ objectForKey:@"Title"]) {
			[rows addObject:@"Title"];
		}
		if ([[info_ objectForKey:@"Images"] count] > 1) {
			[rows addObject:@"PageCount"];
		}
		if ([info_ objectForKey:@"UserName"]) {
			[rows addObject:@"UserName"];
		}
		if ([info_ objectForKey:@"Comment"]) {
			[rows addObject:@"Comment"];
		}
		if ([info_ objectForKey:@"DateString"]) {
			[rows addObject:@"DateString"];
		}
		if ([info_ objectForKey:@"RatingViewCount"]) {
			[rows addObject:@"RatingViewCount"];
		} else if ([info_ objectForKey:@"total_view"]) {
			[rows addObject:@"total_view"];
		}
		if ([info_ objectForKey:@"RatingCount"]) {
			[rows addObject:@"RatingCount"];
		} else if ([info_ objectForKey:@"user_view"]) {
			[rows addObject:@"user_view"];
		}
		if ([info_ objectForKey:@"RatingScore"]) {
			[rows addObject:@"RatingScore"];
		} else if ([info_ objectForKey:@"valuation"]) {
			[rows addObject:@"valuation"];
		}
		if ([info_ objectForKey:@"RatingString"]) {
			[rows addObject:@"RatingString"];
		}
		[mary addObject:rows];
		
		rows = [NSMutableArray array];
		for (int i = 0; i < [[info_ objectForKey:@"Tags"]count]; i++) {
			[rows addObject:@"Tags"];
		}
		[mary addObject:rows];
		
		rows = [NSMutableArray array];
		for (int i = 0; i < [[info_ objectForKey:@"OneComments"]count]; i++) {
			[rows addObject:@"OneComments"];
		}
		[mary addObject:rows];
	}
	
	[tableRows release];
	tableRows = [mary retain];
}

- (CGSize) size {
	return self.view.superview.frame.size;
}

- (void) hideProgress {
	[super hideProgress];
	
	[self updateToolbar];
	[self updateNavigationBar];
}

- (void) showProgress:(BOOL)activity withTitle:(NSString *)str tag:(int)tag {
	[super showProgress:activity withTitle:str tag:tag];
	
	[self updateToolbar];
	[self updateNavigationBar];
}

#pragma mark-

- (CGRect) imageFrame {
	CGRect r;
	r.origin = CGPointMake(0, 0);
	
	if (([[UIDevice currentDevice] respondsToSelector:@selector(userInterfaceIdiom)] ? [[UIDevice currentDevice] userInterfaceIdiom] : 0) != 0) {
		if (UIInterfaceOrientationIsLandscape(((PixiViewerAppDelegate *)[UIApplication sharedApplication].delegate).alwaysSplitViewController.interfaceOrientation)) {
			r.size.height = 661;
			r.size.width = 1024 - 320 - 1;
		} else {
			r.size.height = 917;
			r.size.width = 768 - 320 - 1;
		}
	} else {
		r.size.height = [UIScreen mainScreen].applicationFrame.size.height - (460 - 368);
		r.size.width = 320;
	}
	
	return r;
}

- (void) update:(NSDictionary *)info image:(BOOL)b {
	DLog(@"Medium update: %@", [info description]);

	// image view
	CGRect frame = [self imageFrame];//CGRectMake(20, 5.0, [UIScreen mainScreen].bounds.size.width - 20 * 2, 300);
	NSString *type = [info objectForKey:@"ContentType"];

	//[[self.view viewWithTag:1234] removeFromSuperview];
	if (([type isEqual:@"novel"] && ![info objectForKey:@"Pages"]) || (![type isEqual:@"novel"] && (![info objectForKey:@"MediumURLString"] && !info[@"UgoInfo"]))) {
		// 読めなかった
		[[SharedAlertView sharedInstance] showWithTitle:NSLocalizedString(@"Image load failed.", nil) message:@"" cancelButtonTitle:nil okButtonTitle:@"OK"];
		return;
	}

	if ([type isEqual:@"novel"]) {
		frame = CGRectMake(20, 5.0, [UIScreen mainScreen].bounds.size.width - 20 * 2, 100);
	}

	if (info_ != info) {
		[info_ release];
		info_ = [info retain];
	}
	
	if (!self.ugoIllust && self.info[@"UgoInfo"]) {
		self.ugoIllust = [[[PixivUgoIllust alloc] initWithInfo:self.info[@"UgoInfo"]] autorelease];
		self.ugoIllust.delegate = (id<PixivUgoIllustDelegate>)self;
	}
	
	[self updateTableRows];
	[(UITableView *)self.tableView reloadData];

	// rating
	[self ratingButton].enabled = ([[info objectForKey:@"RatingEnable"] boolValue]);

	[self updateToolbar];
	return;
}

- (void) updateHTML:(NSDictionary *)info {

}

- (void) update:(NSDictionary *)info {
	[self update:info image:YES];
}

- (void) updateInfo:(NSDictionary *)info {
	[self update:info image:NO];
}

#pragma mark-

- (void) connection:(CHHtmlParserConnectionNoScript *)con finished:(long)err {
	if (con == connection_) {
		[connection_ release];
		connection_ = nil;
		
		if (err) {
			UIAlertView	*alert = [[UIAlertView alloc] initWithTitle:@"読み込みに失敗しました" message:[NSString stringWithFormat:@"エラー: %ld", err] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];				
			[alert show];
			[alert release];
		} else {
			NSDictionary *info = [parser_ info];
			
			if ([con respondsToSelector:@selector(scripts)]) {
				NSString *regex = [[PixitailConstants sharedInstance] valueForKeyPath:@"constants.ugo_info_regex"];
				if (regex) {
					NSString *ugoString = nil;
					for (NSString *str in con.scripts) {
						NSArray *ary = [str captureComponentsMatchedByRegex:regex];
						if (ary.count > 0) {
							ugoString = ary.lastObject;
							break;
						}
					}
					if (ugoString) {
						id ugo = [NSJSONSerialization JSONObjectWithData:[ugoString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
						if (ugo) {
							NSMutableDictionary *mdic = [NSMutableDictionary dictionaryWithDictionary:info];
							[mdic setObject:ugo forKey:@"UgoInfo"];
							info = mdic;
						}
					}
				}
			}
			
			// キャッシュ
			[[self pixiv] addEntries:info forIllustID:self.illustID];
		
			[self update:info];
		}
		
		[parser_ release];
		parser_ = nil;
		
		[[NSNotificationCenter defaultCenter] postNotificationName:@"MediumViewControllerLoadedNotification" object:self];
	}
}

- (int) maxLengthOfComment {
	return 255;
}

- (void) comment {
	PixivTagAddViewController *controller = [[PixivTagAddViewController alloc] initWithNibName:@"PixivTagAddViewController" bundle:nil];
	controller.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
	controller.delegate = self;
	controller.type = @"Comment";
	controller.titleString = NSLocalizedString(@"Comment post", nil);
	controller.maxCount = [self maxLengthOfComment];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) controller.modalPresentationStyle = UIModalPresentationFormSheet;
	[self presentModalViewController:controller animated:YES];
	[controller release];
}

- (NSString *) twitterDefaultString:(NSString *)url {
	NSString *str;
	if ([[NSUserDefaults standardUserDefaults] objectForKey:@"TwitterFormat"]) {
		str = [[NSUserDefaults standardUserDefaults] stringForKey:@"TwitterFormat"];
	} else {
#ifdef PIXITAIL
		str = NSLocalizedString(@"Twitter format pixitail", nil);
#else
		str = NSLocalizedString(@"Twitter format", nil);
#endif
	}
	if ([NSStringFromClass([self class]) hasPrefix:@"Danbooru"]) {
		str = NSLocalizedString(@"Twitter format danbooru", nil);
	}
	
	NSString *replacement = [info_ objectForKey:@"Title"] ? [info_ objectForKey:@"Title"] : @"不明";
	if ([str rangeOfString:@"%title"].location != NSNotFound) {
		str = [str stringByReplacingOccurrencesOfString:@"%title" withString:replacement];
	}
	replacement = [info_ objectForKey:@"UserName"] ? [info_ objectForKey:@"UserName"] : @"不明";
	if ([str rangeOfString:@"%author"].location != NSNotFound) {
		str = [str stringByReplacingOccurrencesOfString:@"%author" withString:replacement];
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
	NSArray *activities = [NSArray arrayWithObjects:[[CHTumbletailActivityPhoto alloc] init], [[CHTumbletailActivityQuote alloc] init], [[CHTumbletailActivityLink alloc] init], nil];
	
	NSMutableArray *mary = [NSMutableArray array];
	
    /*
	UIImage *img = nil;
	if (![[info_ objectForKey:@"ContentType"] isEqual:@"novel"]) {
		if (self.ugoIllust) {
			if (self.ugoIllustPlayer) {
				img = self.ugoIllust.firstImage;
			}
		} else if ([[self imageLoaderManager] imageIsLoadedForID:self.illustID]) {
			img = [[self imageLoaderManager] imageForID:self.illustID];
		}
	}
	if (img) {
		[mary addObject:img];
	}
     */
    
	[mary addObject:[self twitterDefaultString:[self url]]];
	
	UIActivityViewController *vc = [[[UIActivityViewController alloc] initWithActivityItems:mary applicationActivities:activities] autorelease];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		dispatch_async(dispatch_get_main_queue(), ^{
			UIPopoverController *popoverController = [[[UIPopoverController alloc] initWithContentViewController:vc] autorelease];
			[popoverController presentPopoverFromBarButtonItem:[self actionButton] permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
		});
	} else {
		[self presentViewController:vc animated:YES completion:^{
		}];
	}
}

- (NSURL *) reportURL {
	if ([NSStringFromClass([self class]) isEqualToString:@"PixivMediumViewController"]) {
		return [NSURL URLWithString:[NSString stringWithFormat:@"http://www.pixiv.net/illust_infomsg.php?illust_id=%@", self.illustID]];
	} else {
		return nil;
	}
}

- (void) report {
	NSURL *url = [self reportURL];
	if (url) {
		WebViewController *vc = [[WebViewController alloc] initWithNibName:@"WebViewController" bundle:nil];
		vc.url = url;
		[self.navigationController pushViewController:vc animated:YES];
		[vc release];
	}
}

- (void) tagAddViewCancel:(PixivTagAddViewController *)sender {
	[self dismissModalViewControllerAnimated:YES];
}

- (void) tagAddView:(PixivTagAddViewController *)sender done:(NSDictionary *)tag {
	NSString *str = [tag objectForKey:@"Tag"];
	
	if ([str length] > 0 && [str length] <= [self maxLengthOfComment]) {
		[[self pixiv] comment:str withInfo:info_];
	
		[self dismissModalViewControllerAnimated:YES];
		//[self showProgress:YES withTitle:nil tag:100];
	} else {
		// エラー
		NSString *msg;
		if ([str length] == 0) {
			msg = NSLocalizedString(@"Comment length is zero.", nil);
		} else {
			msg = [NSString stringWithFormat:@"%d文字以内で入力してください。", [self maxLengthOfComment]];
		}
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:msg message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
		[alert show];
		[alert release];
	}
}

- (void) pixService:(PixService *)sender commentFinished:(long)err {
	NSString *msg;
	[self hideProgress];
	if (err == 0) {
		msg = NSLocalizedString(@"Comment post ok.", nil);
		
		[[self pixiv] removeEntriesForIllustID:self.illustID];
		[self reload];
	} else {
		msg = NSLocalizedString(@"Comment post failed.", nil);
	}
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:msg message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
	[alert show];
	[alert release];
}

- (void) rating:(id)sender {
	if (info_ && [info_ objectForKey:@"MyRate"] == nil) {
		PixivRatingViewController *controller = [[PixivRatingViewController alloc] initWithNibName:@"PixivRatingViewController" bundle:nil];
		controller.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
		controller.ratingDelegate = self;
		//controller.titleString = NSLocalizedString(@"Comment post", nil);
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) controller.modalPresentationStyle = UIModalPresentationFormSheet;
		[self presentModalViewController:controller animated:YES];
		[controller release];
	}
}

- (void) ratingViewCancel:(PixivRatingViewController *)sender {
	[self dismissModalViewControllerAnimated:YES];
}

- (void) ratingView:(PixivRatingViewController *)sender done:(NSInteger)rate {
	[[self pixiv] rating:rate withInfo:info_];
	
	[self dismissModalViewControllerAnimated:YES];
	//[self showProgress:YES withTitle:nil tag:200];
}

- (void) pixService:(PixService *)sender ratingFinished:(long)err {
	NSString *msg;
	[self hideProgress];
	if (err == 0) {
		msg = NSLocalizedString(@"Rating ok.", nil);
		
		[[self pixiv] removeEntriesForIllustID:self.illustID];
		[self reload];
	} else {
		msg = NSLocalizedString(@"Rating failed.", nil);
	}
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:msg message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
	[alert show];
	[alert release];
}

- (void) goToTop {
	[self.navigationController popToViewController:[self.navigationController.viewControllers objectAtIndex:1] animated:YES];
}

- (void) imageButtonAction:(id)obj {
	if (self.ugoIllust && !self.ugoIllust.isLoaded) {
		return;
	}
	
	PixivBigViewController *controller = nil;
	if ([[info_ objectForKey:@"IllustMode"] isEqualToString:@"manga"]) {
		// manga
		controller = (PixivBigViewController *)[[PixivMangaViewController alloc] init];
	} else {
		// big
		controller = [[PixivBigViewController alloc] initWithNibName:@"PixivBigViewController" bundle:nil];
	}
	controller.illustID = self.illustID;
	controller.ugoIllust = self.ugoIllust;
	//controller.account = account;
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		PixiViewerAppDelegate *app = (PixiViewerAppDelegate *)[UIApplication sharedApplication].delegate;
		[app pushViewController:controller animated:YES];
	} else {
		[self.navigationController pushViewController:controller animated:YES];
	}
	[controller release];
}

- (void) tagButtonAction:(id)sender {
	NSData				*data = [((UIButton *)sender).titleLabel.text dataUsingEncoding:NSUTF8StringEncoding];
	NSMutableString		*method = [NSMutableString stringWithString:@"tags.php?tag="];
	int					i;
	
	for (i = 0; i < [data length]; i++) {
		[method appendFormat:@"%%%02X", ((unsigned char *)[data bytes])[i]];
	}
	[method appendString:@"&"];
	
	PixivMatrixViewController *controller = [[PixivMatrixViewController alloc] init];
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

- (IBAction) showUserIllust {
	PixivMatrixViewController *controller = [[PixivMatrixViewController alloc] init];
	controller.method = [NSString stringWithFormat:@"member_illust.php?id=%@&", [info_ objectForKey:@"UserID"]];
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

- (IBAction) showUserBookmark {
	PixivMatrixViewController *controller = [[PixivMatrixViewController alloc] init];
	controller.method = [NSString stringWithFormat:@"bookmark.php?id=%@&", [info_ objectForKey:@"UserID"]];
	controller.navigationItem.title = [NSString stringWithFormat:NSLocalizedString(@"Bookmark by %@", nil), [info_ objectForKey:@"UserName"]];
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

- (IBAction) slideshow {
	PixivSlideshowViewController *controller = [[PixivSlideshowViewController alloc] initWithNibName:@"PixivSlideshowViewController" bundle:nil];
	controller.method = [self parentMatrix].method;
	controller.scrapingInfoKey = [self parentMatrix].scrapingInfoKey;
	controller.account = account;
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		PixiViewerAppDelegate *app = (PixiViewerAppDelegate *)[UIApplication sharedApplication].delegate;
		[app pushViewController:controller animated:YES];
	} else {
		[self.navigationController pushViewController:controller animated:YES];
	}
	[controller release];
}

- (IBAction) goToWeb {	
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.pixiv.net/member_illust.php?mode=medium&illust_id=%@", self.illustID]]];
}

- (IBAction) action:(id)sender {
	if (actionSheet_) [actionSheet_ dismissWithClickedButtonIndex:[actionSheet_ cancelButtonIndex] animated:NO];
	
	UIActionSheet	*alert;
    alert = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Go to bookmarks of this user", nil), NSLocalizedString(@"Go to the web of this illust", nil), @"共有...", @"通報", nil];
	alert.destructiveButtonIndex = 3;
	if (([[UIDevice currentDevice] respondsToSelector:@selector(userInterfaceIdiom)] ? [[UIDevice currentDevice] userInterfaceIdiom] : 0) != 0) {
		[alert showFromBarButtonItem:sender animated:YES];
	} else {
		[alert showFromToolbar:self.navigationController.toolbar];
	}
	actionSheet_ = alert;
	[alert release];
}  
    
- (void) saveAction:(id)sender {
	if (actionSheet_) [actionSheet_ dismissWithClickedButtonIndex:[actionSheet_ cancelButtonIndex] animated:NO];
	
	UIActionSheet	*alert;
    alert = [[UIActionSheet alloc] init];
    alert.delegate = self;
    alert.tag = 300;
    if ([TumblrAccountManager sharedInstance].currentAccount != nil) {
        // Tumblr
        [alert addButtonWithTitle:NSLocalizedString(@"Post to tumblr", nil)];
    }
    if ([[DropBoxTail sharedInstance] linked]) {
        [alert addButtonWithTitle:NSLocalizedString(@"Dropbox", nil)];
    }
    if (UDBoolWithDefault(@"SaveToEvernote", NO)) {
        [alert addButtonWithTitle:NSLocalizedString(@"Evernote", nil)];
    }
    if (UDBoolWithDefault(@"SaveToSugarSync", NO)) {
        [alert addButtonWithTitle:NSLocalizedString(@"SugarSync", nil)];
    }
    if ([GoogleDrive sharedInstance].available) {
        [alert addButtonWithTitle:NSLocalizedString(@"Googleドライブ", nil)];
    }
    if (UDBoolWithDefault(@"SaveToSkyDrive", NO)) {
        [alert addButtonWithTitle:NSLocalizedString(@"SkyDrive", nil)];
    }
    [alert addButtonWithTitle:@"カメラロール"];
    [alert addButtonWithTitle:@"その他"];
    [alert addButtonWithTitle:@"キャンセル"];
    [alert setCancelButtonIndex:alert.numberOfButtons - 1];
    
	if (([[UIDevice currentDevice] respondsToSelector:@selector(userInterfaceIdiom)] ? [[UIDevice currentDevice] userInterfaceIdiom] : 0) != 0) {
		[alert showFromBarButtonItem:sender animated:YES];
	} else {
		[alert showFromToolbar:self.navigationController.toolbar];
	}
	actionSheet_ = alert;
	[alert release];
}

- (NSString *) ratingTitle {
	if ([[self pixiv] isRating:self.illustID]) {
		return nil;
	} else {
		return @"評価";
	}
}

- (void) composeAction:(id)sender {
	if (actionSheet_) [actionSheet_ dismissWithClickedButtonIndex:[actionSheet_ cancelButtonIndex] animated:NO];
	
	UIActionSheet	*alert;
    alert = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:@"コメント", [self ratingTitle], nil];
    alert.delegate = self;
    alert.tag = 200;
	if (([[UIDevice currentDevice] respondsToSelector:@selector(userInterfaceIdiom)] ? [[UIDevice currentDevice] userInterfaceIdiom] : 0) != 0) {
		[alert showFromBarButtonItem:sender animated:YES];
	} else {
		[alert showFromToolbar:self.navigationController.toolbar];
	}
	actionSheet_ = alert;
	[alert release];
    
}

- (IBAction) tumblr:(id)sender {
	if (actionSheet_) [actionSheet_ dismissWithClickedButtonIndex:[actionSheet_ cancelButtonIndex] animated:NO];

	UIActionSheet	*alert = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Post to tumblr", nil), NSLocalizedString(@"Post to tumblr(Private)", nil), nil];
	alert.tag = 100;
	if (([[UIDevice currentDevice] respondsToSelector:@selector(userInterfaceIdiom)] ? [[UIDevice currentDevice] userInterfaceIdiom] : 0) != 0) {
		[alert showFromBarButtonItem:sender animated:YES];
	} else {
		[alert showFromToolbar:self.navigationController.toolbar];
	}
	actionSheet_ = alert;
	[alert release];
}

- (UIBarButtonItem *) actionButton {
	for (UIBarButtonItem *btn in self.toolbarItems) {
		if (btn.action == @selector(action:)) {
			return btn;
		}
	}
	return nil;
}

- (UIBarButtonItem *) ratingButton {
	for (UIBarButtonItem *btn in self.toolbarItems) {
		if (btn.action == @selector(rating:)) {
			return btn;
		}
	}
	return nil;
}

- (UIBarButtonItem *) tumblrButton {
	for (UIBarButtonItem *btn in self.toolbarItems) {
		if (btn.action == @selector(tumblr:)) {
			return btn;
		}
	}
	return nil;
/*
	int index = 6;
	if ([self ratingEnabled] == NO) {
		index -= 2;
	}
	if ([self commentEnabled] == NO) {
		index -= 2;
	}
	return [self.toolbarItems objectAtIndex:index];
*/
}

- (PixivMediumParser *) parser {
	return [[[PixivMediumParser alloc] initWithEncoding:NSUTF8StringEncoding] autorelease];
}

- (CHHtmlParserConnection *) connection {
	NSString *fmt = [[PixitailConstants sharedInstance] valueForKeyPath:@"urls.medium"];
	if (!fmt) {
		fmt = @"http://www.pixiv.net/member_illust.php?mode=medium&illust_id=%@";
	}
	//[[NSURLConnection sendSynchronousRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:[[PixitailConstants sharedInstance] valueForKeyPath:@"urls.medium"], self.illustID]]] returningResponse:nil error:nil] writeToFile:[NSHomeDirectory() stringByAppendingPathComponent:@"medium.html"] atomically:YES];
	return [[[CHHtmlParserConnectionNoScript alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:fmt, self.illustID]]] autorelease];
}

- (long) reload {
	if (connection_) {
		return 0;
	}

	long	err = [[self pixiv] allertReachability];
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
		return err;
	} else if (err) {
		return err;
	}
	 */
	
	UIScrollView *scrollView = (UIScrollView *)self.tableView;
	scrollView.contentSize = [self size];
	[scrollView scrollsToTop];
	
	/*
	if ([self.view viewWithTag:1234] == nil) {
		UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
		CGRect r = activity.frame;
		r.origin.x = ([self size].width - r.size.width) / 2.0;
		r.origin.y = (390 - r.size.height) / 2.0;
		activity.frame = r;
		activity.tag = 1234;
		activity.hidesWhenStopped = YES;
		activity.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
		[self.view addSubview:activity];
		if (r.origin.x > 0) {
			[activity startAnimating];
		} else {
			[activity stopAnimating];
		}
		[activity release];
	}
	*/
	
	[self ratingButton].enabled = NO;

	NSDictionary	*info = [self infoForIllustID:self.illustID];
	if ([info objectForKey:@"MediumURLString"]) {
		//[self update:info];
		[self performSelector:@selector(update:) withObject:info afterDelay:0.1];
	} else {
		PixivMediumParser		*parser = [[self parser] retain];
		CHHtmlParserConnection	*con = [[self connection] retain];
	
		[connection_ cancel];
		connection_ = nil;
		[parser_ release];
		parser_ = nil;

		con.referer = [self referer];
		con.delegate = self;
		parser_ = parser;
		connection_ = con;
	
		[con startWithParser:parser];
	}
	
	[self updateTableRows];
	[self.tableView reloadData];
	return 0;
}

- (void) updateSegment {
}

- (void) baseScrollView:(UIScrollView **)sview andTableView:(UITableView **)tview {
	CGRect r = self.view.frame;
	r.origin = CGPointZero;
	
	UIScrollView *scrollView = [[[UIScrollView alloc] initWithFrame:r] autorelease];
	scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	scrollView.delegate = self;
	scrollView.alwaysBounceHorizontal = YES;
	scrollView.alwaysBounceVertical = NO;
	scrollView.backgroundColor = [UIColor blackColor];
	
	UITableView *tableView = [[[UITableView alloc] initWithFrame:r style:UITableViewStylePlain] autorelease];
	tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	tableView.delegate = self;
	tableView.dataSource = self;
	//tableView.contentInset = UIEdgeInsetsMake(self.navigationController.navigationBar.frame.size.height, 0, self.navigationController.toolbar.frame.size.height, 0);
	tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg.png"]];
	tableView.separatorColor = [UIColor darkGrayColor];	
	tableView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
	[scrollView addSubview:tableView];
	
	if ([UIDevice currentDevice].systemVersion.floatValue < 7.0) {
		tableView.contentInset = UIEdgeInsetsMake(44, 0, 44, 0);
	}
	
	*sview = scrollView;
	*tview = tableView;
}

- (void) next {
	[connection_ cancel];
	connection_ = nil;
	[parser_ release];
	parser_ = nil;
	
	[info_ release];
	info_ = nil;
		
	UITableView *tview;
	UIScrollView *sview;
	[self baseScrollView:&sview andTableView:&tview];

	CGRect r = self.scrollView.frame;
	r.origin.x = r.size.width;
	sview.frame = r;
	
	[self.view addSubview:sview];
	
	UIScrollView *removableScrollView = self.scrollView;
	
	[[UIApplication sharedApplication] beginIgnoringInteractionEvents];
	[UIView animateWithDuration:0.3 animations:^{
		CGRect r = self.scrollView.frame;
		sview.frame = r;
		
		r.origin.x -= r.size.width;
		self.scrollView.frame = r;
	} completion:^(BOOL finished) {	
		[removableScrollView removeFromSuperview];
		
		[[UIApplication sharedApplication] endIgnoringInteractionEvents];
	}];	

	self.scrollView = sview;
	self.tableView = tview;

	[self.ugoIllustPlayer stop];
	self.ugoIllust = nil;
	self.ugoIllustPlayer = nil;
	self.info = [self nextInfo];
	self.illustID = [self nextIID];
	[self updateTableRows];
	[self.tableView reloadData];
	
	[self reload];
	[self updateSegment];
	[self updateToolbar];
}

- (void) prev {
	[connection_ cancel];
	connection_ = nil;
	[parser_ release];
	parser_ = nil;

	[info_ release];
	info_ = nil;
	
	UITableView *tview;
	UIScrollView *sview;
	[self baseScrollView:&sview andTableView:&tview];
	
	CGRect r = self.scrollView.frame;
	r.origin.x = -r.size.width;
	sview.frame = r;
	
	[self.view addSubview:sview];

	UIScrollView *removableScrollView = self.scrollView;

	[[UIApplication sharedApplication] beginIgnoringInteractionEvents];
	[UIView animateWithDuration:0.3 animations:^{
		CGRect r = self.scrollView.frame;
		sview.frame = r;
		
		r.origin.x += r.size.width;
		self.scrollView.frame = r;
	} completion:^(BOOL finished) {		
		[removableScrollView removeFromSuperview];
		[[UIApplication sharedApplication] endIgnoringInteractionEvents];
	}];	
	
	self.scrollView = sview;
	self.tableView = tview;
	
	[self.ugoIllustPlayer stop];
	self.ugoIllust = nil;
	self.ugoIllustPlayer = nil;
	self.info = [self prevInfo];
	self.illustID = [self prevIID];
	[self reload];
	[self updateSegment];
	[self updateToolbar];
}

- (IBAction ) segmentAction:(id)sender {
	UISegmentedControl	*seg = sender;
	if (seg.selectedSegmentIndex == 0 && [self prevIID]) {
		// up
		[self prev];
	} else if ([self nextIID]) {
		//
		[self next];
	}
}

#pragma mark-

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) {
		self.edgesForExtendedLayout = UIRectEdgeNone;
	}
	
	UITableView *tview;
	UIScrollView *sview;
	[self baseScrollView:&sview andTableView:&tview];
	self.scrollView = sview;
	self.tableView = tview;
	[self.view addSubview:self.scrollView];
	
	if ([UIDevice currentDevice].systemVersion.floatValue < 7.0) {
		self.tableView.contentInset = UIEdgeInsetsMake(44, 0, 44, 0);
	}
	
	whiteIndicator = [whiteDisclosureIndicatorImage() retain];

	//self.wantsFullScreenLayout = YES;
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:NO];
	self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
	self.navigationController.toolbar.barStyle = UIBarStyleBlackTranslucent;
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(imageLoaded:) name:@"ImageLoaderManagerFinishedNotification" object:[self imageLoaderManager]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(imageLoadProgress:) name:@"ImageLoaderManagerProgressNotification" object:[self imageLoaderManager]];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(bookmarkFinished:) name:@"PixServiceBookmarkFinishedNotification" object:[self pixiv]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(ratingFinished:) name:@"PixServiceRatingFinishedNotification" object:[self pixiv]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(commentFinished:) name:@"PixServiceCommentFinishedNotification" object:[self pixiv]];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginFinished:) name:@"LoginFinishedNotification" object:nil];
}

- (void) loginFinished:(NSNotification *)notif {
	[self reload];
}

- (void) imageLoaded:(NSNotification *)notif {
	NSString *ID = [[notif userInfo] objectForKey:@"ID"];
	if ([ID isEqualToString:self.illustID]) {
		if ([[notif userInfo] objectForKey:@"Error"]) {
			// エラー
		} else {
			[self.tableView reloadData];
			[self updateToolbar];
		}
	}
}

- (void) imageLoadProgress:(NSNotification *)notif {
	NSString *ID = [[notif userInfo] objectForKey:@"ID"];
	if ([ID isEqualToString:self.illustID]) {
		MediumImageCell *cell = (MediumImageCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
		if ([cell isKindOfClass:[MediumImageCell class]]) {
			cell.progressView.progress = [[[notif userInfo] objectForKey:@"Progress"] doubleValue] / 100.0;
		}
	}
}

- (void) bookmarkFinished:(NSNotification *)notif {
	NSString *ID = [[notif userInfo] objectForKey:@"IllustID"];
	if ([ID isEqualToString:self.illustID]) {
		[[self pixiv] removeEntriesForIllustID:self.illustID];
		[self reload];
	}	
}

- (void) ratingFinished:(NSNotification *)notif {
	NSString *ID = [[notif userInfo] objectForKey:@"IllustID"];
	if ([ID isEqualToString:self.illustID]) {
		[[self pixiv] removeEntriesForIllustID:self.illustID];
		[self reload];
	}	
}

- (void) commentFinished:(NSNotification *)notif {
	NSString *ID = [[notif userInfo] objectForKey:@"IllustID"];
	if ([ID isEqualToString:self.illustID]) {
		[[self pixiv] removeEntriesForIllustID:self.illustID];
		[self reload];
	}	
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	[super viewDidUnload];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
	//[[self pixiv] addToBookmarkCancel];
	[[self pixiv] loginCancel];

	//self.illustID = nil;
	
	[connection_ cancel];
	connection_ = nil;
	[parser_ release];
	parser_ = nil;

	//[info_ release];
	//info_ = nil;
	[whiteIndicator release];
	
	self.tableView = nil;
	self.scrollView = nil;
}

- (BOOL) showAddButton {
	return (![NSStringFromClass([self class]) hasPrefix:@"Tumblr"] && ![NSStringFromClass([self class]) hasPrefix:@"Danbooru"] && ![NSStringFromClass([self class]) hasPrefix:@"Seiga"]);
}

- (void) setupToolbar {
    NSMutableArray	*tmp = [NSMutableArray array];
    UIBarButtonItem	*item;
    
    if ([self commentEnabled] && [self ratingEnabled]) {
        [tmp addObject:[[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"star.png"] style:UIBarButtonItemStylePlain target:self action:@selector(composeAction:)] autorelease]];
        [tmp addObject:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease]];
    }
    
    if ([self showAddButton]) {
        item = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addToBookmark:)] autorelease];
        [tmp addObject:item];
        item.enabled = !self.account.anonymous;

        [tmp addObject:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease]];
    }
        
	[tmp addObject:[[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"save.png"] style:UIBarButtonItemStylePlain target:self action:@selector(saveAction:)] autorelease]];
    [tmp addObject:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease]];
    
    [tmp addObject:[[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"left_tool.png"] style:UIBarButtonItemStylePlain target:self action:@selector(prev)] autorelease]];
    [tmp addObject:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease]];

    [tmp addObject:[[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"right_tool.png"] style:UIBarButtonItemStylePlain target:self action:@selector(next)] autorelease]];
    [tmp addObject:[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil] autorelease]];

    item = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(action:)] autorelease];
    [tmp addObject:item];
 
    
    /*
    if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
        item = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"gototop.png"] style:UIBarButtonItemStylePlain target:self action:@selector(goToTop)];
        [tmp addObject:item];
        [item release];
		
        item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        [tmp addObject:item];
        [item release];
    }
    
    if ([self commentEnabled]) {
        item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(comment)];
        //item = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"comment.png"] style:UIBarButtonItemStylePlain target:self action:@selector(comment)];
        item.enabled = !self.account.anonymous;
        [tmp addObject:item];
        [item release];
        
        item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        [tmp addObject:item];
        [item release];
    }
    
    if ([self ratingEnabled]) {
        item = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"star.png"] style:UIBarButtonItemStylePlain target:self action:@selector(rating:)];
        item.enabled = (info_ && [[info_ objectForKey:@"RatingEnable"] boolValue]);
        [tmp addObject:item];
        [item release];
		
        item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        [tmp addObject:item];
        [item release];
    }
    
    item = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"tumblr.png"] style:UIBarButtonItemStylePlain target:self action:@selector(tumblr:)];
    item.enabled = ([self isKindOfClass:[TumblrMediumViewController class]]) || ([Tumblr sharedInstance].available && [[self cache] imageDataForKey:self.illustID] != nil && info_ && ![[info_ objectForKey:@"ContentType"] isEqual:@"novel"]);
    [tmp addObject:item];
    [item release];
    
    item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    [tmp addObject:item];
    [item release];
    
    item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(action:)];
    [tmp addObject:item];
    [item release];
    
    if (![self isKindOfClass:[TumblrMediumViewController class]] && ![NSStringFromClass([self class]) hasPrefix:@"Danbooru"]) {
        item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        [tmp addObject:item];
        [item release];
        
        item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addToBookmark:)];
        [tmp addObject:item];
        item.enabled = !self.account.anonymous;
        [item release];
    }
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad || [NSStringFromClass([self class]) hasPrefix:@"Danbooru"]) {
        item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        [tmp addObject:item];
        [item release];
        
        [tmp addObject:[[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"save.png"] style:UIBarButtonItemStylePlain target:self action:@selector(save)] autorelease]];
    }
     */
    
    [self setToolbarItems:tmp animated:NO];
    //[self.navigationController.toolbar setItems:tmp animated:NO];
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	//[[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
	[self setStatusBarHidden:NO animated:animated];
	[self.navigationController setNavigationBarHidden:NO animated:animated];
	[self.navigationController setToolbarHidden:NO animated:animated];

	[self setupToolbar];
    
    /*
	UISegmentedControl *seg = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:[UIImage imageNamed:@"up.png"], [UIImage imageNamed:@"down.png"], nil]];
	seg.segmentedControlStyle = UISegmentedControlStyleBar;
	//seg.tintColor = [UIColor grayColor];
	seg.momentary = YES;
	[seg addTarget:self action:@selector(segmentAction:) forControlEvents:UIControlEventValueChanged];
	UIBarButtonItem	*item = [[UIBarButtonItem alloc] initWithCustomView:seg];
	[seg release];
	self.navigationItem.rightBarButtonItem = item;
	[item release];
     */
    
	if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
		self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Home", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(goToTop)] autorelease];
	}
	
	/*
	if ([self.view viewWithTag:1234]) {
		UIActivityIndicatorView *activity = (UIActivityIndicatorView *)[self.view viewWithTag:1234];
		CGRect r = activity.frame;
		r.origin.x = ([self size].width - r.size.width) / 2.0;
		r.origin.y = (390 - r.size.height) / 2.0;
		activity.frame = r;
		[activity startAnimating];
	}
	*/
	
	//[self updateSegment];
	[self reload];
	[self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	[self updateSegment];
}

- (void) viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	if (actionSheet_) [actionSheet_ dismissWithClickedButtonIndex:[actionSheet_ cancelButtonIndex] animated:NO];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	//if (info_) [self update:info_];
	[self.tableView reloadData];
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	self.ugoIllust.delegate = nil;
	self.ugoIllust = nil;
	self.ugoIllustPlayer.delegate = nil;
	self.ugoIllustPlayer = nil;
	
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
	//[[self pixiv] addToBookmarkCancel];
	[[self pixiv] loginCancel];
	
	//self.illustID = nil;
	
	[connection_ cancel];
	connection_ = nil;
	[parser_ release];
	parser_ = nil;
	
	//[info_ release];
	//info_ = nil;
	[whiteIndicator release];
	
	[imageCell release];
	imageCell = nil;
	self.tableView = nil;
	self.scrollView = nil;

	
	[[self pixiv] removeEntriesForIllustID:self.illustID];
	[illustID release];
	[account release];
	[info_ release];
	[tableRows release];
		
    [super dealloc];
}

#pragma mark-

- (void) imageViewLoaded:(NSNotification *)notif {
	[(UITableView *)self.tableView reloadData];
}

- (NSString *) serviceName {
	return @"pixiv";
}

- (NSString *) tumblrServiceName {
	return @"<a href=\"http://www.pixiv.net/\">pixiv</a>";
}

- (NSString *) url {
	return [NSString stringWithFormat:@"http://www.pixiv.net/member_illust.php?mode=medium&illust_id=%@", self.illustID];
}

- (NSString *) parserClassName {
	if ([[info_ objectForKey:@"IllustMode"] isEqualToString:@"manga"]) {
		return @"PixivMangaParser";
	} else {	
		return @"PixivBigParser";
	}
}

- (NSString *) sourceURL {
	if ([[info_ objectForKey:@"IllustMode"] isEqualToString:@"manga"]) {
		return [NSString stringWithFormat:@"http://www.pixiv.net/member_illust.php?mode=manga&illust_id=%@", self.illustID];
	} else {
		return [NSString stringWithFormat:@"http://www.pixiv.net/member_illust.php?mode=big&illust_id=%@", self.illustID];
	}
}

- (UIBarButtonItem *) saveButton {
	for (UIBarButtonItem *item in self.toolbarItems) {
		if (item.action == @selector(saveAction:)) {
			return item;
		}
	}
	return nil;
}

- (NSArray *) saveImageURLs {
	if (info_[@"Images"]) {
		NSMutableArray *ary = [NSMutableArray array];
		for (NSDictionary *d in info_[@"Images"]) {
			[ary addObject:d[@"URLString"]];
		}
		return ary;
	} else {
		return nil;
	}
}

- (NSData *) saveImageData {
	return nil;
}

- (void) save:(NSString *)local data:(NSData *)data withInfo:(NSDictionary *)info type:(int)type {	
	if (local && type == 1) {
		NSMutableDictionary *dic = [[info mutableCopy] autorelease];
		NSString *p = [local stringByAppendingString:@"_db"];
		[data writeToFile:p atomically:YES];
			
		[dic setObject:p forKey:@"Path"]; 

		[[DropBoxTail sharedInstance] upload:dic];
	} else if (local && type == 2) {
		NSMutableDictionary *dic = [[info mutableCopy] autorelease];
		NSString *p = [local stringByAppendingString:@"_en"];
		[data writeToFile:p atomically:YES];

		[dic setObject:p forKey:@"Path"]; 

		[[EvernoteTail sharedInstance] upload:dic];
	} else if (local && (type == 3 || type == 4)) {
		NSMutableDictionary *dic = [[info mutableCopy] autorelease];
		NSString *p = [local stringByAppendingString:@"_tu"];
		[data writeToFile:p atomically:YES];
		
		[dic setObject:p forKey:@"Path"]; 
		
		[[Tumblr sharedInstance] upload:dic];
	} else if (local && type == 5) {
		NSMutableDictionary *dic = [[info mutableCopy] autorelease];
		NSString *p = [local stringByAppendingString:@"_ss"];
		[data writeToFile:p atomically:YES];
		
		[dic setObject:p forKey:@"Path"]; 
		
		[[SugarSync sharedInstance] upload:dic];
	} else if (local && type == 6) {
		NSMutableDictionary *dic = [[info mutableCopy] autorelease];
		NSString *p = [local stringByAppendingString:@"_gd"];
		[data writeToFile:p atomically:YES];
		
		[dic setObject:p forKey:@"Path"]; 
		
		[[GoogleDrive sharedInstance] upload:dic];
	} else if (local && type == 7) {
		NSMutableDictionary *dic = [[info mutableCopy] autorelease];
		NSString *p = [local stringByAppendingString:@"_sd"];
		[data writeToFile:p atomically:YES];
		
		[dic setObject:p forKey:@"Path"]; 
		
		[[SkyDrive sharedInstance] upload:dic];
	} else {
		NSMutableDictionary *dic = [[info mutableCopy] autorelease];
		NSString *p = [local stringByAppendingString:@"_cr"];
		[data writeToFile:p atomically:YES];

		[dic setObject:p forKey:@"Path"]; 
			
		[[CameraRoll sharedInstance] save:dic];
	}
}

- (void) save:(int)type {
	NSData *data = [self saveImageData];
	if (self.ugoIllust) {
		if (type == 3 || type == 4) {
			data = self.ugoIllust.gifDataForTumblr;
		} else {
			data = self.ugoIllust.gifData;
		}
	}

	NSDictionary	*info = [self infoForIllustID:self.illustID];
	NSString		*title = [info objectForKey:@"Title"];
	NSString		*user = [info objectForKey:@"UserName"];
	NSMutableArray	*tags = [NSMutableArray array];
	for (NSDictionary *tag in [info objectForKey:@"Tags"]) {
		if ([tag isKindOfClass:[NSString class]]) {
			[tags addObject:tag];
		} else if ([tag isKindOfClass:[NSDictionary class]]) {
			[tags addObject:[tag objectForKey:@"Name"]];
		}
	}
	[tags addObject:[self serviceName]];
	if (!title) {
		title = self.illustID;
	}
		
	NSArray *a_paths = NSSearchPathForDirectoriesInDomains( NSCachesDirectory, NSUserDomainMask, YES );
	NSString *local = nil;
	if ([a_paths count] > 0) {
		CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
		NSString *uuidStr = [(id)CFUUIDCreateString(kCFAllocatorDefault, uuid) autorelease];
		CFRelease(uuid);
		local = [[a_paths objectAtIndex:0] stringByAppendingPathComponent:uuidStr];
	} else {
		assert(0);
	}

	NSMutableDictionary *dic = [NSMutableDictionary dictionary];
	id obj;
			
	obj = [self parserClassName];
	if (obj) [dic setObject:obj forKey:@"ParserClass"]; 
	obj = [self sourceURL];
	if (obj) [dic setObject:obj forKey:@"SourceURL"]; 
	obj = user;
	if (obj) [dic setObject:obj forKey:@"Username"]; 
	obj = [self serviceName];
	if (obj) [dic setObject:obj forKey:@"ServiceName"]; 
	obj = [self referer];
	if (obj) [dic setObject:obj forKey:@"Referer"]; 
	obj = title;
	if (obj) [dic setObject:obj forKey:@"Name"]; 
	obj = title;
	if (obj) [dic setObject:obj forKey:@"Title"]; 
	obj = tags;
	if (obj) [dic setObject:obj forKey:@"Tags"]; 
	obj = [self url];
	if (obj) {
		[dic setObject:obj forKey:@"URL"]; 
		[dic setObject:obj forKey:@"Referer"]; 
	}
	
	if (type == 3 || type == 4) {
		NSString *url = [self url];
		NSString *caption;
		if ([info_ objectForKey:@"Title"] && [info_ objectForKey:@"UserName"]) {
#ifdef PIXITAIL
			caption = [NSString stringWithFormat:NSLocalizedString(@"Tumblr caption pixitail", nil), url, [info_ objectForKey:@"Title"], [info_ objectForKey:@"UserName"], [self tumblrServiceName]];
#else
			caption = [NSString stringWithFormat:NSLocalizedString(@"Tumblr caption", nil), url, [info_ objectForKey:@"Title"], [info_ objectForKey:@"UserName"],	[self tumblrServiceName]];
#endif
		} else {
#ifdef PIXITAIL
			caption = [NSString stringWithFormat:NSLocalizedString(@"Tumblr caption pixitail no author", nil), url, [self tumblrServiceName]];
#else
			caption = [NSString stringWithFormat:NSLocalizedString(@"Tumblr caption no author", nil), url, url, [self tumblrServiceName]];
#endif
		}
		[dic setObject:caption forKey:@"Caption"];

		if (self.ugoIllust) {
			UIImage *img = self.ugoIllust.firstImage;
			if (data.length < 1024 * 1024) {
				dic[@"ContentType"] = @"image/gif";
				dic[@"Filename"] = @"image.gif";
			} else {
				data = UIImageJPEGRepresentation(img, 0.8);
				dic[@"ContentType"] = @"image/jpeg";
				dic[@"Filename"] = @"image.jpg";
			}
		} else {
			dic[@"ContentType"] = @"image/jpeg";
			dic[@"Filename"] = @"image.jpg";
		}
		if (type == 4) {
			dic[@"Private"] = @(YES);
		}
		dic[@"URL"] = url;
	}
	
	NSArray *imageURLs = [self saveImageURLs];
	if (imageURLs.count == 0) {
		[dic setObject:local forKey:@"Path"];

		[self save:local data:data withInfo:dic type:type];
	} else if (imageURLs.count == 1) {
		[dic setObject:local forKey:@"Path"];
		[dic setObject:[imageURLs lastObject] forKey:@"ImageURL"]; 

		[self save:local data:data withInfo:dic type:type];
	} else {
		if (type == 3 || type == 4) {
			// tumblr
			NSMutableArray *list = [NSMutableArray array];
			int i = 0;
			for (NSString *imgurl in imageURLs) {
				local = [local stringByAppendingFormat:@"_%d", i++];
				
				NSMutableDictionary *d = [[dic mutableCopy] autorelease];
				[d setObject:imgurl forKey:@"ImageURL"];
				[d setObject:local forKey:@"Path"];
				[d setObject:[NSString stringWithFormat:@"%d.jpg", i] forKey:@"Filename"];
				
				[list addObject:d];
			}
			
			NSMutableDictionary *d = [[dic mutableCopy] autorelease];
			d[@"list"] = list;
			[[Tumblr sharedInstance] upload:d];
		} else {
			int i = 0;
			for (NSString *imgurl in imageURLs) {
				local = [local stringByAppendingFormat:@"_%d", i++];
				
				[dic setObject:imgurl forKey:@"ImageURL"];
				[dic setObject:local forKey:@"Path"];
				[dic setObject:[title stringByAppendingFormat:@"_%03d", i] forKey:@"Name"];
				[dic setObject:[title stringByAppendingFormat:@"_%03d", i] forKey:@"Title"];
				[dic setObject:title forKey:@"Directory"];
				
				[self save:local data:data withInfo:dic type:type];
			}
			
		}
	}
	
	//[self saveButton].enabled = NO;
}

- (NSString *) tagsDesc {
	NSMutableString *str = [NSMutableString string];
	for (NSDictionary *tag in [info_ objectForKey:@"Tags"]) {
		NSString *name;
		if ([tag isKindOfClass:[NSString class]]) {
			name = (NSString *)tag;
		} else if ([tag isKindOfClass:[NSDictionary class]]) {
			name = [tag objectForKey:@"Name"];
		}

		if ([name length] > 0) {
			[str appendString:name];
		}
		if (tag != [[info_ objectForKey:@"Tags"] lastObject]) {
			[str appendString:@","];
		}
	}
	return str;
}

- (void) postToTumblr:(BOOL)private {
	//DLog(@"writePhoto: %@", [info_ description]);
	//[[Tumblr sharedInstance] setup];

	/*
	// 「寝ているお姉さん」/「Suoni」のイラスト [pixiv]
	NSData *data = [self saveImageData];
	NSString *url = [self url];
	NSString *caption;
	if ([info_ objectForKey:@"Title"] && [info_ objectForKey:@"UserName"]) {
#ifdef PIXITAIL
		caption = [NSString stringWithFormat:NSLocalizedString(@"Tumblr caption pixitail", nil), url, [info_ objectForKey:@"Title"], [info_ objectForKey:@"UserName"], [self tumblrServiceName]];
#else
		caption = [NSString stringWithFormat:NSLocalizedString(@"Tumblr caption", nil), url, [info_ objectForKey:@"Title"], [info_ objectForKey:@"UserName"],	[self tumblrServiceName]];
#endif
	} else {
#ifdef PIXITAIL
		caption = [NSString stringWithFormat:NSLocalizedString(@"Tumblr caption pixitail no author", nil), url, [self tumblrServiceName]];
#else
		caption = [NSString stringWithFormat:NSLocalizedString(@"Tumblr caption no author", nil), url, url, [self tumblrServiceName]];
#endif
	}
	
	NSArray *a_paths = NSSearchPathForDirectoriesInDomains( NSCachesDirectory, NSUserDomainMask, YES );
	NSString *local = nil;
	if ([a_paths count] > 0) {
		CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
		NSString *uuidStr = [(id)CFUUIDCreateString(kCFAllocatorDefault, uuid) autorelease];
		CFRelease(uuid);
		local = [[a_paths objectAtIndex:0] stringByAppendingPathComponent:uuidStr];
	} else {
		assert(0);
	}
	
	NSMutableDictionary *info = [NSMutableDictionary dictionaryWithObjectsAndKeys:
		@"image/jpeg",		@"ContentType",
		@"image.jpg",		@"Filename",
		[NSNumber numberWithBool:private],		@"Private",
		caption,			@"Caption",
		url,				@"URL",
		[self tagsDesc],	@"Tags",
		[[self saveImageURLs] objectAtIndex:0],	@"ImageURL",
		local,				@"Path",
		nil];

	NSArray *imageURLs = [self saveImageURLs];
	if (imageURLs.count == 0) {
		[info setObject:local forKey:@"Path"];
	} else if (imageURLs.count == 1) {
		[info setObject:local forKey:@"Path"];
		[info setObject:[imageURLs lastObject] forKey:@"ImageURL"]; 
	} else {
		int i = 0;
		for (NSString *imgurl in imageURLs) {
			[info setObject:imgurl forKey:@"ImageURL"]; 
			[info setObject:[local stringByAppendingFormat:@"_%d", i++] forKey:@"Path"];
			[info setObject:[title stringByAppendingFormat:@"_%03d", i] forKey:@"Name"];
			[info setObject:[title stringByAppendingFormat:@"_%03d", i] forKey:@"Title"];
			[info setObject:title forKey:@"Directory"];
		}
	}
	
	[data writeToFile:local atomically:YES];
	
    [[Tumblr sharedInstance] upload:info];
	 */
}

- (IBAction) addToBookmark:(id)sender {
	if (actionSheet_) [actionSheet_ dismissWithClickedButtonIndex:[actionSheet_ cancelButtonIndex] animated:NO];

	UIActionSheet	*alert = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Are you sure to add to favolite?", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Bookmarks", nil), NSLocalizedString(@"Bookmarks(Hidden)", nil), NSLocalizedString(@"Favorite User", nil), NSLocalizedString(@"Favorite User(Hidden)", nil), nil];
	if (([[UIDevice currentDevice] respondsToSelector:@selector(userInterfaceIdiom)] ? [[UIDevice currentDevice] userInterfaceIdiom] : 0) != 0) {
		[alert showFromBarButtonItem:sender animated:YES];
	} else {
		[alert showFromToolbar:self.navigationController.toolbar];
	}
	actionSheet_ = alert;
	[alert release];
}

- (void) compose:(UIActionSheet *)sheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSString *title = [sheet buttonTitleAtIndex:buttonIndex];
    if ([self ratingTitle] && [title isEqualToString:[self ratingTitle]]) {
        // 評価
        [self rating:[self composeButton]];
    } else if ([title isEqualToString:@"コメント"]) {
        // コメント
        [self comment];
    }
}

- (void) save:(UIActionSheet *)sheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSString *title = [sheet buttonTitleAtIndex:buttonIndex];
    if ([title isEqualToString:NSLocalizedString(@"Post to tumblr", nil)]) {
        [self save:3];
    } else if ([title isEqualToString:NSLocalizedString(@"Post to tumblr(Private)", nil)]) {
        [self save:4];
    } else if ([title isEqualToString:NSLocalizedString(@"Dropbox", nil)]) {
        [self save:1];
    } else if ([title isEqualToString:NSLocalizedString(@"Evernote", nil)]) {
		if (![EvernoteTail sharedInstance].session.isAuthenticated) {
			[[EvernoteTail sharedInstance].session authenticateWithViewController:self completionHandler:^(NSError *error) {
				if (error) {
					[[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Login failed", nil) message:[error localizedDescription] delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil] autorelease] show];
				}
			}];
		} else {
			[self save:2];
		}
    } else if ([title isEqualToString:NSLocalizedString(@"SugarSync", nil)]) {
        [self save:5];
    } else if ([title isEqualToString:NSLocalizedString(@"Googleドライブ", nil)]) {
        [self save:6];
    } else if ([title isEqualToString:NSLocalizedString(@"SkyDrive", nil)]) {
		if (![SkyDrive sharedInstance].available) {
			[[SkyDrive sharedInstance] login:self withDelegate:nil];
		} else {
			[self save:7];
		}
    } else if ([title isEqualToString:@"カメラロール"]) {
        [self save:0];
    } else if ([title isEqualToString:@"その他"]) {
		NSMutableArray *mary = [NSMutableArray array];
		
		UIImage *img = nil;
		if (self.ugoIllust){
			img = self.ugoIllust.firstImage;
		} else if ([[self imageLoaderManager] imageIsLoadedForID:self.illustID]) {
			img = [[self imageLoaderManager] imageForID:self.illustID];
		}
		if (img) {
			NSString *text = [self twitterDefaultString:[self url]];
			[mary addObject:text];
			[mary addObject:img];
			
			UIActivityViewController *vc = [[UIActivityViewController alloc] initWithActivityItems:mary applicationActivities:nil];
			if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
				dispatch_async(dispatch_get_main_queue(), ^{
					UIPopoverController *popoverController = [[[UIPopoverController alloc] initWithContentViewController:vc] autorelease];
					[popoverController presentPopoverFromBarButtonItem:[self saveButton] permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
				});
			} else {
				[self presentViewController:vc animated:YES completion:^{
				}];
			}
		}
    }
}

- (void) add:(UIActionSheet *)sheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	UIAlertView	*alert = nil;
	long		err;
	if (0 && [self isInBookmark]) {
		// 削除
		if (buttonIndex == 0) {
			// OK
			err = [[self pixiv] removeFromBookmark:self.illustID];
			if (err) {
				alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Remove from bookmark failed.", @"") message:@"" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];	
			}
		}
	} else {
		// 追加		
		NSMutableDictionary	*mdic = [[info_ mutableCopy] autorelease];
		if (buttonIndex == 0) {
			// 公開
			[mdic setObject:[NSNumber numberWithBool:YES] forKey:@"IsOpen"];
			[mdic setObject:@"illust" forKey:@"Type"];
			
			[[self pixiv] addToBookmark:self.illustID withInfo:mdic];
		} else if (buttonIndex == 1) {
			// 非公開
			[mdic setObject:[NSNumber numberWithBool:NO] forKey:@"IsOpen"];
			[mdic setObject:@"illust" forKey:@"Type"];

			[[self pixiv] addToBookmark:self.illustID withInfo:mdic];
		} else if (buttonIndex == 2) {
			// 公開お気に入りユーザ
			[mdic setObject:[NSNumber numberWithBool:YES] forKey:@"IsOpen"];
			[mdic setObject:@"user" forKey:@"Type"];

			[[self pixiv] addToBookmark:[info_ objectForKey:@"UserID"] withInfo:mdic];
		} else if (buttonIndex == 3) {
			// 非公開お気に入りユーザ
			[mdic setObject:[NSNumber numberWithBool:NO] forKey:@"IsOpen"];
			[mdic setObject:@"user" forKey:@"Type"];

			[[self pixiv] addToBookmark:[info_ objectForKey:@"UserID"] withInfo:mdic];
		} 
	}
	
	if (alert) {
		[alert show];
		[alert release];	
	} else {
		addButtonIndex_ = buttonIndex;
	}
}

- (void)action:(UIActionSheet *)sheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex != sheet.cancelButtonIndex) {
		switch (buttonIndex) {
		case 0:
			[self showUserBookmark];
			break;
		case 1:
			[self goToWeb];
			break;
		case 2:
			[self twitter];
			break;
		case 3:
			[self report];
			break;
		default:
			break;
		}
	}
}

- (void)tumblr:(UIActionSheet *)sheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex < 2) {
		[self postToTumblr:buttonIndex == 1];
	}
}

- (void)actionSheet:(UIActionSheet *)sheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	actionSheet_ = nil;
	
	if (sheet.tag == 100) {
		// tumblr
		[self tumblr:sheet clickedButtonAtIndex:buttonIndex];
    } else if (sheet.tag == 200) {
        // compose
		[self compose:sheet clickedButtonAtIndex:buttonIndex];
    } else if (sheet.tag == 300) {
        // save
		[self save:sheet clickedButtonAtIndex:buttonIndex];
	} else if ([sheet.title isEqualToString:@""]) {
		// action
		[self action:sheet clickedButtonAtIndex:buttonIndex];
	} else {
		// add
		[self add:sheet clickedButtonAtIndex:buttonIndex];
	}
}

- (void) pixService:(PixService *)sender addBookmarkFinished:(long)err {
	UIAlertView	*alert = nil;
	
	[self hideProgress];
	if (addButtonIndex_ == 0) {
		// 公開
		if (err) {
			alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Add to bookmark failed.", @"") message:@"" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];				
		} else {
				alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Add to bookmark ok.", @"") message:@"" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];	
		}
	} else if (addButtonIndex_ == 1) {
		// 非公開
		if (err) {
			alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Add to bookmark failed.", @"") message:@"" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];				
		} else {
			alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Add to bookmark ok.", @"") message:@"" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];	
		}
	} else if (addButtonIndex_ == 2) {
		// 公開お気に入りユーザ
		if (err) {
			alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Add to favorite failed.", @"") message:@"" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];				
		} else {
			alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Add to favorite ok.", @"") message:@"" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];	
		}
	} else if (addButtonIndex_ == 3) {
		// 非公開お気に入りユーザ
		if (err) {
			alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Add to favorite failed.", @"") message:@"" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];				
		} else {
			alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Add to favorite ok.", @"") message:@"" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];	
		}
	} 
	addButtonIndex_ = -1;
	
	[alert show];
	[alert release];	
}

#pragma mark-

/*
- (void) tumblr:(Tumblr *)sender writePhotoProgress:(int)percent {
	[progressViewController_ setDoubleValue:(float)percent / 100.0];
}

- (void) tumblr:(Tumblr *)sender writePhotoFinished:(long)err {
	[self hideProgress];
	
	UIAlertView *alert;
	if (err == 201) {	
		alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Tumblr post ok.", nil) message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];

		// タグクラウド更新
		for (NSDictionary *tag in [info_ objectForKey:@"Tags"]) {
			[[TagCloud sharedInstance] add:[tag objectForKey:@"Name"] forType:@"Tumblr" user:[Tumblr sharedInstance].username];
		}
	} else {
		alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Tumblr post failed.", nil) message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil];
	}
	[alert show];
	[alert release];
}
*/

- (void) progressCancel:(ProgressViewController *)sender {
	switch (sender.tag) {
	case 100:
		[[self pixiv] commentCancel];
		break;
	case 200:
		[[self pixiv] ratingCancel];
		break;
	//case 300:
	//	[[Tumblr sharedInstance] writePhotoCancel];
	//	break;
	case 400:
		[[self pixiv] addToBookmarkCancel];
		break;
	case 1000:
		[[self pixiv] loginCancel];
		[self.navigationController popToRootViewControllerAnimated:YES];
		break;
	default:
		break;
	}
	
	[self hideProgress];
}

#pragma mark-

- (void) pixService:(PixService *)sender loginFinished:(long)err {
	[self hideProgress];
	if (err) {
		// もいっかい
		err = [[self pixiv] login:self];
		if (err) {
			UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"ログインに失敗しました。" message:@"" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil] autorelease];
			[alert show];
			[self.navigationController popToRootViewControllerAnimated:YES];
			return;
		}
	} else {
		[self reload];
	}
}

- (void) photoLinkAction:(id)sender {
	NSString *type = [info_ objectForKey:@"PhotoType"];
	//NSString *link = [info_ objectForKey:@"PhotoLink"];
	NSString *iid = [info_ objectForKey:@"PhotoLinkIllustID"];
	
	if ([type isEqual:@"Pixiv"]) {
		if (iid) {
			[[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"pixitail://org.cathand.pixitail/pixiv/%@", iid]]];
		}
		/*
		PixAccount *acc = [[AccountManager sharedInstance] defaultAccount:AccountType_Pixiv];
		if (iid && acc) {
			if (![[Pixiv sharedInstance].username isEqual:acc.username] || ![[Pixiv sharedInstance].password isEqual:acc.password]) {
				[Pixiv sharedInstance].username = acc.username;
				[Pixiv sharedInstance].password = acc.password;
				[Pixiv sharedInstance].logined = NO;
			}	
	
			PixivMediumViewController *controller = [[PixivMediumViewController alloc] init];
			controller.illustID = iid;
			[self.navigationController pushViewController:controller animated:YES];
			[controller release];
		}
		*/
	} else if ([type isEqual:@"Pixa"]) {
		PixAccount *acc = [[AccountManager sharedInstance] defaultAccount:@"PiXA"];
		if (iid && acc) {
			if (![[Pixa sharedInstance].username isEqual:acc.username] || ![[Pixa sharedInstance].password isEqual:acc.password]) {
				[Pixa sharedInstance].username = acc.username;
				[Pixa sharedInstance].password = acc.password;
				[Pixa sharedInstance].logined = NO;
			}	
	
			PixaMediumViewController *controller = [[PixaMediumViewController alloc] init];
			controller.illustID = iid;
			controller.account = account;
			[self.navigationController pushViewController:controller animated:YES];
			[controller release];
		}
	} else if ([type isEqual:@"Tinami"]) {
		PixAccount *acc = [[AccountManager sharedInstance] defaultAccount:@"TINAMI"];
		if (iid) {
			if (acc && (![[Tinami sharedInstance].username isEqual:acc.username] || ![[Tinami sharedInstance].password isEqual:acc.password])) {
				[Tinami sharedInstance].username = acc.username;
				[Tinami sharedInstance].password = acc.password;
				[Tinami sharedInstance].logined = NO;
			} else {
				[Tinami sharedInstance].username = @"";
				[Tinami sharedInstance].password = @"";
				[Tinami sharedInstance].logined = NO;
			}
	
			TinamiMediumViewController *controller = [[TinamiMediumViewController alloc] init];
			controller.illustID = iid;
			controller.account = account;
			[self.navigationController pushViewController:controller animated:YES];
			[controller release];
		}
	}
}

#pragma mark-

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return [tableRows count];
	
	if (connection_) {
		return 1;
	} else {
		NSInteger ret = 2;
		if ([info_ objectForKey:@"Tags"]) {
			ret += 1;
		}
		if ([[info_ objectForKey:@"OneComments"] count] > 0) {
			ret += 1;
		}
		return ret;
	}
}

- (BOOL) hasLink {
	return ([info_ objectForKey:@"PhotoType"] && [info_ objectForKey:@"PhotoLink"] && [info_ objectForKey:@"PhotoLinkIllustID"]);
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [[tableRows objectAtIndex:section] count];
	
	NSInteger ret = 0;
	
	if (section == 0) {
		ret++;
	} else if (section == 1) {
		if ([info_ objectForKey:@"Title"]) {
			ret++;
		}
		if ([info_ objectForKey:@"UserName"]) {
			ret++;
		}
		if ([info_ objectForKey:@"Comment"]) {
			ret++;
		}

		if ([info_ objectForKey:@"RatingViewCount"] || [info_ objectForKey:@"total_view"]) {
			ret++;
		}
		if ([info_ objectForKey:@"RatingCount"] || [info_ objectForKey:@"user_view"]) {
			ret++;
		}
		if ([info_ objectForKey:@"RatingScore"] || [info_ objectForKey:@"valuation"]) {
			ret++;
		}

		if ([info_ objectForKey:@"RatingString"]) {
			ret++;
		}
		
		// photo type
		if ([self hasLink]) {
			ret++;
		}

	} else if (section == 2) {
		ret += [[info_ objectForKey:@"Tags"] count];
	} else if (section == 3) {
		ret += [[info_ objectForKey:@"OneComments"] count];
	} else if (section == 4) {
		if ([info_ objectForKey:@"PhotoType"] && [info_ objectForKey:@"PhotoLink"] && [info_ objectForKey:@"PhotoLinkIllustID"]) {
			ret++;
		}
	}
	
	return ret;
}

- (UIView *) sectionHeaderView:(NSString *)string {
	UIView *bgView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 20)] autorelease];
	UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(2, 0, self.view.frame.size.width - 20, 20)] autorelease];
		
	label.font = [UIFont boldSystemFontOfSize:16];
	label.textColor = [UIColor lightTextColor];
	label.shadowColor = [UIColor darkTextColor];
	label.shadowOffset = CGSizeMake(0, -1);
	label.backgroundColor = [UIColor clearColor];
	label.text = string;
		
	bgView.backgroundColor = [UIColor darkGrayColor];
	[bgView addSubview:label];
	bgView.alpha = 0.9;
	
	return bgView;
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
	if (section == 0) {
		return 0;
	} else if (section == 1) {
		return 0;
	} else if (section == 2) {
		return 20;
	} else if (section == 3) {
		return 20;
	} else if (section == 4) {
		return 0;	
	} else {
		return 0;
	}
	
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
	if (section == 0) {
		return nil;
	} else if (section == 1) {
		return nil;
	} else if (section == 2) {
		return [self sectionHeaderView:@"タグ"];
	} else if (section == 3) {
		return [self sectionHeaderView:@"コメント"];
	} else if (section == 4) {
		return nil;	
	} else {
		return nil;
	}
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSString *key = [[tableRows objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
	if ([key isEqual:@"Image"]) {
		if ([[info_ objectForKey:@"ContentType"] isEqual:@"novel"]) {
			return 0;
		} else {
			return [self imageFrame].size.height;
		}
	} else if ([key isEqual:@"UserName"] || [key isEqual:@"Comment"] || [key isEqual:@"Title"] || [key isEqual:@"RatingString"] || [key isEqual:@"DateString"]) {
		return [MediumViewLabelCell heightForDesc:[info_ objectForKey:key] viewWidth:self.view.frame.size.width];
	} else if ([key isEqual:@"Tags"]) {
		NSArray *ary = [info_ objectForKey:@"Tags"];
		id tag = indexPath.row < ary.count ? [ary objectAtIndex:indexPath.row] : nil;
		if ([tag isKindOfClass:[NSDictionary class]]) {
			tag = [tag objectForKey:@"Name"];
		}
		CGSize size = [tag sizeWithFont:[UIFont systemFontOfSize:14] constrainedToSize:CGSizeMake(self.view.frame.size.width - 20, FLT_MAX) lineBreakMode:UILineBreakModeCharacterWrap];
		return size.height + 10;
	} else if ([key isEqual:@"OneComments"]) {
		NSDictionary *com = [[info_ objectForKey:@"OneComments"] objectAtIndex:indexPath.row];
		return [MediumViewCommentCell heightForDesc:[com objectForKey:@"Comment"] viewWidth:self.view.frame.size.width];
	} else if ([key isEqual:@"PageCount"]) {
		return 22;
	} else {
		return 44;
	}
	
	/*
	if (indexPath.section == 0) {
		if ([[info_ objectForKey:@"ContentType"] isEqual:@"novel"]) {
			return 0;
		} else {
			return [self imageFrame].size.height;
		}
	} else if ([self hasLink] && indexPath.section == 1 && ((![info_ objectForKey:@"UserName"] && indexPath.row == 1) || ([info_ objectForKey:@"UserName"] && indexPath.row == 2))) {
		return 40;
	} else if (indexPath.section == 1) {
		if (indexPath.row < 4) {
			NSString *str = nil;
			switch (indexPath.row) {
			case 0:
				str = [info_ objectForKey:@"Title"];
				break;
			case 1:
				str = [info_ objectForKey:@"UserName"];
				break;
			case 2:
				str = [info_ objectForKey:@"Comment"];
				break;
			case 3:
				str = [info_ objectForKey:@"RatingString"];
				break;
			default:
				break;
			}
			if (str) {	
				return [MediumViewLabelCell heightForDesc:str viewWidth:self.view.frame.size.width];
			} else {
				return 50;
			}
		} else {
			return 50;
		}
	} else if (indexPath.section == 2) {
		id tag = [[info_ objectForKey:@"Tags"] objectAtIndex:indexPath.row];
		if ([tag isKindOfClass:[NSDictionary class]]) {
			tag = [tag objectForKey:@"Name"];
		}
		CGSize size = [tag sizeWithFont:[UIFont systemFontOfSize:14] constrainedToSize:CGSizeMake(self.view.frame.size.width - 20, FLT_MAX) lineBreakMode:UILineBreakModeCharacterWrap];
		return size.height + 10;
	} else if (indexPath.section == 3) {
		NSDictionary *com = [[info_ objectForKey:@"OneComments"] objectAtIndex:indexPath.row];
		return [MediumViewCommentCell heightForDesc:[com objectForKey:@"Comment"] viewWidth:self.view.frame.size.width];
	} else if (indexPath.section == 4) {
		return 44;
	} else {
		return 0;
	}
	 */
}

- (MediumViewImageCell *) imageCell:(UITableView *)tableView {
    static NSString *CellIdentifier = @"MediumViewImageCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [MediumViewImageCell cell];
		cell.backgroundColor = [UIColor clearColor];
    }
	return (MediumViewImageCell *)cell;
}

- (MediumViewLabelCell *) labelCell:(UITableView *)tableView {
    static NSString *CellIdentifier = @"MediumViewLabelCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [MediumViewLabelCell cell];
		cell.backgroundColor = [UIColor clearColor];
    }
	return (MediumViewLabelCell *)cell;
}

- (MediumViewCommentCell *) commentCell:(UITableView *)tableView {
    static NSString *CellIdentifier = @"MediumViewCommentCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [MediumViewCommentCell cell];
		cell.backgroundColor = [UIColor clearColor];
    }
	return (MediumViewCommentCell *)cell;
}

- (UITableViewCell *) defaultCell:(UITableView *)tableView {
    static NSString *CellIdentifier = @"UITableViewCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
		cell.backgroundColor = [UIColor clearColor];
    }
	return (UITableViewCell *)cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	NSString *key = [[tableRows objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
	if ([key isEqual:@"Image"]) {
		MediumImageCell *cell = imageCell;
		if (!cell) {
			cell = [MediumImageCell cell:tableView];
			imageCell = [cell retain];
		}
		
		NSString *urlString = [info_ objectForKey:@"MediumURLString"];
		if ([[info_ objectForKey:@"ContentType"] isEqual:@"novel"]) {
			if ([cell.activityView isAnimating]) {
				[cell.activityView stopAnimating];
			}
			cell.progressView.hidden = YES;
		} else if (self.ugoIllust) {
			if (self.ugoIllustPlayer) {
				if ([cell.activityView isAnimating]) {
					[cell.activityView stopAnimating];
				}
				
				if (!self.ugoIllustPlayer.isPlaying) {
					cell.mediumImageView.image = self.ugoIllust.firstImage;
					[self.ugoIllustPlayer play];
				}
				//cell.mediumImageView.image = nil;
				//cell.mediumImageView.image = img;
				//[cell.mediumImageView startAnimating];
			} else {
				if (![cell.activityView isAnimating]) {
					[cell.activityView startAnimating];
				}
				
				[self.ugoIllust load];
			}
		} else if (urlString) {
			if ([cell.activityView isAnimating]) {
				[cell.activityView stopAnimating];
			}
			
			UIImage *img = nil;
			if ([[self imageLoaderManager] imageIsLoadedForID:self.illustID]) {
				img = [[self imageLoaderManager] imageForID:self.illustID];
			}
			if (img) {
				cell.progressView.hidden = YES;
				cell.progressView.progress = 0;
				cell.mediumImageView.image = img;
			} else {
				if ([[self smallCache] conteinsImageForKey:self.illustID]) {
					cell.mediumImageView.image = [[self smallCache] imageForKey:self.illustID];
				} else {
					cell.mediumImageView.image = nil;
				}
				
				if ([[self imageLoaderManager] imageIsLoadingForID:self.illustID]) {
					cell.progressView.hidden = NO;
					cell.progressView.progress = [[self imageLoaderManager] imageLoadingPercentForID:self.illustID] / 100.0;
				} else {
					cell.progressView.hidden = NO;
					cell.progressView.progress = 0;
					
					[[self imageLoaderManager] loadImageForID:[info_ objectForKey:@"IllustID"] url:urlString];
				}
			}
		} else {
			if ([[self smallCache] conteinsImageForKey:self.illustID]) {
				cell.mediumImageView.image = [[self smallCache] imageForKey:self.illustID];
			} else {
				cell.mediumImageView.image = nil;
			}
			
			if (![cell.activityView isAnimating]) {
				[cell.activityView startAnimating];
			}
			cell.progressView.hidden = YES;
		}
		
		cell.accessoryType = UITableViewCellAccessoryNone;
		cell.selectionStyle = UITableViewCellSelectionStyleNone;		
		return cell;
	} else if ([key isEqual:@"Title"]) {
		MediumViewLabelCell *cell = [self labelCell:tableView];
		
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		cell.accessoryView = nil;
		cell.labelLabel.text = @"タイトル:";
		cell.descLabel.text = [info_ objectForKey:@"Title"] ? [info_ objectForKey:@"Title"] : @"不明";
		if ([[info_ objectForKey:@"ContentType"] isEqual:@"novel"]) {
			cell.accessoryView = [[[UIImageView alloc] initWithImage:whiteIndicator] autorelease];
			cell.selectionStyle = UITableViewCellSelectionStyleBlue;
		} else {
			cell.accessoryView = nil;			
		}
		return cell;
	} else if ([key isEqual:@"UserName"]) {
		MediumViewLabelCell *cell = [self labelCell:tableView];
		
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		cell.accessoryView = nil;
		cell.labelLabel.text = @"作者:";
		cell.descLabel.text = [info_ objectForKey:@"UserName"] ? [info_ objectForKey:@"UserName"] : @"";
		cell.selectionStyle = UITableViewCellSelectionStyleBlue;
		cell.accessoryView = [[[UIImageView alloc] initWithImage:whiteIndicator] autorelease];
		return cell;
	} else if ([key isEqual:@"Comment"]) {
		MediumViewLabelCell *cell = [self labelCell:tableView];
		
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		cell.accessoryView = nil;
		cell.labelLabel.text = @"コメント:";
		cell.descLabel.text = [info_ objectForKey:@"Comment"] ? [info_ objectForKey:@"Comment"] : @"";
		return cell;
	} else if ([key isEqual:@"RatingViewCount"]) {
		MediumViewLabelCell *cell = [self labelCell:tableView];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		cell.accessoryView = nil;
		cell.labelLabel.text = NSLocalizedString(@"RatingViewCount", nil);
		cell.descLabel.text = [info_ objectForKey:@"RatingViewCount"] ? [[info_ objectForKey:@"RatingViewCount"] stringValue] : @"";
		return cell;
	} else if ([key isEqual:@"RatingString"]) {
		MediumViewLabelCell *cell = [self labelCell:tableView];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		cell.accessoryView = nil;
		cell.labelLabel.text = @"評価";
		cell.descLabel.text = [[info_ objectForKey:@"RatingString"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		return cell;
	} else if ([key isEqual:@"total_view"]) {
		MediumViewLabelCell *cell = [self labelCell:tableView];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		cell.accessoryView = nil;
		
		cell.labelLabel.text = NSLocalizedString(@"total_view", nil);
		cell.descLabel.text = [info_ objectForKey:@"total_view"] ? [[info_ objectForKey:@"total_view"] stringValue] : @"";
		return cell;
	} else if ([key isEqual:@"RatingCount"]) {
		MediumViewLabelCell *cell = [self labelCell:tableView];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		cell.accessoryView = nil;
		
		cell.labelLabel.text = NSLocalizedString(@"RatingCount", nil);
		cell.descLabel.text = [info_ objectForKey:@"RatingCount"] ? [[info_ objectForKey:@"RatingCount"] stringValue] : @"";
		return cell;
	} else if ([key isEqual:@"user_view"]) {
		MediumViewLabelCell *cell = [self labelCell:tableView];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		cell.accessoryView = nil;
		
		cell.labelLabel.text = NSLocalizedString(@"user_view", nil);
		cell.descLabel.text = [info_ objectForKey:@"user_view"] ? [[info_ objectForKey:@"user_view"] stringValue] : @"";
		return cell;
	} else if ([key isEqual:@"RatingScore"]) {
		MediumViewLabelCell *cell = [self labelCell:tableView];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		cell.accessoryView = nil;
		
		cell.labelLabel.text = NSLocalizedString(@"RatingScore", nil);
		cell.descLabel.text = [info_ objectForKey:@"RatingScore"] ? [[info_ objectForKey:@"RatingScore"] stringValue] : @"";
		return cell;
	} else if ([key isEqual:@"valuation"]) {
		MediumViewLabelCell *cell = [self labelCell:tableView];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		cell.accessoryView = nil;
		
		cell.labelLabel.text = NSLocalizedString(@"valuation", nil);
		cell.descLabel.text = [info_ objectForKey:@"valuation"] ? [[info_ objectForKey:@"valuation"] stringValue] : @"";
		return cell;
	} else if ([key isEqual:@"Tags"]) {
		UITableViewCell *cell = [self defaultCell:tableView];
		id tag = [[info_ objectForKey:@"Tags"] objectAtIndex:indexPath.row];
		if ([tag isKindOfClass:[NSDictionary class]]) {
			tag = [tag objectForKey:@"Name"];
		}
		CGRect r = cell.textLabel.frame;
		r.size.width = self.view.frame.size.width - 20;
		cell.textLabel.frame = r;
		cell.textLabel.text = tag;
		cell.textLabel.numberOfLines = 0;
		cell.textLabel.font = [UIFont systemFontOfSize:14];
		cell.textLabel.textColor = [UIColor whiteColor];
		cell.accessoryView = [[[UIImageView alloc] initWithImage:whiteIndicator] autorelease];
		cell.selectionStyle = UITableViewCellSelectionStyleBlue;
		return cell;
	} else if ([key isEqual:@"OneComments"]) {
		MediumViewCommentCell *cell = [self commentCell:tableView];
		NSDictionary *com = [[info_ objectForKey:@"OneComments"] objectAtIndex:indexPath.row];
		cell.nameLabel.text = [com objectForKey:@"UserName"];
		cell.dateLabel.text = [com objectForKey:@"DateString"];
		cell.commentLabel.text = [com objectForKey:@"Comment"];
		cell.commentLabel.numberOfLines = 0;
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		return cell;
	} else if ([key isEqual:@"PhotoType"]) {
		UITableViewCell *cell = [self defaultCell:tableView];
		if ([[info_ objectForKey:@"PhotoType"] isEqual:@"Pixiv"]) {
			cell.textLabel.text = @"pixiv";
		} else if ([[info_ objectForKey:@"PhotoType"] isEqual:@"Pixa"]) {
			cell.textLabel.text = @"PiXA";
		} else if ([[info_ objectForKey:@"PhotoType"] isEqual:@"Tinami"]) {
			cell.textLabel.text = @"TINAMI";
		}
		
		cell.textLabel.numberOfLines = 1;
		cell.textLabel.font = [UIFont systemFontOfSize:14];
		cell.textLabel.textColor = [UIColor whiteColor];
		cell.accessoryView = [[[UIImageView alloc] initWithImage:whiteIndicator] autorelease];
		cell.selectionStyle = UITableViewCellSelectionStyleBlue;
		return cell;
	} else if ([key isEqual:@"DateString"]) {
		MediumViewLabelCell *cell = [self labelCell:tableView];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		cell.accessoryView = nil;
		cell.labelLabel.text = @"投稿日時";
		cell.descLabel.text = [[info_ objectForKey:@"DateString"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
		return cell;
	} else if ([key isEqual:@"PageCount"]) {
		UITableViewCell *cell = [self defaultCell:tableView];

		CGRect r = cell.textLabel.frame;
		r.size.width = self.view.frame.size.width - 20;
		cell.textLabel.frame = r;
		cell.textLabel.text = [NSString stringWithFormat:@"%@ページ", @([[info_ objectForKey:@"Images"] count])];
		cell.textLabel.numberOfLines = 0;
		cell.textLabel.font = [UIFont systemFontOfSize:14];
		cell.textLabel.textColor = [UIColor whiteColor];
		cell.accessoryView = nil;
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		return cell;
	} else {
		assert(0);
		return nil;
	}
	
	
	/*
	if (indexPath.section == 0) {
		MediumImageCell *cell = [MediumImageCell cell:tableView];
		
		NSString *url = [info_ objectForKey:@"MediumURLString"];
		if ([[info_ objectForKey:@"ContentType"] isEqual:@"novel"]) {
			if ([cell.activityView isAnimating]) {
				[cell.activityView stopAnimating];
			}
			cell.progressView.hidden = YES;
		} else if (url) {
			if ([cell.activityView isAnimating]) {
				[cell.activityView stopAnimating];
			}

			UIImage *img = nil;
			if ([[self imageLoaderManager] imageIsLoadedForID:self.illustID]) {
				img = [[self imageLoaderManager] imageForID:self.illustID];
			}
			if (img) {
				cell.progressView.hidden = YES;
				cell.progressView.progress = 0;
				cell.mediumImageView.image = img;
			} else {
				if ([[self smallCache] conteinsImageForKey:self.illustID]) {
					cell.mediumImageView.image = [[self smallCache] imageForKey:self.illustID];
				} else {
					cell.mediumImageView.image = nil;
				}
				
				if ([[self imageLoaderManager] imageIsLoadingForID:self.illustID]) {
					cell.progressView.hidden = NO;
					cell.progressView.progress = [[self imageLoaderManager] imageLoadingPercentForID:self.illustID] / 100.0;
				} else {
					cell.progressView.hidden = NO;
					cell.progressView.progress = 0;
					
					[[self imageLoaderManager] loadImageForID:self.illustID url:url];
				}
			}
		} else {
			if ([[self smallCache] conteinsImageForKey:self.illustID]) {
				cell.mediumImageView.image = [[self smallCache] imageForKey:self.illustID];
			} else {
				cell.mediumImageView.image = nil;
			}

			if (![cell.activityView isAnimating]) {
				[cell.activityView startAnimating];
			}
			cell.progressView.hidden = YES;
		}
		
		cell.accessoryType = UITableViewCellAccessoryNone;
		cell.selectionStyle = UITableViewCellSelectionStyleNone;		
		return cell;
	} else if ([self hasLink] && indexPath.section == 1 && ((![info_ objectForKey:@"Title"] && indexPath.row == 0) || (![info_ objectForKey:@"UserName"] && indexPath.row == 1) || ([info_ objectForKey:@"UserName"] && indexPath.row == 2))) {
		UITableViewCell *cell = [self defaultCell:tableView];

		if ([[info_ objectForKey:@"PhotoType"] isEqual:@"Pixiv"]) {
			cell.textLabel.text = @"pixiv";
		} else if ([[info_ objectForKey:@"PhotoType"] isEqual:@"Pixa"]) {
			cell.textLabel.text = @"PiXA";
		} else if ([[info_ objectForKey:@"PhotoType"] isEqual:@"Tinami"]) {
			cell.textLabel.text = @"TINAMI";
		}

		cell.textLabel.numberOfLines = 1;
		cell.textLabel.font = [UIFont systemFontOfSize:14];
		cell.textLabel.textColor = [UIColor whiteColor];
		cell.accessoryView = [[[UIImageView alloc] initWithImage:whiteIndicator] autorelease];
		cell.selectionStyle = UITableViewCellSelectionStyleBlue;
		return cell;
	} else if (indexPath.section == 1) {
		MediumViewLabelCell *cell = [self labelCell:tableView];
		
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		cell.accessoryView = nil;
		switch (indexPath.row) {
		case 0:
			cell.labelLabel.text = @"タイトル:";
			cell.descLabel.text = [info_ objectForKey:@"Title"] ? [info_ objectForKey:@"Title"] : @"不明";
			if ([[info_ objectForKey:@"ContentType"] isEqual:@"novel"]) {
				cell.accessoryView = [[[UIImageView alloc] initWithImage:whiteIndicator] autorelease];
				cell.selectionStyle = UITableViewCellSelectionStyleBlue;
			} else {
				cell.accessoryView = nil;			
			}
			break;
		case 1:
			if ([self isKindOfClass:[TumblrMediumViewController class]]) {
				cell.labelLabel.text = @"Tumblog:";
				cell.descLabel.text = [NSString stringWithFormat:@"%@.tumblr.com", [info_ objectForKey:@"UserName"]];
			} else {
				cell.labelLabel.text = @"作者:";
				cell.descLabel.text = [info_ objectForKey:@"UserName"] ? [info_ objectForKey:@"UserName"] : @"";
			}
			cell.selectionStyle = UITableViewCellSelectionStyleBlue;
			cell.accessoryView = [[[UIImageView alloc] initWithImage:whiteIndicator] autorelease];
			break;
		case 2:
			cell.labelLabel.text = @"コメント:";
			cell.descLabel.text = [info_ objectForKey:@"Comment"] ? [info_ objectForKey:@"Comment"] : @"";
			break;
		case 3:
			if ([info_ objectForKey:@"RatingViewCount"]) {
				cell.labelLabel.text = NSLocalizedString(@"RatingViewCount", nil);
				cell.descLabel.text = [info_ objectForKey:@"RatingViewCount"] ? [[info_ objectForKey:@"RatingViewCount"] stringValue] : @"";
			} else if ([info_ objectForKey:@"RatingString"]) {
				cell.labelLabel.text = @"評価";
				cell.descLabel.text = [[info_ objectForKey:@"RatingString"] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
			} else if ([info_ objectForKey:@"total_view"]) {
				cell.labelLabel.text = NSLocalizedString(@"total_view", nil);
				cell.descLabel.text = [info_ objectForKey:@"total_view"] ? [[info_ objectForKey:@"total_view"] stringValue] : @"";
			}
			break;
		case 4:
			if ([info_ objectForKey:@"RatingCount"]) {
				cell.labelLabel.text = NSLocalizedString(@"RatingCount", nil);
				cell.descLabel.text = [info_ objectForKey:@"RatingCount"] ? [[info_ objectForKey:@"RatingCount"] stringValue] : @"";
			} else if ([info_ objectForKey:@"user_view"]) {
				cell.labelLabel.text = NSLocalizedString(@"user_view", nil);
				cell.descLabel.text = [info_ objectForKey:@"user_view"] ? [[info_ objectForKey:@"user_view"] stringValue] : @"";
			}
			break;
		case 5:
			if ([info_ objectForKey:@"RatingScore"]) {
				cell.labelLabel.text = NSLocalizedString(@"RatingScore", nil);
				cell.descLabel.text = [info_ objectForKey:@"RatingScore"] ? [[info_ objectForKey:@"RatingScore"] stringValue] : @"";
			} else if ([info_ objectForKey:@"valuation"]) {
				cell.labelLabel.text = NSLocalizedString(@"valuation", nil);
				cell.descLabel.text = [info_ objectForKey:@"valuation"] ? [[info_ objectForKey:@"valuation"] stringValue] : @"";
			}
			break;
		}
		
		return cell;
	} else if (indexPath.section == 2) {
		UITableViewCell *cell = [self defaultCell:tableView];
		id tag = [[info_ objectForKey:@"Tags"] objectAtIndex:indexPath.row];
		if ([tag isKindOfClass:[NSDictionary class]]) {
			tag = [tag objectForKey:@"Name"];
		}
		CGRect r = cell.textLabel.frame;
		r.size.width = self.view.frame.size.width - 20;
		cell.textLabel.frame = r;
		cell.textLabel.text = tag;
		cell.textLabel.numberOfLines = 0;
		cell.textLabel.font = [UIFont systemFontOfSize:14];
		cell.textLabel.textColor = [UIColor whiteColor];
		cell.accessoryView = [[[UIImageView alloc] initWithImage:whiteIndicator] autorelease];
		cell.selectionStyle = UITableViewCellSelectionStyleBlue;
		return cell;
	} else if (indexPath.section == 3) {
		MediumViewCommentCell *cell = [self commentCell:tableView];
		NSDictionary *com = [[info_ objectForKey:@"OneComments"] objectAtIndex:indexPath.row];
		cell.nameLabel.text = [com objectForKey:@"UserName"];
		cell.dateLabel.text = [com objectForKey:@"DateString"];
		cell.commentLabel.text = [com objectForKey:@"Comment"];
		cell.commentLabel.numberOfLines = 0;
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		return cell;
	} else {
		return nil;
	}
	 */
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	if (progressShowing_) {
		return;
	}
	
	NSString *key = [[tableRows objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
	if ([key isEqual:@"UserName"]) {
		[self showUserIllust];
	} else if ([key isEqual:@"Title"] && [[info_ objectForKey:@"ContentType"] isEqual:@"novel"]) {
		[self imageButtonAction:nil];
	} else if ([key isEqual:@"Image"]) {
		[self imageButtonAction:nil];
	} else if ([key isEqual:@"Tags"]) {
		id tag = [[info_ objectForKey:@"Tags"] objectAtIndex:indexPath.row];
		if ([tag isKindOfClass:[NSDictionary class]]) {
			tag = [tag objectForKey:@"Name"];
		}
		
		UIButton *btn = [[[UIButton alloc] init] autorelease];
		[btn setTitle:tag forState:UIControlStateNormal];
		btn.tag = indexPath.row;
		[self tagButtonAction:btn];
	} else if ([key isEqual:@"PhotoType"]) {
		[self photoLinkAction:nil];
	}
	
	
	/*
	if ([self hasLink] && indexPath.section == 1 && ((![info_ objectForKey:@"Title"] && indexPath.row == 0) || (![info_ objectForKey:@"UserName"] && indexPath.row == 1) || ([info_ objectForKey:@"UserName"] && indexPath.row == 2))) {
		[self photoLinkAction:nil];
	} else if (indexPath.section == 1 && indexPath.row == 1) {
		[self showUserIllust];
	} else if (indexPath.section == 1 && indexPath.row == 0 && [[info_ objectForKey:@"ContentType"] isEqual:@"novel"]) {
		[self imageButtonAction:nil];
	} else if (indexPath.section == 0) {
		//MediumViewImageCell *cell = (MediumViewImageCell *)[tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
		[self imageButtonAction:nil];
	} else if (indexPath.section == 2) {
		id tag = [[info_ objectForKey:@"Tags"] objectAtIndex:indexPath.row];
		if ([tag isKindOfClass:[NSDictionary class]]) {
			tag = [tag objectForKey:@"Name"];
		}
		
		UIButton *btn = [[[UIButton alloc] init] autorelease];
		[btn setTitle:tag forState:UIControlStateNormal];
		btn.tag = indexPath.row;
		[self tagButtonAction:btn];
	}
	 */
}

- (void) ugoIllustLoaded:(id)sender error:(NSError *)err {
	if (sender == self.ugoIllust) {
		if (err) {
			UIAlertView	*alert = [[UIAlertView alloc] initWithTitle:@"読み込みに失敗しました" message:[err localizedDescription] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
			[alert show];
			[alert release];
		} else {
			self.ugoIllustPlayer = [[PixivUgoIllustPlayer alloc] initWithUgoIllust:self.ugoIllust];
			self.ugoIllustPlayer.delegate = (id<PixivUgoIllustPlayerDelegate>)self;
		}
		[self.tableView reloadData];
		[self updateToolbar];
	}
}

- (void) frameChanged:(id)sender image:(UIImage *)image {
	imageCell.mediumImageView.image = image;
}

#pragma mark-

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
	if (scrollView != self.scrollView) {
		return;
	}
	
	DLog(@"%f", scrollView.contentOffset.x);
	if (scrollView.contentOffset.x < -20) {
		if ([self prevIID]) {
			[self prev];
		}
	} else if (scrollView.contentOffset.x > 20) {
		if ([self nextIID]) {
			[self next];
		}
	}
}

#pragma mark-

- (NSMutableDictionary *) storeInfo {
	NSMutableDictionary *info = [super storeInfo];
	
	[info setObject:[account info] forKey:@"Account"];
	[info setObject:illustID forKey:@"IllustID"];

	return info;
}

- (BOOL) needsStore {
	return YES;
}

- (BOOL) restore:(NSDictionary *)info {
	id obj;
	
	obj = [info objectForKey:@"IllustID"];
	if (obj == nil) {
		return NO;
	}
	self.illustID = obj;

	obj = [info objectForKey:@"Account"];
	PixAccount *acc = [[AccountManager sharedInstance] accountWithInfo:obj];
	if (acc == nil) {
		return NO;
	}	
	self.account = acc;

	return YES;
}

@end


static void drawDisclosureIndicator(CGContextRef ctxt, CGFloat x, CGFloat y) {
    static const CGFloat R = 4.5; // "radius" of the arrow head
    static const CGFloat W = 2; // line width
    CGContextSaveGState(ctxt);
    CGContextMoveToPoint(ctxt, x-R, y-R);
    CGContextAddLineToPoint(ctxt, x, y);
    CGContextAddLineToPoint(ctxt, x-R, y+R);
    CGContextSetLineCap(ctxt, kCGLineCapSquare);
    CGContextSetLineJoin(ctxt, kCGLineJoinMiter);
    CGContextSetLineWidth(ctxt, W);
    CGContextStrokePath(ctxt);
    CGContextRestoreGState(ctxt);
}

static UIImage *whiteDisclosureIndicatorImage() {
	return [UIImage imageNamed:@"disclosure.png"];

	UIGraphicsBeginImageContext(CGSizeMake(10, 10));
	[[UIColor whiteColor] set];
	drawDisclosureIndicator(UIGraphicsGetCurrentContext(), 5, 5);
	UIImage *ret = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return ret;
}