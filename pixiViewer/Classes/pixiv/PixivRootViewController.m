//
//  PixivRootViewController.m
//  pixiViewer
//
//  Created by nya on 09/08/22.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PixivRootViewController.h"
#import "PixivMatrixViewController.h"
#import "PixivSearchViewController.h"
#import "PixivTagListController.h"
#import "PixivUserListViewController.h"
#import "Pixiv.h"
#import "Pixa.h"
#import "PixaMatrixViewController.h"
#import "PixaSearchViewController.h"
//#import "URLCache.h"
#import "ApplicationInformationViewController.h"
#import "ApplicationSupportViewController.h"
#import "PixListThumbnail.h"
#import "PixivSearchHistoryViewController.h"
#import "Tumblr.h"
#import "TumblrMatrixViewController.h"


static BOOL enabledR18() {
	return [[NSUserDefaults standardUserDefaults] boolForKey:@"R18IsEnabled"];
}

static BOOL enablePixiv() {
	return [[Pixiv sharedInstance].username length] > 0 && [[Pixiv sharedInstance].password length] > 0;
}

static BOOL enablePixa() {
	return [[Pixa sharedInstance].username length] > 0 && [[Pixa sharedInstance].password length] > 0;
}

static BOOL enableTumblr() {
	return [Tumblr sharedInstance].available;
}

static int pixivItemCount() {
	if (enabledR18()) {
		return 15 + 3;
	} else {
		return 15;
	}
}

// xxx 重複
static NSString *tagMethodWithTag(NSString *tag) {
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
		return [NSString stringWithFormat:@"search.php?word=%@&s_mode=%@&", [[info objectForKey:@"Term"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], [info objectForKey:@"Scope"]];
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
		return @"new_illust.php?";						// みんなの新着
	case 9:
		return @"ranking.php?mode=day&";				// デイリーランキング
	case 10:
		return @"ranking.php?mode=week&";				// ウィークリーランキング
	case 11:
		return @"ranking.php?mode=month&";				// マンスリーランキング
	case 12:
		return @"search.php?";							// 検索
	case 13:
		return searchHistoryMethod();					// 検索履歴
	case 14:
	{
		NSArray	*ary = [[NSUserDefaults standardUserDefaults] objectForKey:@"SavedTags"];
		return [ary count] > 0 ? tagMethodWithTag([ary objectAtIndex:0]) : nil;										// タグ
	}
	case 15:
		return @"new_illust_r18.php?";					// みんなのR-18新着
	case 16:
		return @"ranking_r18.php?mode=day&";			// R-18デイリーランキング
	case 17:
		return @"ranking_r18.php?mode=week&";			// R-18ウィークリーランキング
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
		return NSLocalizedString(@"New entry", nil);			// みんなの新着
	case 9:
		return NSLocalizedString(@"Ranking", nil);				// デイリーランキング
	case 10:
		return NSLocalizedString(@"WeeklyRanking", nil);		// ウィークリーランキング
	case 11:
		return NSLocalizedString(@"MonthlyRanking", nil);		// マンスリーランキング
	case 12:
		return NSLocalizedString(@"Search", nil);				// 検索
	case 13:
		return NSLocalizedString(@"SearchHistory", nil);		// 検索履歴
	case 14:
		return NSLocalizedString(@"SavedTags", nil);			// タグ
	case 15:
		return [NSString stringWithFormat:@"R-18%@", NSLocalizedString(@"New entry", nil)];			// R-18みんなの新着
	case 16:
		return [NSString stringWithFormat:@"R-18%@", NSLocalizedString(@"Ranking", nil)];				// R-18デイリーランキング
	case 17:
		return [NSString stringWithFormat:@"R-18%@", NSLocalizedString(@"WeeklyRanking", nil)];			// R-18ウィークリーランキング
	default:
		assert(0);
		return nil;
	}
}

static id createPixivNavigationControllerAtIndex(int i) {
	switch (i) {
	default:
	{
		PixivMatrixViewController *tmp = [[PixivMatrixViewController alloc] initWithNibName:@"PixivMatrixViewController" bundle:nil];
		tmp.method = pixivMethodAtIndex(i);
		return tmp;
	}
	case 12:
	{
		PixivMatrixViewController *tmp = [[PixivSearchViewController alloc] initWithNibName:@"PixivSearchController" bundle:nil];
		tmp.method = pixivMethodAtIndex(i);
		return tmp;
	}
	case 13:
		return [[PixivSearchHistoryViewController alloc] init];
	case 14:
		return [[PixivTagListController alloc] initWithNibName:@"PixivTagListController" bundle:nil];
	case 1:
	case 3:
	case 5:
	{
		PixivUserListViewController *tmp = [[PixivUserListViewController alloc] initWithNibName:@"PixivUserListViewController" bundle:nil];
		tmp.method = pixivMethodAtIndex(i);
		return tmp;
	}
	}
}

static int pixaItemCount() {
	return 7;
}

static NSString *pixaMethodAtIndex(int i) {
	switch (i) {
	case 0:
		return @"illustrations/list_follows?";							// フォロー
	case 1:
		return @"collections/show?";									// コレクション
	case 2:
		return @"illustrations/list_main?";								// 新着
	case 3:
		return @"illustrations/list_ranking?mode=daily&";				// デイリーランキング
	case 4:
		return @"illustrations/list_ranking?mode=weekly&";				// ウィークリーランキング
	case 5:
		return @"illustrations/list_ranking?mode=monthly&";				// マンスリーランキング
	case 6:
		return @"search/search?";										// 検索
	default:
		assert(0);
		return nil;
	}
}

static NSString *pixaNameAtIndex(int i) {
	switch (i) {
	case 0:
		return NSLocalizedString(@"NewFollows", nil);			// フォロー
	case 1:
		return NSLocalizedString(@"Collection", nil);			// コレクション
	case 2:
		return NSLocalizedString(@"PixaNew", nil);				// 新着
	case 3:
		return NSLocalizedString(@"Ranking", nil);				// デイリーランキング
	case 4:
		return NSLocalizedString(@"WeeklyRanking", nil);		// ウィークリーランキング
	case 5:
		return NSLocalizedString(@"MonthlyRanking", nil);		// マンスリーランキング
	case 6:
		return NSLocalizedString(@"Search", nil);				// 検索
	default:
		assert(0);
		return nil;
	}
}

static int otherItemCount() {
	return 2;
}

static NSString *otherNameAtIndex(int i) {
	switch (i) {
	case 0:
		return NSLocalizedString(@"Application information", nil);		// 情報
	case 1:
		return NSLocalizedString(@"Application support", nil);			// サポート
	default:
		assert(0);
		return nil;
	}
}


@interface PixivRootViewController(Private)
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
@end


@implementation PixivRootViewController

@synthesize account;

- (void)dealloc {
	[self viewDidUnload];
	[account release];
	
    [super dealloc];
}

- (void)viewDidLoad {	
	[PixListThumbnail sharedInstance];

	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent animated:NO];
	
	self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
	self.navigationController.navigationBar.translucent = YES;
	self.navigationController.toolbar.barStyle = UIBarStyleBlackTranslucent;
	
    [super viewDidLoad];
}

/*
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
*/
/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/
/*
- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
}
*/
/*
- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}
*/

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
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidAppear:(BOOL)animated {
	[self.navigationController setToolbarHidden:YES animated:NO];
	[((UITableView *)self.view) reloadData];
	
	[self.navigationController setNavigationBarHidden:YES animated:NO];
	[self.navigationController setNavigationBarHidden:NO animated:NO];
}


#pragma mark Table view methods

static int serviceForSection(int section) {
	if (section == 0) {
		if (enablePixiv()) {
			return 0;
		} else if (!enablePixiv() && enablePixa()) {
			return 1;
		} else if (!enablePixiv() && !enablePixa() && enableTumblr()) {
			return 2;
		} else {
			return 100;
		}
	} else if (section == 1) {
		if (enablePixiv() && enablePixa()) {
			return 1;
		} else if (enablePixiv() && !enablePixa() && enableTumblr()) {
			return 2;
		} else if (!enablePixiv() && enablePixa() && enableTumblr()) {
			return 2;
		} else {
			return 100;
		}
	} else if (section == 2) {
		if (enablePixiv() && enablePixa() && enableTumblr()) {
			return 2;
		} else {
			return 100;
		}
	} else {
		return 100;
	}
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	NSInteger ret = 1;
	
	if (enablePixiv()) {
		ret++;
	}
	if (enablePixa()) {
		ret++;
	}
	if (enableTumblr()) {
		ret++;
	}

	return ret;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	switch (serviceForSection(section)) {
	case 0:
		return @"pixiv";
	case 1:
		return @"PiXA";
	case 2:
		return @"Tumblr";
	default:
		return NSLocalizedString(@"Other", nil);
	}
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	switch (serviceForSection(section)) {
	case 0:
		return pixivItemCount();
	case 1:
		return pixaItemCount();
	case 2:
		return 1;
	default:
		return otherItemCount();
	}
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
	UIImage			*img = nil;
	int				service = serviceForSection(indexPath.section);
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
	
	cell.textLabel.numberOfLines = 2;
	cell.textLabel.lineBreakMode = UILineBreakModeCharacterWrap;
	cell.textLabel.font = [cell.textLabel.font fontWithSize:16];
	if (service == 0) {
		cell.textLabel.text = pixivNameAtIndex(indexPath.row);
		img = [[PixListThumbnail sharedInstance] imageWithMethod:pixivMethodAtIndex(indexPath.row)];
	
		cell.imageView.contentMode = UIViewContentModeScaleToFill;
		cell.imageView.image = img;
	} else if (service == 1) {
		cell.textLabel.text = pixaNameAtIndex(indexPath.row);
		img = [[PixListThumbnail sharedInstance] imageWithMethod:pixaMethodAtIndex(indexPath.row)];
	
		cell.imageView.contentMode = UIViewContentModeScaleToFill;
		cell.imageView.image = img;
    } else if (service == 2) {
		cell.textLabel.text = @"Dashboard";
		img = [[PixListThumbnail sharedInstance] imageWithMethod:@"Tumblr_Dashboard"];
		
		cell.imageView.contentMode = UIViewContentModeScaleToFill;
		cell.imageView.image = img;
    } else {
		cell.textLabel.text = otherNameAtIndex(indexPath.row);
		cell.imageView.image = nil;
	}
	
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	return cell;
}


- (void)actionSheet:(UIActionSheet *)sheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:nil];

	if (buttonIndex == 0) {
		// キャンセル
		[[Pixiv sharedInstance] loginCancel];
		[[Pixa sharedInstance] loginCancel];
		[(UITableView *)self.view deselectRowAtIndexPath:[(UITableView *)self.view indexPathForSelectedRow] animated:NO];
	}
	
	[actionSheet_ release];
	actionSheet_ = nil;
	[selectedIndex_ release];
	selectedIndex_ = nil;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	UIViewController		*controller = nil;
	int						service = serviceForSection(indexPath.section);
	
	if (actionSheet_) {
		[actionSheet_ dismissWithClickedButtonIndex:0 animated:YES];
		[actionSheet_ release];
		actionSheet_ = nil;
	}
	
	if (service == 0) {
		PixivMatrixViewController	*pixiv = nil;
	
		// login
		if (![[Pixiv sharedInstance] logined]) {
			long err = [[Pixiv sharedInstance] login:self];
			if (err) {
				UIAlertView	*alert = nil;
				if (err == -1) {
					// ログイン失敗
					alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Login faied.", nil) message:NSLocalizedString(@"Please confirm your account.", nil) delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];				
				} else if (err == -2) {
					// 通信不可
					alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Connection faied.", nil) message:NSLocalizedString(@"Network is not connected.", nil) delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];				
				} else if (err != 0) {
					// その他
					alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Connection faied.", nil) message:NSLocalizedString(@"", nil) delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];				
				}
				[alert show];
				[alert release];

				[tableView deselectRowAtIndexPath:indexPath animated:NO];
				return;
			}
			[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorStartNotification" object:nil];

			[selectedIndex_ release];
			selectedIndex_ = [indexPath retain];

			UIActionSheet	*alert = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Now login...", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:nil];
			[alert showInView:self.view];
			actionSheet_ = alert;
			return;
		}
		
		pixiv = createPixivNavigationControllerAtIndex(indexPath.row);
		if ([pixiv isKindOfClass:[UIViewController class]]) {
			pixiv.navigationItem.title = pixivNameAtIndex(indexPath.row);
	
			controller = pixiv;
		}
	} else if (service == 1) {
		PixaMatrixViewController	*pixa = nil;
	
		// login
		if (![[Pixa sharedInstance] logined]) {
			long err = [[Pixa sharedInstance] login:self];
			if (err) {
				UIAlertView	*alert = nil;
				if (err == -1) {
					// ログイン失敗
					alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Login faied.", nil) message:NSLocalizedString(@"Please confirm your account.", nil) delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];				
				} else if (err == -2) {
					// 通信不可
					alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Connection faied.", nil) message:NSLocalizedString(@"Network is not connected.", nil) delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];				
				} else if (err != 0) {
					// その他
					alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Connection faied.", nil) message:NSLocalizedString(@"", nil) delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];				
				}
				[alert show];
				[alert release];

				[tableView deselectRowAtIndexPath:indexPath animated:NO];
				return;
			}
			[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorStartNotification" object:nil];

			[selectedIndex_ release];
			selectedIndex_ = [indexPath retain];

			UIActionSheet	*alert = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Now login...", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:nil];
			[alert showInView:self.view];
			actionSheet_ = alert;
			return;
		}
			
		if (indexPath.row == 6) {
			pixa = [[PixaSearchViewController alloc] initWithNibName:@"PixivSearchController" bundle:nil];
		} else {
			pixa = [[PixaMatrixViewController alloc] initWithNibName:@"PixivMatrixViewController" bundle:nil];
		}
		
		if (pixa) {
			pixa.method = pixaMethodAtIndex(indexPath.row);
			pixa.navigationItem.title = pixaNameAtIndex(indexPath.row);
			
			controller = pixa;
		}
    } else if (service == 2) {
		TumblrMatrixViewController *tmp = [[TumblrMatrixViewController alloc] initWithNibName:@"PixivMatrixViewController" bundle:nil];
		tmp.title = @"Dashboard";
		tmp.method = @"Tumblr_Dashboard";
		controller = tmp;
    } else {
		switch (indexPath.row) {
		case 0:
			controller = [[ApplicationInformationViewController alloc] initWithNibName:@"ApplicationInformationViewController" bundle:nil];
			break;
		case 1:
			controller = [[ApplicationSupportViewController alloc] initWithNibName:@"ApplicationSupportViewController" bundle:nil];
			break;
		default:
			break;
		}
	}
	
	if (controller) {
		[self.navigationController pushViewController:controller animated:YES];
		[controller release];
	}
}


/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/


/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/


/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/


/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

- (void) pixService:(PixService *)sender loginFinished:(long)err {
	if (actionSheet_) {
		[actionSheet_ dismissWithClickedButtonIndex:0 animated:YES];
		[actionSheet_ release];
		actionSheet_ = nil;
	}

	if (err) {
		UIAlertView	*alert = nil;
		if (err == -1) {
			// ログイン失敗
			alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Login faied.", nil) message:NSLocalizedString(@"Please confirm your account.", nil) delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];				
		} else if (err == -2) {
			// 通信不可
			alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Connection faied.", nil) message:NSLocalizedString(@"Network is not connected.", nil) delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];				
		} else if (err != 0) {
			// その他
			alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Connection faied.", nil) message:NSLocalizedString(@"", nil) delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];				
		}
		[alert show];
		[alert release];
	} else {
		// 成功 -> 選択し直し
		[self tableView:(UITableView *)self.view didSelectRowAtIndexPath:selectedIndex_];
	}
	[selectedIndex_ release];
	selectedIndex_ = nil;

	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:nil];
}

@end

