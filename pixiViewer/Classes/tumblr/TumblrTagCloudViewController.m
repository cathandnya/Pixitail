//
//  TumblrTagCloudViewController.m
//  pixiViewer
//
//  Created by nya on 10/05/29.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TumblrTagCloudViewController.h"
#import "TagCloud.h"
#import "TumblrMatrixViewController2.h"
#import "AccountManager.h"
#import "Tag.h"
#import "Tumblr.h"
#import "TumblrTagCloudRebuildViewController.h"


@implementation TumblrTagCloudViewController

@synthesize account, name;

- (void) update {
	[list release];
	list = [[[TagCloud sharedInstance] tagsForType:@"Tumblr" user:account.username] retain];
	
	//NSLog([list description]);
	[self.tableView reloadData];
}

- (void) dealloc {

	[list release];
	[account release];
	[name release];
	[super dealloc];
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
	
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(action:)] autorelease];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	[self.navigationController setToolbarHidden:YES animated:YES];

	[self update];
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
    return [list count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
	Tag *tag = [list objectAtIndex:indexPath.row];
	cell.textLabel.text = [NSString stringWithFormat:@"%@ (%d)", tag.name, [tag.frequency integerValue]];
	cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
	
    return cell;
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


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[self.tableView deselectRowAtIndexPath:indexPath animated:YES];

	Tag *tag = [list objectAtIndex:indexPath.row];
	TumblrMatrixViewController2 *vc = [[[TumblrMatrixViewController2 alloc] init] autorelease];
	vc.title = tag.name;
	vc.method = [NSString stringWithFormat:@"read?tagged=%@&", encodeURIComponent(tag.name)];
	vc.name = [Tumblr instance].name;
	vc.account = self.account;
	vc.needsAuth = YES;
	vc.account = account;
	
	[self.navigationController pushViewController:vc animated:YES];
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	[super viewDidUnload];
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}

- (void) action:(id)sender {
	UIActionSheet *sheet = [[[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:@"キャンセル" destructiveButtonTitle:nil otherButtonTitles:@"再構築", nil] autorelease];
	if (([[UIDevice currentDevice] respondsToSelector:@selector(userInterfaceIdiom)] ? [[UIDevice currentDevice] userInterfaceIdiom] : 0) != 0) {
		[sheet showFromBarButtonItem:sender animated:YES];
	} else {
		[sheet showInView:self.view];
	}
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	if (buttonIndex == 0) {
		TumblrTagCloudRebuildViewController *vc = [[[TumblrTagCloudRebuildViewController alloc] initWithNibName:@"TumblrTagCloudRebuildViewController" bundle:nil] autorelease];
		vc.account = self.account;
		vc.name = self.name;
		UINavigationController *nc = [[[UINavigationController alloc] initWithRootViewController:vc] autorelease];
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) nc.modalPresentationStyle = UIModalPresentationFormSheet;
		[self presentModalViewController:nc animated:YES];
	}
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

