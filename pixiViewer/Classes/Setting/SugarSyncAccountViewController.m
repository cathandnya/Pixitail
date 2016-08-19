//
//  SugarSyncAccountViewController.m
//
//  Created by Naomoto nya on 12/07/06.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "SugarSyncAccountViewController.h"
#import "SugarSync.h"
#import "UserDefaults.h"

@implementation SugarSyncAccountViewController

- (void) viewDidLoad {
	[super viewDidLoad];
	
	self.username = [[SugarSync sharedInstance] username];
	self.password = @"";
	
	self.title = NSLocalizedString(@"SugarSync", nil);
	self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
}

- (void) viewDidUnload {
	[super viewDidUnload];
}

- (NSString *) usernameLabel {
	return @"メールアドレス";
}

- (void) done:(id)sender {
	for (TextFieldCell *cell in [self.tableView visibleCells]) {
		if ([cell isKindOfClass:[TextFieldCell class]]) [cell.textField resignFirstResponder];
	}
	
	SugarSync *service = [SugarSync sharedInstance];
	[service loginWithUsername:self.username password:self.password block:^(NSError *err) {
		[self hideProgress];
		
		if (err) {
			[[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Login failed", nil) message:[NSString stringWithFormat:NSLocalizedString(@"Error: %d", nil), [err code]] delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil] autorelease] show];
		} else {
			UDSetBool(YES, @"SaveToSugarSync");
			[[NSNotificationCenter defaultCenter] postNotificationName:@"PreferenceChangedNotification" object:self userInfo:[NSDictionary dictionaryWithObject:@"SugarSyncLogin" forKey:@"Key"]];
			[self.parentViewController dismissModalViewControllerAnimated:YES];
		}
	}];
	
	[self showProgress:YES withTitle:NSLocalizedString(@"Login", nil) tag:0];
}

- (void) cancel:(id)sender {
	[self.parentViewController dismissModalViewControllerAnimated:YES];
}

#pragma mark-

- (BOOL) logined {
	return [[SugarSync sharedInstance] hasAccount];
}

@end
