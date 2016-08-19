//
//  TumblrBlogListViewController.m
//  pixiViewer
//
//  Created by nya on 10/06/05.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TumblrBlogListViewController.h"
#import "AccountManager.h"


@implementation TumblrBlogAddViewController

@synthesize textField;
@synthesize delegate;

+ (TumblrBlogAddViewController *) viewController {
	return [[[TumblrBlogAddViewController alloc] initWithNibName:@"TumblrBlogAddViewController" bundle:nil] autorelease];
}

- (void) viewDidLoad {
	[super viewDidLoad];
	
	self.title = @"他のブログの追加";
	self.view.backgroundColor = [UIColor groupTableViewBackgroundColor];
	self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel)] autorelease];
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done)] autorelease];
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	[textField becomeFirstResponder];
}

- (void) viewDidUnload {
	[super viewDidUnload];
	self.textField = nil;
}

- (void) dealloc {
	[super dealloc];
}

- (void) cancel {
	[delegate performSelector:@selector(addDone:) withObject:nil];
	[self.navigationController popViewControllerAnimated:YES];
}

- (void) done {
	[delegate performSelector:@selector(addDone:) withObject:textField.text];
	[self.navigationController popViewControllerAnimated:YES];
}

@end


@implementation TumblrBlogListViewController

@synthesize account;

- (void) updateLeftBar {
	self.navigationItem.leftBarButtonItem = !self.tableView.editing ? [[[UIBarButtonItem alloc] initWithTitle:@"編集" style:UIBarButtonItemStyleBordered target:self action:@selector(edit:)] autorelease] : [[[UIBarButtonItem alloc] initWithTitle:@"完了" style:UIBarButtonItemStyleDone target:self action:@selector(edit:)] autorelease];	
}

- (NSString *) blogDefaultKey {
	return [NSString stringWithFormat:@"TumblrBlogList_%@", self.account.username];
}

- (void) saveBlogs:(NSArray *)tags {
	[[NSUserDefaults standardUserDefaults] setObject:tags forKey:[self blogDefaultKey]];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSArray *) blogs {
	return [[NSUserDefaults standardUserDefaults] objectForKey:[self blogDefaultKey]];
}

- (void) moveBlog:(NSUInteger)fromIndex toIndex:(NSInteger)toIndex {
	NSMutableArray *ary = [NSMutableArray arrayWithArray:[self blogs]];
	id from = [[[ary objectAtIndex:fromIndex] retain] autorelease];	
	[ary removeObjectAtIndex:fromIndex];
	[ary insertObject:from atIndex:toIndex];
	[self saveBlogs:ary];
}

- (void) removeBlog:(NSUInteger)idx {
	NSMutableArray *ary = [NSMutableArray arrayWithArray:[self blogs]];
	[ary removeObjectAtIndex:idx];
	[self saveBlogs:ary];
}

- (void) addBlog:(NSString *)str {
	NSMutableArray *ary = [NSMutableArray arrayWithArray:[self blogs]];
	if ([ary containsObject:str]) {
		[ary removeObject:str];
	}
	[ary insertObject:str atIndex:0];
	[self saveBlogs:ary];
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
	
	self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
	self.title = @"他のブログの編集";
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"完了" style:UIBarButtonItemStyleDone target:self action:@selector(done:)] autorelease];
	[self updateLeftBar];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	
	//[self.tableView setEditing:YES];
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
    return 2;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return section == 0 ? [[self blogs] count] : 1;
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
    }
    
	if (indexPath.section == 0) {
		cell.textLabel.text = [[self blogs] objectAtIndex:indexPath.row];
		cell.textLabel.textAlignment = UITextAlignmentLeft;
		cell.accessoryType = UITableViewCellAccessoryNone;
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
	} else {
		cell.textLabel.text = @"追加...";
		cell.textLabel.textAlignment = UITextAlignmentCenter;
		cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		cell.selectionStyle = UITableViewCellSelectionStyleBlue;
	}
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	
	if (indexPath.section == 1) {
		TumblrBlogAddViewController *vc = [TumblrBlogAddViewController viewController];
		vc.delegate = self;
		[self.navigationController pushViewController:vc animated:YES];
	}
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
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
		[self removeBlog:indexPath.row];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}

// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
	[self moveBlog:fromIndexPath.row toIndex:toIndexPath.row];
}

// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
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
		return [NSIndexPath indexPathForRow:0 inSection:0];
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
    [super dealloc];
}

- (void) addDone:(NSString *)str {
	if ([str length] > 0) {
		[self addBlog:str];
		[self.tableView reloadData];
	}
}

- (void) done:(id)sender {
	[self dismissModalViewControllerAnimated:YES];
}

- (void) edit:(id)sender {
	[self.tableView setEditing:!self.tableView.editing animated:YES];
	[self updateLeftBar];
}

@end

