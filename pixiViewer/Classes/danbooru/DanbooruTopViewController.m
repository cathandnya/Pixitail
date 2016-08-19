//
//  DanbooruTopViewController.m
//  pixiViewer
//
//  Created by  on 11/07/25.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import "DanbooruTopViewController.h"
#import "Danbooru.h"
#import "DanbooruMatrixViewController.h"
#import "DanbooruSearchViewController.h"
#import "DanbooruSearchHistoryViewController.h"
#import "DanbooruTagBookmarkViewController.h"
#import "AccountManager.h"
#import "PixListThumbnail.h"


static NSInteger itemCount() {
	return 4;
}

static NSString *methodAtIndex(NSInteger i, PixAccount *account) {
	switch (i) {
		case 0:
			return [NSString stringWithFormat:@"http://%@/post/index.json?limit=20", account.hostname];			// Posts
		case 1:
			return @"danbooru_bookmarks";									// タグブックマーク
		case 2:
			return @"danbooru_search";								// 検索
		case 3:
			return @"danbooru_search_history";								// 検索
		default:
			assert(0);
			return nil;
	}
}

static NSString *nameAtIndex(NSInteger i) {
	switch (i) {
		case 0:
			return @"Posts";			
		case 1:
			return @"タグブックマーク";
		case 2:
			return @"検索";
		case 3:
			return @"検索履歴";
		default:
			assert(0);
			return nil;
	}
}


@implementation DanbooruTopViewController

- (PixService *) pixiv {
	return [Danbooru sharedInstance];
}

- (NSInteger) count {
	return itemCount();
}

- (NSString *) methodAtIndex:(NSInteger)i {
	return methodAtIndex(i, account);
}

- (NSString *) nameAtIndex:(NSInteger)i {
	return nameAtIndex(i);
}

- (long) login {
	return 0;
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

- (void) viewDidLoad {
	Danbooru *service = (Danbooru *)[self pixiv];
	service.account = self.account;
		
	[super viewDidLoad];

	if ([account.hostname isEqualToString:@"danbooru.donmai.us"]) {
		self.title = @"Danbooru";
	} else {
		self.title = account.hostname;
	}
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
	
	DanbooruMatrixViewController	*pixa = nil;	
	if (indexPath.row == 2) {
		pixa = [[DanbooruSearchViewController alloc] initWithNibName:@"DanbooruSearchController" bundle:nil];
	} else if (indexPath.row == 3) {
		pixa = (DanbooruMatrixViewController *)[[DanbooruSearchHistoryViewController alloc] init];
	} else if (indexPath.row == 1) {
		pixa = (DanbooruMatrixViewController *)[[DanbooruTagBookmarkViewController alloc] init];
	} else {
		pixa = [[DanbooruMatrixViewController alloc] init];
	}
	
	if (pixa) {
		if ([pixa respondsToSelector:@selector(setMethod:)]) {
			pixa.method = methodAtIndex(indexPath.row, account);
		}
		pixa.navigationItem.title = nameAtIndex(indexPath.row);
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


