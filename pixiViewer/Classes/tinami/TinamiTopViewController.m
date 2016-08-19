//
//  TinamiTopViewController.m
//  pixiViewer
//
//  Created by nya on 10/02/23.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TinamiTopViewController.h"
#import "PixListThumbnail.h"
#import "TinamiMatrixViewController.h"
#import "Tinami.h"
#import "AccountManager.h"
#import "TinamiSearchViewController.h"
#import "TinamiTagListController.h"
#import "TinamiSearchHistoryViewController.h"
#import "TinamiUserListViewController.h"


@implementation TinamiTopViewController

- (PixService *) pixiv {
	return [Tinami sharedInstance];
}

- (BOOL) isGuest {
	return self.account.anonymous;
}

- (BOOL) isCreator {
	return (![self isGuest] && [[Tinami sharedInstance] logined] && [Tinami sharedInstance].creatorID != nil);
}

- (NSInteger) count {
	if ([self isCreator]) {
		return 20;
	} else if ([self isGuest]) {
		return 14;
	} else {
		return 19;
	}
}

- (NSString *) methodAtIndex:(NSInteger)i {
	int base;
	if ([self isCreator]) {
		base = 0;
	} else if ([self isGuest]) {
		base = 6;
	} else {
		base = 1;
	}

	switch (i + base) {
	case 0:
		return [NSString stringWithFormat:@"content/search?prof_id=%@", [Tinami sharedInstance].creatorID];
	case 1:
		return @"bookmark/content/list?perpage=20";
	case 2:
		return @"bookmark/list?perpage=20";
	case 3:
		return @"watchkeyword/content/list?perpage=20";
	case 4:
		return @"friend/recommend/content/list?perpage=20";
	case 5:
		return @"collection/list?perpage=20";
	case 6:
		return @"content/search?sort=new";
	case 7:
		return @"content/search?cont_type[]=1";
	case 8:
		return @"content/search?cont_type[]=2";
	case 9:
		return @"content/search?cont_type[]=3";
	case 10:
		return @"content/search?cont_type[]=5";
	case 11:
		return @"content/search?cont_type[]=4";
	case 12:
		return @"ranking?category=0";
	case 13:
		return @"ranking?category=1";
	case 14:
		return @"ranking?category=2";
	case 15:
		return @"ranking?category=3";
	case 16:
		return @"ranking?category=5";
	case 17:
		return @"ranking?category=4";
	case 18:
		return @"tinami_search";
	case 19:
		return @"tinami_search";
	default:
		//assert(0);
	return nil;
	}	
}

- (NSString *) titleAtIndex:(NSInteger)i {
	int base;
	if ([self isCreator]) {
		base = 0;
	} else if ([self isGuest]) {
		base = 6;
	} else {
		base = 1;
	}

	switch (i + base) {
	case 0:
		return @"自分の作品";
	case 1:
		return @"お気に入りクリエイター新着";
	case 2:
		return @"お気に入りクリエイター一覧";
	case 3:
		return @"ウォッチキーワード新着";
	case 4:
		return @"友達の支援履歴";
	case 5:
		return @"コレクション";
	case 6:
	case 12:
		return @"総合";
	case 7:
	case 13:
		return @"イラスト";
	case 8:
	case 14:
		return @"マンガ";
	case 9:
	case 15:
		return @"モデル";
	case 10:
	case 16:
		return @"コスプレ";
	case 11:
	case 17:
		return @"小説";
	case 18:
		return @"検索";
	case 19:
		return @"検索履歴";
	default:
		//assert(0);
		return nil;
	}
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


- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void) viewDidLoad {
	[super viewDidLoad];

	UIImage *logo = [UIImage imageNamed:@"tinami.png"];
	UIImageView *logoView = [[[UIImageView alloc] initWithImage:logo] autorelease];
	CGRect r = logoView.frame;
	logoView.contentMode = UIViewContentModeTop;
	r.size.height += 5;
	logoView.frame = r;
	
	self.navigationItem.titleView = logoView;	
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

#pragma mark-

- (void) loginFinished:(NSNotification *)notif {
	[self.tableView reloadData];
	/*
	if ([self isCreator]) {
		[self.tableView beginUpdates];
		[self.tableView insertSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationRight];
		[self.tableView endUpdates]; 
	} else {
		[self.tableView reloadData];
	}
	 */
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	if ([self isCreator]) {
		return 5;
	} else if ([self isGuest]) {
		return 3;
	} else {
		return 4;
	}
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	int base;
	if ([self isCreator]) {
		base = 0;
	} else if ([self isGuest]) {
		base = 2;
	} else {
		base = 1;
	}

	switch (section + base) {
	case 0:
		return 1;
	case 1:
		return 5;
	case 2:
		return 6;
	case 3:
		return 6;
	case 4:
		return 2;
	default:
		assert(0);
		return 0;
	}	
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	int base;
	if ([self isCreator]) {
		base = 0;
	} else if ([self isGuest]) {
		base = 2;
	} else {
		base = 1;
	}

	switch (section + base) {
	case 0:
		return @"クリエイター";
	case 1:
		return self.account.username ? @"ユーザー" : @"ゲスト";
	case 2:
		return @"新着";
	case 3:
		return @"ランキング";
	case 4:
		return @"検索";
	default:
		//assert(0);
		return nil;
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
	UIImage			*img = nil;
    NSInteger idx = [self indexForIndexPath:indexPath];
	
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
		cell.textLabel.numberOfLines = 2;
		cell.textLabel.lineBreakMode = UILineBreakModeCharacterWrap;
		cell.textLabel.font = [cell.textLabel.font fontWithSize:16];
		cell.imageView.contentMode = UIViewContentModeScaleToFill;
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
	
	img = [self.account.thumbnail imageWithMethod:[self methodAtIndex:idx]];
	cell.textLabel.text = [self titleAtIndex:idx];
	cell.imageView.image = img;
	
	if (self.account.anonymous && ([[self methodAtIndex:idx] hasPrefix:@"collection"] || [[self methodAtIndex:idx] hasPrefix:@"bookmark"])) {
		cell.textLabel.textColor = [UIColor grayColor];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
	} else {
		cell.textLabel.textColor = [UIColor blackColor];
		cell.selectionStyle = UITableViewCellSelectionStyleBlue;
	}
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	UIViewController		*controller = nil;
    NSUInteger idx = [self indexForIndexPath:indexPath];

	if (self.account.anonymous && ([[self methodAtIndex:idx] hasPrefix:@"collection"] || [[self methodAtIndex:idx] hasPrefix:@"bookmark"])) {
		return;
	}

		TinamiMatrixViewController	*pixa = nil;
	
		// login
		/*
		if (![[Tinami sharedInstance] logined]) {
			long err = [[Tinami sharedInstance] login:self];
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
		*/
		
		NSString *method = [self methodAtIndex:idx];
		NSString *title = [self titleAtIndex:idx];
		if ([title isEqual:@"検索"]) {
			// 検索
			pixa = [[TinamiSearchViewController alloc] initWithNibName:@"TinamiSearchController" bundle:nil];
			pixa.method = method;
			pixa.account = self.account;
		} else if ([title isEqual:@"検索履歴"]) {
			// 検索履歴
			pixa = (TinamiMatrixViewController *)[[TinamiSearchHistoryViewController alloc] init];
			pixa.account = self.account;
		} else if ([title isEqual:@"お気に入りクリエイター一覧"]) {
			// お気に入りユーザ
			pixa = (TinamiMatrixViewController *)[[TinamiUserListViewController alloc] initWithNibName:@"PixivUserListViewController" bundle:nil];
			pixa.method = method;
			pixa.account = self.account;
		} else if ([title isEqual:@"タグブックマーク"]) {
			// タグブックマーク
			pixa = (TinamiMatrixViewController *)[[TinamiTagListController alloc] initWithNibName:@"PixivTagListController" bundle:nil];
			pixa.account = self.account;
		} else {
			pixa = [[TinamiMatrixViewController alloc] init];
			pixa.method = method;
			pixa.account = self.account;
		}
		
		if (pixa) {
			pixa.navigationItem.title = [self titleAtIndex:idx];			
			controller = pixa;
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


- (void)dealloc {
    [super dealloc];
}

#pragma mark-

/*
- (void) connection:(NSURLConnection *)con didReceiveResponse:(NSURLResponse *)response {
}


- (void) connection:(NSURLConnection *)con didReceiveData:(NSData *)data {
	if (con == getLoginInfoConnection) {
		[loginInfo_ appendData:data];
	} else if (con == getCreatorInfoConnection) {
		[creatorInfo_ appendData:data];
	}
}


- (void) connection:(NSURLConnection *)con didFailWithError:(NSError *)error {
	if (con == getLoginInfoConnection) {
		[getLoginInfoConnection release];
		getLoginInfoConnection = nil;
		[loginInfo_ release];
		loginInfo_ = nil;
	} else if (con == getCreatorInfoConnection) {
		[getLoginInfoConnection release];
		getLoginInfoConnection = nil;
		[creatorInfo_ release];
		creatorInfo_ = nil;
	}
}

- (void) connectionDidFinishLoading:(NSURLConnection *)con {
	if (con == getLoginInfoConnection) {
		[getLoginInfoConnection release];
		getLoginInfoConnection = nil;
	
		TinamiAuthParser *parser = [[[TinamiAuthParser alloc] initWithEncoding:NSUTF8StringEncoding] autorelease];
		[parser addData:loginInfo_];
		[loginInfo_ release];
		loginInfo_ = nil;
		if ([parser.status isEqual:@"ok"] == NO) {
			// 失敗
			
		}
		
		[creatorID release];
		creatorID = [parser.creatorID retain];

	} else if (con == getCreatorInfoConnection) {
	}
}

- (NSCachedURLResponse *) connection:(NSURLConnection *)con willCacheResponse:(NSCachedURLResponse *)cachedResponse {
    return nil;
}

- (NSURLRequest *)connection:(NSURLConnection *)con willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)redirectResponse {
	return request;
}
*/

@end
