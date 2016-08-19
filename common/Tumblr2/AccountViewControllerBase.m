//
//  AccountViewController.m
//  Tumbltail
//
//  Created by nya on 10/09/19.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "AccountViewControllerBase.h"
#import "ActivitySheetViewController.h"


@implementation AccountViewControllerBase

@synthesize username, password;

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
	
	self.navigationController.navigationBar.barStyle= UIBarStyleBlackTranslucent;
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneAction:)] autorelease];
}

- (void) doneAction:(id)sender {
	
	
	[self dismissModalViewControllerAnimated:YES];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:)] autorelease];
	self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)] autorelease];
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
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return 2;
}

- (NSString *) usernameLabel {
	return NSLocalizedString(@"Username", nil);
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {    
    if (indexPath.section == 0) {
		TextFieldCell *cell = [TextFieldCell cell:tableView];
		cell.delegate = self;
    
		if (indexPath.row == 0) {
			cell.textLabel.text = [self usernameLabel];
			cell.textField.keyboardType = UIKeyboardTypeEmailAddress;
			cell.textField.secureTextEntry = NO;
			cell.textField.text = self.username;
		} else if (indexPath.row == 1) {
			cell.textLabel.text = NSLocalizedString(@"Password", nil);
			cell.textField.keyboardType = UIKeyboardTypeDefault;
			cell.textField.secureTextEntry = YES;
			cell.textField.text = self.password;
		}
	
		return cell;
	} else {
		assert(0);
		return nil;
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
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
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
}

- (BOOL) textFieldCell:(TextFieldCell *)sender shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
	return YES;
}

- (void) textFieldCellValueChanged:(TextFieldCell *)sender {
	NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
	if (indexPath.row == 0) {
		self.username = sender.textField.text;
	} else if (indexPath.row == 1) {
		self.password = sender.textField.text;
	}
}

- (void) textFieldCellDidReturn:(TextFieldCell *)sender {
	NSIndexPath *indexPath = [self.tableView indexPathForCell:sender];
	if (indexPath.row == 0) {
		TextFieldCell *cell = (TextFieldCell *)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
		[cell.textField becomeFirstResponder];
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
	self.username = nil;
	self.password = nil;

    [super dealloc];
}

#pragma mark-

- (void) done:(id)sender {
	for (TextFieldCell *cell in [self.tableView visibleCells]) {
		if ([cell isKindOfClass:[TextFieldCell class]]) [cell.textField resignFirstResponder];
	}
}

- (void) cancel:(id)sender {
	[self dismissModalViewControllerAnimated:YES];
}

#pragma mark-

- (void) progressCancel:(id)sender {
	[self hideProgress];
}

#pragma mark-

- (void) showProgressWithTitle:(NSString *)str {
	activityController = [[ActivitySheetViewController activityController] retain];
	[activityController present];
	activityController.label.text = str;
	if (!activityController.activityView.isAnimating) {
		[activityController.activityView startAnimating];
	}
}

- (void) hideProgress {
	[activityController dismiss];
	[activityController release];
	activityController = nil;
}

@end

