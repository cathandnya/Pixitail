//
//  EvernoteAccountViewController.m
//  Tumbltail
//
//  Created by nya on 10/11/27.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "EvernoteAccountViewController.h"
#import "EvernoteTail.h"
#import "ProgressViewController.h"
#import "UserDefaults.h"
#import "NSData+Crypto.h"


@implementation EvernoteAccountViewController

@synthesize username, password;

- (void) viewDidLoad {
	[super viewDidLoad];
	
	self.username = UDStringWithDefault(@"EvernoteUsername", @"");
	
	self.title = NSLocalizedString(@"EvernoteAccount", nil);
	self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(done:)] autorelease];
	self.navigationItem.leftBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)] autorelease];
}

#pragma mark-

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

	//[EvernoteTail sharedInstance].username = self.username;
	//[EvernoteTail sharedInstance].password = self.password;
	//[[EvernoteTail sharedInstance] login:self];
	
	[self showProgress:YES withTitle:NSLocalizedString(@"Login", nil) tag:0];
	progressViewController_.cancelButton.enabled = NO;
	
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (void) cancel:(id)sender {
	[self.parentViewController dismissModalViewControllerAnimated:YES];
}

- (void) loginFinishedDelay:(NSError *)err {
	[self hideProgress];
	
	if (err) {
		[[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Login failed", nil) message:[NSString stringWithFormat:NSLocalizedString(@"Error: %d", nil), [err code]] delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil] autorelease] show];
	} else {
		//UDSetBool(YES, @"SaveToEvernote");
		//UDSetString(self.username, @"EvernoteUsername");
		//UDSetString(self.password, @"EvernotePassword");
		//[[NSUserDefaults standardUserDefaults] synchronize];

		[[NSNotificationCenter defaultCenter] postNotificationName:@"PreferenceChangedNotification" object:self userInfo:[NSDictionary dictionaryWithObject:@"SaveToEvernote" forKey:@"Key"]];
		[self.parentViewController dismissModalViewControllerAnimated:YES];
	}
}

- (void) loginFinished:(NSError *)err {
	if (err) {
		//[[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Login failed", nil) message:[NSString stringWithFormat:NSLocalizedString(@"Error: %d", nil), [err code]] delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil] autorelease] show];
	} else {
		UDSetBool(YES, @"SaveToEvernote");
		UDSetString(self.username, @"EvernoteUsername");
		UDSetString([self.password cryptedString], @"EvernotePassword");
		[[NSUserDefaults standardUserDefaults] synchronize];
	}
	
	[self performSelector:@selector(loginFinishedDelay:) withObject:err afterDelay:1.0];
}

#pragma mark-

- (void) progressCancel:(id)sender {
	[self hideProgress];
}

@end
