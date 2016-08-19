//
//  PixAccountViewController.m
//  Tumbltail
//
//  Created by nya on 10/11/27.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TumblrAccountViewController.h"
//#import "PostCache.h"
#import "Requests.h"
#import "SharedAlertView.h"


@implementation TumblrAccountViewController

@synthesize account;

- (id) initWithStyle:(UITableViewStyle)s {
	self = [super initWithStyle:s];
	if (self) {
	}
	return self;
}

- (void)dealloc {
	self.account = nil;

    [super dealloc];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.title = @"Tumblr";
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void) setAccount:(TumblrAccount *)acc {
	if (account != acc) {
		[account release];
		account = [acc retain];
	}
	
	self.username = account.userID;
	self.password = @"";
}

- (NSString *) usernameLabel {
	return NSLocalizedString(@"Mail address", nil);
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	if (self.account != nil && [TumblrAccountManager sharedInstance].accounts.count > 0) {
		return 2;
	} else {
		return 1;
	}
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
	switch (section) {
	case 0:
		return 2;
	case 1:
		return 1;
	default:
		return 0;
	}
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {    
    if (indexPath.section == 0) {
		return [super tableView:tableView cellForRowAtIndexPath:indexPath];
	} else if (indexPath.section == 1) {
		static NSString *CellIdentifier = @"Cell";
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
		if (cell == nil) {
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
		}
		
		cell.textLabel.textAlignment = UITextAlignmentCenter;
		cell.textLabel.text = NSLocalizedString(@"Delete", nil);
		return cell;
	} else {
		assert(0);
		return nil;
	}
}

#pragma mark-

- (void) done:(id)sender {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"CurrentAccountWillChangeNotification" object:self];

	for (TextFieldCell *cell in [self.tableView visibleCells]) {
		if ([cell isKindOfClass:[TextFieldCell class]]) [cell.textField resignFirstResponder];
	}
		
	request = [[LoginRequest alloc] init];
	request.delegate = self;
	[request startWithUsername:self.username password:self.password];
	[self showProgressWithTitle:NSLocalizedString(@"Login", nil)];
}

- (void) cancel:(id)sender {
	[self dismissModalViewControllerAnimated:YES];
}

#pragma mark-

- (void) loginRequest:(id)sender finished:(id)ret {
	[request cancel];
	[request autorelease];
	request = nil;
	
	id token = [ret objectForKey:@"Result"];
	if (token) {
		newAccount = [[TumblrAccount alloc] init];
		newAccount.userID = self.username;
		newAccount.token = token;
		[self performSelector:@selector(loadUserInfo:) withObject:newAccount afterDelay:0.0];
	} else {
		[self hideProgress];
		
		NSError *err = [ret objectForKey:@"Error"];
		if (err) {
			[[SharedAlertView sharedInstance] showError:err withTitle:NSLocalizedString(@"Login failed", nil)];
		} else {
			[[SharedAlertView sharedInstance] showWithTitle:NSLocalizedString(@"Login failed", nil) message:nil cancelButtonTitle:nil okButtonTitle:NSLocalizedString(@"OK", nil)];
		}		
	}
}

- (void) loginRequest:(id)sender failed:(NSError *)err {
	[request cancel];
	[request autorelease];
	request = nil;

	[self hideProgress];
}

- (void) loadUserInfo:(TumblrAccount *)acc {
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(userInfoLoaded:) name:@"TumblrAccountUserInfoLoadedNotification" object:acc];
	[acc load];
}

- (void) userInfoLoaded:(NSNotification *)notif {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[self hideProgress];
	if (![[notif userInfo] objectForKey:@"Error"]) {
		UIActionSheet *sheet = [[[UIActionSheet alloc] init] autorelease];
		sheet.title = @"投稿先";
		sheet.delegate = self;
		for (Tumblog *b in newAccount.blogs) {
			[sheet addButtonWithTitle:b.name];
		}
		[sheet addButtonWithTitle:@"キャンセル"];
		sheet.cancelButtonIndex = sheet.numberOfButtons - 1;
		[sheet showInView:self.view];
	} else {
		[newAccount autorelease];
		[[SharedAlertView sharedInstance] showWithTitle:NSLocalizedString(@"Login failed", nil) message:NSLocalizedString(@"Please verify the account.", nil) cancelButtonTitle:nil okButtonTitle:NSLocalizedString(@"OK", nil)];
	}
}

- (void) progressCancel:(id)sender {
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	TumblrAccount *acc = [newAccount autorelease];
	if (buttonIndex != actionSheet.cancelButtonIndex) {
		Tumblog *b = [acc.blogs objectAtIndex:buttonIndex];
		[[NSUserDefaults standardUserDefaults] setObject:b.name forKey:@"TumblrBlogName"];
		
		[[TumblrAccountManager sharedInstance] addAccount:acc original:self.account];
		[TumblrAccountManager sharedInstance].currentAccount = acc;
		[[TumblrAccountManager sharedInstance] save];
		
		[self dismissModalViewControllerAnimated:YES];
	}
}

@end
