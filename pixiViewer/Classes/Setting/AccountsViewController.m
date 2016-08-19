//
//  AccountsViewController.m
//  pixiViewer
//
//  Created by nya on 11/08/07.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import "AccountsViewController.h"
#import "AccountManager.h"
#import "AccountViewController.h"


@implementation AccountsViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque animated:NO];
	self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
	self.navigationController.toolbar.barStyle = UIBarStyleBlackTranslucent;
	
	self.title = @"アカウント";
	
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneAction:)] autorelease];
	
	self.tableView.editing = YES;
	self.tableView.allowsSelectionDuringEditing = YES;
}

- (void) doneAction:(id)sender {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"AccountListViewNeedsUpdateNotification" object:self userInfo:nil];
	[self dismissModalViewControllerAnimated:YES];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
	[self.tableView reloadData];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

#pragma mark - Table view data source

- (NSArray *) accounts {
	return [AccountManager sharedInstance].accounts;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	if (section == 0) {
		return [[self accounts] count];
	} else {
		return 1;
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell;
	if (indexPath.section == 0) {
		cell = [tableView dequeueReusableCellWithIdentifier:@"Subtitle"];
		if (cell == nil) {
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Subtitle"] autorelease];
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		}
		
		PixAccount *acc = [[self accounts] objectAtIndex:indexPath.row];
		if ([acc.serviceName isEqualToString:@"Danbooru"]) {
			cell.textLabel.text = acc.hostname;
		} else {
			cell.textLabel.text = acc.anonymous ? @"ゲスト" : acc.username;
		}
		cell.detailTextLabel.text = NSLocalizedString(acc.typeString, nil);
	} else {
		cell = [tableView dequeueReusableCellWithIdentifier:@"Default"];
		if (cell == nil) {
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Default"] autorelease];
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		}
		
		cell.textLabel.text = NSLocalizedString(@"Add new account...", nil);
	}
    return cell;
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
	if (indexPath.section == 0) {
		return YES;
	} else {
		return NO;
	}
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
		[[AccountManager sharedInstance] removeAccount:[[AccountManager sharedInstance].accounts objectAtIndex:indexPath.row]];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}

// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
	[[AccountManager sharedInstance] moveIndex:fromIndexPath.row toIndex:toIndexPath.row];
}

// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
	if (indexPath.section == 0) {
		return YES;
	} else {
		return NO;
	}
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath {
	if (proposedDestinationIndexPath.section == 0) {
		return proposedDestinationIndexPath;
	} else {
		return [NSIndexPath indexPathForRow:[[AccountManager sharedInstance].accounts count] - 1 inSection:0];
	}	
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	UIViewController *controller = nil;
	if (indexPath.section == 0) {
		AccountViewController *vc = [[AccountViewController alloc] init];
		vc.account = [[self accounts] objectAtIndex:indexPath.row];
		controller = vc;
	} else {
		AccountViewController *vc = [[AccountViewController alloc] init];
		controller = vc;
	}
	[self.navigationController pushViewController:controller animated:YES];
	[controller release];
}

@end
