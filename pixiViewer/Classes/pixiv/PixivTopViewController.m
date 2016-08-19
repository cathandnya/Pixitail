//
//  PixivTopViewController.m
//  pixiViewer
//
//  Created by nya on 10/02/11.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PixivTopViewController.h"
#import "PixivMatrixViewController.h"
#import "PixivSearchViewController.h"
#import "PixivSearchHistoryViewController.h"
#import "PixivTagListController.h"
#import "PixivUserListViewController.h"
#import "PixListThumbnail.h"
#import "Pixiv.h"
#import "Pixa.h"
#import "AccountManager.h"
#import "AdmobHeaderView.h"
#import "PixivUserSearchViewController.h"
#import "PixitailConstants.h"
#import "PixiViewerAppDelegate.h"


static BOOL enabledR18() {
	return [[NSUserDefaults standardUserDefaults] boolForKey:@"R18IsEnabled"];
}

static int pixivItemCount() {
	if (enabledR18()) {
		return 17 + 3 - 1;
	} else {
		return 17 - 1;
	}
}

// xxx 重複
NSString *tagMethodWithTag(NSString *tag) {
	if (!tag) {
		return nil;
	}

	NSData				*data = [tag dataUsingEncoding:NSUTF8StringEncoding];
	NSMutableString		*method = [NSMutableString stringWithString:@"tags.php?tag="];
	int					i;
	
	for (i = 0; i < [data length]; i++) {
		[method appendFormat:@"%%%02X", ((unsigned char *)[data bytes])[i]];
	}
	[method appendString:@"&"];
	
	return method;
}

static NSString *searchHistoryMethod() {
	NSArray *ary = [[NSUserDefaults standardUserDefaults] objectForKey:@"SerchHistory"];
	if ([ary count] > 0) {
		NSDictionary *info = [ary objectAtIndex:0];
		return [NSString stringWithFormat:@"search.php?word=%@&s_mode=%@&", encodeURIComponent([info objectForKey:@"Term"]), [info objectForKey:@"Scope"]];
	}
	return nil;
}

static NSString *pixivMethodAtIndex(int i) {
	switch (i) {
	case 0:
		return @"member_illust.php?";					// 自分
	case 1:
		return @"mypixiv_all.php?";						// マイピク一覧
	case 2:
		return @"mypixiv_new_illust.php?";				// マイピク新着
	case 3:
		return @"bookmark.php?type=user&";				// お気に入りユーザ一覧
	case 4:
		return @"bookmark_new_illust.php?";				// お気に入りユーザ新着
	case 5:
		return @"bookmark.php?type=user&rest=hide&";	// お気に入りユーザ(非公開)一覧
	case 6:
		return @"bookmark.php?";						// ブックマーク
	case 7:
		return @"bookmark.php?rest=hide&";				// ブックマーク(非公開)
	case 8:
	{
		NSArray	*ary = [[NSUserDefaults standardUserDefaults] objectForKey:@"SavedTags"];
		return [ary count] > 0 ? tagMethodWithTag([ary objectAtIndex:0]) : nil;										// タグ
	}
	case 9:
		return @"new_illust.php?";						// みんなの新着
	case 10:
		return @"ranking.php?mode=dayly&";				// デイリーランキング
	case 11:
		return @"ranking.php?mode=weekly&";				// ウィークリーランキング
	case 12:
		return @"ranking.php?mode=monthly&";				// マンスリーランキング
	case 13:
		return @"ranking.php?mode=rookie&";					// ルーキーランキング
	case 14:
		return @"search.php?";							// 検索
	case 15:
		return searchHistoryMethod();					// 検索履歴
	//case 16:
	//	return @"search_user.php?";						// ユーザ検索
	case 16:
		return @"new_illust_r18.php?";					// みんなのR-18新着
	case 17:
		return @"ranking.php?mode=daily_r18&";			// R-18デイリーランキング
	case 18:
		return @"ranking.php?mode=weekly_r18&";			// R-18ウィークリーランキング
	default:
		assert(0);
		return nil;
	}
}

static NSString *pixivNameAtIndex(int i) {
	switch (i) {
	case 0:
		return NSLocalizedString(@"My illust", nil);			// 自分
	case 1:
		return NSLocalizedString(@"My pixiv list", nil);		// マイピク一覧
	case 2:
		return NSLocalizedString(@"My pixiv", nil);				// マイピク新着
	case 3:
		return NSLocalizedString(@"Favorite list", nil);		// お気に入りユーザ一覧
	case 4:
		return NSLocalizedString(@"Favorite", nil);				// お気に入りユーザ新着
	case 5:
		return NSLocalizedString(@"Favorite(Hidden) list", nil);// お気に入りユーザ(非公開)一覧
	case 6:
		return NSLocalizedString(@"Bookmarks", nil);			// ブックマーク
	case 7:
		return NSLocalizedString(@"Bookmarks(Hidden)", nil);	// ブックマーク(非公開)
	case 8:
		return NSLocalizedString(@"SavedTags", nil);			// タグ
	case 9:
		return NSLocalizedString(@"New entry", nil);			// みんなの新着
	case 10:
		return NSLocalizedString(@"Ranking", nil);				// デイリーランキング
	case 11:
		return NSLocalizedString(@"WeeklyRanking", nil);		// ウィークリーランキング
	case 12:
		return NSLocalizedString(@"MonthlyRanking", nil);		// マンスリーランキング
	case 13:
		return @"ルーキーランキング";								// ルーキーランキング
	case 14:
		return NSLocalizedString(@"Search", nil);				// 検索
	case 15:
		return NSLocalizedString(@"SearchHistory", nil);		// 検索履歴
	//case 16:
	//	return @"ユーザ検索";			// ユーザ検索
	case 16:
		return [NSString stringWithFormat:@"R-18%@", NSLocalizedString(@"New entry", nil)];			// R-18みんなの新着
	case 17:
		return [NSString stringWithFormat:@"R-18%@", NSLocalizedString(@"Ranking", nil)];				// R-18デイリーランキング
	case 18:
		return [NSString stringWithFormat:@"R-18%@", NSLocalizedString(@"WeeklyRanking", nil)];			// R-18ウィークリーランキング
	default:
		assert(0);
		return nil;
	}
}

@implementation PixivTopViewController

@synthesize account;

- (PixService *) pixiv {
	return [Pixiv sharedInstance];
}

- (NSInteger) count {
	return pixivItemCount();
}

- (NSString *) methodAtIndex:(int)i {
	return pixivMethodAtIndex(i);
}

- (NSString *) nameAtIndex:(int)i {
	return pixivNameAtIndex(i);
}

#pragma mark-

/*
- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if (self = [super initWithStyle:style]) {
    }
    return self;
}
*/

- (void)dealloc {
	[account release];
	
    [super dealloc];
}

- (void)setup {
	if (![[self pixiv].username isEqual:account.username] || ![[self pixiv].password isEqual:account.password]) {
		[self pixiv].username = account.username;
		[self pixiv].password = account.password;
		[self pixiv].logined = NO;
	}	
}

- (void)viewDidLoad {
    [super viewDidLoad];

	[self setup];
	
	self.tableView.rowHeight = 44;

	self.title = NSLocalizedString(account.typeString, nil);
	//[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:NO];
	//self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
	//self.navigationController.toolbar.barStyle = UIBarStyleBlackTranslucent;
		
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DisableAd"] == NO) {
		UIViewController *adroot;
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			adroot = (UIViewController *)((PixiViewerAppDelegate *)[UIApplication sharedApplication].delegate).alwaysSplitViewController;
		} else {
			adroot = self;
		}
		
		UIView *header = [[[AdmobHeaderView alloc] initWithViewController:adroot] autorelease];
		CGRect r = header.frame;
		r.size.width = self.view.frame.size.width;
		header.frame = r;
		self.tableView.tableHeaderView = header;//[[[AdmobHeaderBGView alloc] init] autorelease];
	}
	
	[[NSUserDefaults standardUserDefaults] setObject:[account info] forKey:@"LastAccount"];
	[[NSUserDefaults standardUserDefaults] synchronize];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginFinished:) name:@"LoginFinishedNotification" object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DisableAd"]) {
		self.tableView.tableHeaderView = nil;
	}
	
    [super viewWillAppear:animated];

	[self.navigationController setToolbarHidden:YES animated:YES];
	//[self.navigationController setNavigationBarHidden:YES animated:NO];
	[self.navigationController setNavigationBarHidden:NO animated:NO];

	[self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
	//[[AdmobHeaderView sharedInstance] removeFromSuperview];

	[super viewWillDisappear:animated];
}

/*
- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}
*/

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super viewDidUnload];
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

- (void) loginFinished:(NSNotification *)notif {
	[self.tableView reloadData];
}

#pragma mark-

- (void) progressCancel:(ProgressViewController *)sender {
	//[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:nil];

	[[self pixiv] loginCancel];
	[self.navigationController popViewControllerAnimated:YES];
	
	[self hideProgress];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
	if (alertView.tag == 100) {
		[self.navigationController popViewControllerAnimated:YES];
	}
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return [[[PixitailConstants sharedInstance] valueForKeyPath:@"menu"] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	NSDictionary *dic = [[[PixitailConstants sharedInstance] valueForKeyPath:@"menu"] objectAtIndex:section];
	return [[dic objectForKey:@"rows"] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (section == 0) {
		return self.account.username;
	} else {
		NSDictionary *dic = [[[PixitailConstants sharedInstance] valueForKeyPath:@"menu"] objectAtIndex:section];
		return [dic objectForKey:@"title"];
	}
}

- (NSUInteger) indexForIndexPath:(NSIndexPath *)path {
	NSUInteger idx = 0;
	
	for (NSUInteger i = 0; i < path.section; i++) {
		idx += [self tableView:self.tableView numberOfRowsInSection:i];
	}
	idx += path.row;
	
	return idx;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
	UIImage			*img = nil;
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
	
	NSDictionary *sec = [[[PixitailConstants sharedInstance] valueForKeyPath:@"menu"] objectAtIndex:indexPath.section];
	NSDictionary *row = [[sec objectForKey:@"rows"] objectAtIndex:indexPath.row];
	
	cell.textLabel.numberOfLines = 2;
	cell.textLabel.lineBreakMode = UILineBreakModeCharacterWrap;
	cell.textLabel.font = [cell.textLabel.font fontWithSize:16];
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
	cell.textLabel.text = [row objectForKey:@"name"];
	
	NSString *method = [row objectForKey:@"method"];
	if ([method isEqual:@"search_history"]) {
		method = searchHistoryMethod();
	} else if ([method isEqual:@"saved_tags"]) {
		NSArray	*ary = [[NSUserDefaults standardUserDefaults] objectForKey:@"SavedTags"];
		method = ([ary count] > 0 ? tagMethodWithTag([ary objectAtIndex:0]) : nil);										// タグ
	}
	img = [self.account.thumbnail imageWithMethod:method];
	cell.imageView.contentMode = UIViewContentModeScaleToFill;
	cell.imageView.image = img;
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	UIViewController		*controller = nil;

	NSDictionary *sec = [[[PixitailConstants sharedInstance] valueForKeyPath:@"menu"] objectAtIndex:indexPath.section];
	NSDictionary *row = [[sec objectForKey:@"rows"] objectAtIndex:indexPath.row];
	
	PixivMatrixViewController	*pixiv = nil;
	NSString *className = [row objectForKey:@"class"];
	if (className) {
		NSString *nibName = nil;
		if (![[row objectForKey:@"no_nib"] boolValue]) {
			nibName = [row objectForKey:@"nib"];
			if (!nibName) {
				nibName = className;
			}
		}
		if (nibName) {
			pixiv = [[[NSClassFromString(className) alloc] initWithNibName:nibName bundle:nil] autorelease];
		} else {
			pixiv = [[[NSClassFromString(className) alloc] init] autorelease];
		}
	} else {
		pixiv = [[[PixivMatrixViewController alloc] init] autorelease];
	}
	if ([pixiv respondsToSelector:@selector(setMethod:)]) {
		[pixiv performSelector:@selector(setMethod:) withObject:[row objectForKey:@"method"]];
	}
	if ([pixiv respondsToSelector:@selector(setScrapingInfoKey:)]) {
		[pixiv performSelector:@selector(setScrapingInfoKey:) withObject:[row objectForKey:@"parser"]];
	}
	
	if ([pixiv isKindOfClass:[UIViewController class]]) {
		pixiv.navigationItem.title = [row objectForKey:@"name"];
		controller = pixiv;
	}
	pixiv.account = self.account;

	if (controller) {
		[self.navigationController pushViewController:controller animated:YES];
	}
}

#pragma mark-

- (NSMutableDictionary *) storeInfo {
	NSMutableDictionary *info = [super storeInfo];
	
	[info setObject:[account info] forKey:@"Account"];

	return info;
}

- (BOOL) needsStore {
	return YES;
}

- (BOOL) restore:(NSDictionary *)info {
	id obj;
	
	obj = [info objectForKey:@"Account"];
	PixAccount *acc = [[AccountManager sharedInstance] accountWithInfo:obj];
	if (acc == nil) {
		return NO;
	}	
	self.account = acc;

	return YES;
}

@end

