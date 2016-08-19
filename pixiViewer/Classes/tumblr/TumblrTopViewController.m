//
//  TumblrTopViewController.m
//  pixiViewer
//
//  Created by nya on 10/02/14.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TumblrTopViewController.h"
#import "PixListThumbnail.h"
#import "TumblrMatrixViewController.h"
#import "TumblrMatrixViewController2.h"
#import "AccountManager.h"
#import "Tumblr.h"
#import "TumblrTagCloudViewController.h"
#import "TumblrTagBookmarkViewController.h"
#import "TumblrBlogListViewController.h"


@implementation TumblrTopViewController

- (PixService *) pixiv {
	return [Tumblr instance];
}

- (int) count {
	return 5;
}

- (NSString *) blogDefaultKey {
	return [NSString stringWithFormat:@"TumblrBlogList_%@", self.account.username];
}

- (NSArray *) blogs {
	return [[NSUserDefaults standardUserDefaults] objectForKey:[self blogDefaultKey]];
}

- (void) viewDidLoad {
	[super viewDidLoad];
	self.tableView.allowsSelectionDuringEditing = YES;
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"編集" style:UIBarButtonItemStyleBordered target:self action:@selector(editBlogs:)] autorelease];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

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
	[super viewDidUnload];
}

#pragma mark Table view methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (section == 0) {
		return [self count];
	} else if (section == 1) {
		return [[self blogs] count];
	} else {
		return 0;
	}
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	if (section == 0) {
		if ([Tumblr instance].name) {
			return [NSString stringWithFormat:@"%@.tumblr.com", [Tumblr instance].name];
		} else {
			return @"Loading...";
		}
	} else {
		return @"Other blogs";
	}
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
	UIImage			*img = nil;
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
	
	cell.textLabel.font = [cell.textLabel.font fontWithSize:16];
	cell.imageView.contentMode = UIViewContentModeScaleToFill;
	if (indexPath.section == 0) {
		cell.textLabel.numberOfLines = 2;
		cell.textLabel.lineBreakMode = UILineBreakModeCharacterWrap;
		cell.textLabel.textAlignment = UITextAlignmentLeft;
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
		if (indexPath.row == 1) {
			cell.textLabel.text = @"Home";
			img = [self.account.thumbnail imageWithMethod:[NSString stringWithFormat:@"%@_%@", [Tumblr instance].name, @"read?"]];
		} else if (indexPath.row == 0) {
			cell.textLabel.text = @"Dashboard";
#ifdef USE_TWITTER_API_DASHBOARD
			img = [self.account.thumbnail imageWithMethod:@"home_timeline"];
#else
			//img = [self.account.thumbnail imageWithMethod:@"dashboard?"];
			img = [self.account.thumbnail imageWithMethod:[NSString stringWithFormat:@"%@_%@", [Tumblr instance].name, @"dashboard?"]];
#endif
		} else if (indexPath.row == 2) {
			cell.textLabel.text = @"Likes";
			img = [self.account.thumbnail imageWithMethod:[NSString stringWithFormat:@"%@_%@", [Tumblr instance].name, @"likes?"]];
		} else if (indexPath.row == 3) {
			cell.textLabel.text = @"タグクラウド";
			img = [UIImage imageNamed:@"dummy.png"];
		} else if (indexPath.row == 4) {
			cell.textLabel.text = @"タグブックマーク";
			img = [UIImage imageNamed:@"dummy.png"];
		}
	
		//cell.selectionStyle = self.tableView.editing ? UITableViewCellSelectionStyleNone : UITableViewCellSelectionStyleBlue;
		cell.imageView.image = img;
	} else if (indexPath.section == 1) {
		cell.textLabel.numberOfLines = 2;
		cell.textLabel.lineBreakMode = UILineBreakModeCharacterWrap;
		cell.textLabel.textAlignment = UITextAlignmentLeft;
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		cell.textLabel.text = [NSString stringWithFormat:@"%@.tumblr.com", [[self blogs] objectAtIndex:indexPath.row]];
		cell.imageView.image = [self.account.thumbnail imageWithMethod:[NSString stringWithFormat:@"%@_%@", [[self blogs] objectAtIndex:indexPath.row], @"read?"]];
	}
	
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	UIViewController *controller = nil;
	[tableView deselectRowAtIndexPath:indexPath animated:YES];

	if (![Tumblr instance].reachable) {
				UIAlertView	*alert = nil;
					// 通信不可
					alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Connection faied.", nil) message:NSLocalizedString(@"Network is not connected.", nil) delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];				
				[alert show];
				[alert release];

				[tableView deselectRowAtIndexPath:indexPath animated:NO];
				return;
	}
	
	TumblrMatrixViewController2 *vc = nil;
	if (indexPath.section == 0) {
		if (indexPath.row == 1) {
			vc = [[TumblrMatrixViewController2 alloc] init];
			vc.title = @"Home";
			vc.method = @"read?";
			vc.name = [Tumblr instance].name;
			vc.account = self.account;
			vc.needsAuth = YES;
		} else if (indexPath.row == 0) {
#ifdef USE_TWITTER_API_DASHBOARD
			vc = [[TumblrMatrixViewController alloc] init];
			vc.method = @"home_timeline";
#else
			vc = [[TumblrMatrixViewController2 alloc] init];
			vc.name = [Tumblr instance].name;
			vc.needsAuth = YES;
			vc.method = @"dashboard?";
#endif
			vc.account = self.account;
			vc.title = @"Dashboard";
		} else if (indexPath.row == 2) {
			vc = [[TumblrMatrixViewController2 alloc] init];
			vc.title = @"Likes";
			vc.method = @"likes?";
			vc.name = [Tumblr instance].name;
			vc.account = self.account;
			vc.needsAuth = YES;
		} else if (indexPath.row == 3) {
			vc = (TumblrMatrixViewController2 *)[[TumblrTagCloudViewController alloc] init];
			vc.name = [Tumblr instance].name;
			vc.title = @"タグクラウド";
		} else if (indexPath.row == 4) {
			vc = (TumblrMatrixViewController2 *)[[TumblrTagBookmarkViewController alloc] init];
			vc.name = [Tumblr instance].name;
			vc.title = @"タグブックマーク";
		}
	} else {
		vc = [[TumblrMatrixViewController2 alloc] init];
		vc.title = [NSString stringWithFormat:@"%@.tumblr.com", [[self blogs] objectAtIndex:indexPath.row]];
		vc.method = @"read?";
		vc.name = [[self blogs] objectAtIndex:indexPath.row];
		vc.account = self.account;
		vc.needsAuth = NO;
	}
	vc.account = account;
	controller = vc;

	[self.navigationController pushViewController:controller animated:YES];
	[controller release];
}

- (void)dealloc {
    [super dealloc];
}

#pragma mark-

- (void) loginFinished:(NSNotification *)notif {
	[self.tableView reloadData];
}

- (void) editBlogs:(id)sender {
	TumblrBlogListViewController *vc = [[[TumblrBlogListViewController alloc] initWithStyle:UITableViewStyleGrouped] autorelease];
	vc.account = self.account;
	UINavigationController *nc = [[[UINavigationController alloc] initWithRootViewController:vc] autorelease];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) nc.modalPresentationStyle = UIModalPresentationFormSheet;
	[self presentModalViewController:nc animated:YES];
}

@end
