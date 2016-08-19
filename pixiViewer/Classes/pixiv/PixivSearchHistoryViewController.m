//
//  PixivSearchHistoryViewController.m
//  pixiViewer
//
//  Created by nya on 09/11/28.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PixivSearchHistoryViewController.h"
#import "PixivMatrixViewController.h"
#import "PixListThumbnail.h"
#import "AccountManager.h"
#import "PixService.h"
#import "AdmobHeaderView.h"
#import "PixiViewerAppDelegate.h"


@implementation PixivSearchHistoryViewController

@synthesize account;

- (NSString *) defaultName {
	return @"SerchHistory";
}

/*
- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if (self = [super initWithStyle:style]) {
    }
    return self;
}
*/

- (void)viewDidLoad {
    [super viewDidLoad];

	self.tableView.rowHeight = 44;
	
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
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	[self.navigationController setToolbarHidden:YES animated:YES];
	[self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
	//[self.tableView reloadData];
}

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

- (NSArray *) list {
	return [[NSUserDefaults standardUserDefaults] objectForKey:[self defaultName]];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[self list] count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"SearchHistoryCell";
    NSArray *list = [self list];
	
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
	cell.textLabel.numberOfLines = 2;
	cell.textLabel.lineBreakMode = UILineBreakModeCharacterWrap;
	cell.textLabel.font = [cell.textLabel.font fontWithSize:16];
	if (indexPath.row < [list count]) {
		NSDictionary *info = [list objectAtIndex:indexPath.row];
		cell.textLabel.text = [info objectForKey:@"Term"];
		cell.imageView.image = [self.account.thumbnail imageWithMethod:[NSString stringWithFormat:@"search.php?word=%@&s_mode=%@&", encodeURIComponent([info objectForKey:@"Term"]), [info objectForKey:@"Scope"]]];
	}
	
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *list = [self list];
	if (indexPath.row < [list count]) {
		NSDictionary *info = [list objectAtIndex:indexPath.row];
		
		PixivMatrixViewController * controller = [[PixivMatrixViewController alloc] init];
		controller.method = [NSString stringWithFormat:@"search.php?word=%@&s_mode=%@&", encodeURIComponent([info objectForKey:@"Term"]), [info objectForKey:@"Scope"]];
		controller.account = self.account;
		[self.navigationController pushViewController:controller animated:YES];
		[controller release];
	}
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		NSMutableArray *list = [NSMutableArray arrayWithArray:[self list]];
	
        // Delete the row from the data source
		if (indexPath.row < [list count]) {
			[list removeObjectAtIndex:indexPath.row];

			[[NSUserDefaults standardUserDefaults] setObject:list forKey:[self defaultName]];
			[[NSUserDefaults standardUserDefaults] synchronize];

			[tableView reloadData];
		}
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}

// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}

// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return NO;
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
	[account release];

    [super dealloc];
}

#pragma mark-

/*
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
	}
}
*/

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

