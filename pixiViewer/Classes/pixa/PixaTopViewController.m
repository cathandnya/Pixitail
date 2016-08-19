//
//  PixaTopViewController.m
//  pixiViewer
//
//  Created by nya on 10/02/11.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PixaTopViewController.h"
#import "PixaMatrixViewController.h"
#import "PixaSearchViewController.h"
#import "AccountManager.h"
#import "Pixa.h"
#import "PixListThumbnail.h"


static int pixaItemCount() {
	return 7;
}

static NSString *pixaMethodAtIndex(NSInteger i) {
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

static NSString *pixaNameAtIndex(NSInteger i) {
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


@implementation PixaTopViewController

- (PixService *) pixiv {
	return [Pixa sharedInstance];
}

- (int) count {
	return pixaItemCount();
}

- (NSString *) methodAtIndex:(NSInteger)i {
	return pixaMethodAtIndex(i);
}

- (NSString *) nameAtIndex:(NSInteger)i {
	return pixaNameAtIndex(i);
}

/*
- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if (self = [super initWithStyle:style]) {
    }
    return self;
}
*/

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

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [self count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
	UIImage			*img = nil;
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
	
	NSUInteger idx = [self indexForIndexPath:indexPath];
	cell.textLabel.numberOfLines = 2;
	cell.textLabel.lineBreakMode = UILineBreakModeCharacterWrap;
	cell.textLabel.font = [cell.textLabel.font fontWithSize:16];
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
	cell.textLabel.text = [self nameAtIndex:idx];
	img = [self.account.thumbnail imageWithMethod:[self methodAtIndex:idx]];
	cell.imageView.contentMode = UIViewContentModeScaleToFill;
	cell.imageView.image = img;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	UIViewController		*controller = nil;

		PixaMatrixViewController	*pixa = nil;
	
		// login
		/*
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
		*/
			
		if (indexPath.row == 6) {
			pixa = [[PixaSearchViewController alloc] initWithNibName:@"PixivSearchController" bundle:nil];
		} else {
			pixa = [[PixaMatrixViewController alloc] init];
		}
		
		if (pixa) {
			pixa.method = pixaMethodAtIndex(indexPath.row);
			pixa.navigationItem.title = pixaNameAtIndex(indexPath.row);
			pixa.account = self.account;
			
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


@end

