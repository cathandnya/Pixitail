//
//  TumblrTagBookmarkViewController.m
//  pixiViewer
//
//  Created by nya on 10/05/30.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TumblrTagBookmarkViewController.h"
#import "TumblrMatrixViewController2.h"
#import "AccountManager.h"
#import "Tumblr.h"
#import "PixivTagAddViewController.h"
#import "PixListThumbnail.h"


@implementation TumblrTagBookmarkViewController

@synthesize account, name;

#pragma mark-

- (void) updateRightBar {
	self.navigationItem.rightBarButtonItem = !self.tableView.editing ? [[[UIBarButtonItem alloc] initWithTitle:@"編集" style:UIBarButtonItemStyleBordered target:self action:@selector(editTag:)] autorelease] : [[[UIBarButtonItem alloc] initWithTitle:@"完了" style:UIBarButtonItemStyleDone target:self action:@selector(editTag:)] autorelease];	
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

- (void) moveTag:(NSUInteger)fromIndex toIndex:(NSInteger)toIndex {
	NSMutableArray *ary = [NSMutableArray arrayWithArray:[self tags]];
	id from = [[[ary objectAtIndex:fromIndex] retain] autorelease];	
	[ary removeObjectAtIndex:fromIndex];
	[ary insertObject:from atIndex:toIndex];
	[self saveTags:ary];
}

- (void) removeTag:(NSUInteger)idx {
	NSMutableArray *ary = [NSMutableArray arrayWithArray:[self tags]];
	[ary removeObjectAtIndex:idx];
	[self saveTags:ary];
}

- (void) addTag:(NSString *)str {
	NSMutableArray *ary = [NSMutableArray arrayWithArray:[self tags]];
	if ([ary containsObject:str]) {
		[ary removeObject:str];
	}
	[ary insertObject:str atIndex:0];
	[self saveTags:ary];
}

#pragma mark -
#pragma mark Initialization

/*
- (id)initWithStyle:(UITableViewStyle)style {
    // Override initWithStyle: if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
    if ((self = [super initWithStyle:style])) {
    }
    return self;
}
*/


#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

	self.tableView.allowsSelectionDuringEditing = YES;
	[self updateRightBar];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

	[self.navigationController setToolbarHidden:YES animated:YES];
	[((UITableView *)self.view) reloadData];
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
/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
	return [[self tags] count] + (self.tableView.editing ? 1 : 0);
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
	
	cell.textLabel.font = [cell.textLabel.font fontWithSize:16];
	cell.imageView.contentMode = UIViewContentModeScaleToFill;
	{
		int idx = indexPath.row;		
		if (self.tableView.editing) {
			idx--;
		}

		cell.textLabel.numberOfLines = 1;
		if (idx < 0) {
			cell.textLabel.text = @"タグを追加...";
			cell.accessoryType = UITableViewCellAccessoryNone;
			cell.textLabel.textAlignment = UITextAlignmentCenter;
			cell.selectionStyle = UITableViewCellSelectionStyleBlue;
			cell.imageView.image = nil;
		} else {
			cell.textLabel.text = [[self tags] objectAtIndex:idx];
			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.textLabel.textAlignment = UITextAlignmentLeft;
			//cell.selectionStyle = self.tableView.editing ? UITableViewCellSelectionStyleNone : UITableViewCellSelectionStyleBlue;
			cell.imageView.image = [self.account.thumbnail imageWithMethod:[NSString stringWithFormat:@"read?tagged=%@&", encodeURIComponent([[self tags] objectAtIndex:idx])]];
		}
	}
	
	return cell;
}

- (void) add {
	if (self.tableView.editing == NO) {
		return;
	}
	
	PixivTagAddViewController	*controller = [[PixivTagAddViewController alloc] initWithNibName:@"PixivTagAddViewController" bundle:nil];
	controller.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
	controller.delegate = self;
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) controller.modalPresentationStyle = UIModalPresentationFormSheet;
	[self presentModalViewController:controller animated:YES];
	[controller release];
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
	{
		int idx = indexPath.row;		
		if (self.tableView.editing) {
			idx--;
		}
		if (idx < 0) {
			[self add];
		} else if (self.tableView.editing == NO) {
			vc = [[TumblrMatrixViewController2 alloc] init];
			vc.title = [[self tags] objectAtIndex:idx];
			vc.method = [NSString stringWithFormat:@"read?tagged=%@&", encodeURIComponent([[self tags] objectAtIndex:idx])];
			vc.name = [Tumblr instance].name;
			vc.account = self.account;
			vc.needsAuth = YES;
		}
	}
	vc.account = account;
	controller = vc;

	[self.navigationController pushViewController:controller animated:YES];
	[controller release];
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.row > 0) {
		return YES;
	} else {
		return NO;
	}
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
		[self removeTag:indexPath.row - 1];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}

// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
	[self moveTag:fromIndexPath.row - 1 toIndex:toIndexPath.row - 1];
}

// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.row > 0) {
		return YES;
	} else {
		return NO;
	}
}

- (NSIndexPath *)tableView:(UITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath {
	if (proposedDestinationIndexPath.row > 0) {
		return proposedDestinationIndexPath;
	} else {
		return [NSIndexPath indexPathForRow:1 inSection:0];
	}	
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}


- (void)dealloc {
	[account release];
	[name release];

    [super dealloc];
}

- (void) editTag:(id)sender {
	[self.tableView setEditing:!self.tableView.editing animated:YES];
	
	[self.tableView beginUpdates];
	if (self.tableView.editing) {
		[self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationTop];
	} else {
		[self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationBottom];
	}
	[self.tableView endUpdates]; 

	[self updateRightBar];
}

- (void) tagAddViewCancel:(PixivTagAddViewController *)sender {
	[self dismissModalViewControllerAnimated:YES];
}

- (void) tagAddView:(PixivTagAddViewController *)sender done:(NSDictionary *)info {
	NSString	*str = [info objectForKey:@"Tag"];
	NSArray		*ary = [str componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
	for (NSString *s in ary) {
		if ([s length] > 0) {
			[self addTag:s];
		}
	}
	
	[self.tableView reloadData];
	[self dismissModalViewControllerAnimated:YES];	
}

#pragma mark-

- (NSMutableDictionary *) storeInfo {
	NSMutableDictionary *info = [super storeInfo];
	
	[info setObject:[account info] forKey:@"Account"];
	[info setObject:name forKey:@"Name"];

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
	
	obj = [info objectForKey:@"Name"];
	if (obj == nil) {
		return NO;
	}
	self.name = obj;

	return YES;
}

@end

