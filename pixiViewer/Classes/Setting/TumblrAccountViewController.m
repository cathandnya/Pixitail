//
//  TumblrAccountViewController.m
//  pixiViewer
//
//  Created by nya on 11/08/07.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import "TumblrAccountViewController.h"
#import "UserDefaults.h"
#import "Tumblr.h"
#import "ProgressViewController.h"
#import "NSData+Crypto.h"


@implementation TumblrAccountViewController

- (void) viewDidLoad {
	[super viewDidLoad];
	
	self.username = UDStringWithDefault(@"TumblrUsername", @"");
	
	self.title = @"Tumblr";
	self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
}

#pragma mark-

- (NSString *) usernameLabel {
	return @"メールアドレス";
}

#pragma mark-

- (void) done:(id)sender {
	for (TextFieldCell *cell in [self.tableView visibleCells]) {
		if ([cell isKindOfClass:[TextFieldCell class]]) [cell.textField resignFirstResponder];
	}
	
	[Tumblr sharedInstance].username = self.username;
	[Tumblr sharedInstance].password = self.password;
	if ([[Tumblr sharedInstance] login:self]) {
		[[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Login failed", nil) message:@"" delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil] autorelease] show];
		return;
	}
	
	[self showProgress:YES withTitle:NSLocalizedString(@"Login", nil) tag:0];
	progressViewController_.cancelButton.enabled = NO;
	
	[[NSUserDefaults standardUserDefaults] synchronize];
}

- (void) cancel:(id)sender {
	[self.parentViewController dismissModalViewControllerAnimated:YES];
}

- (void) loginFinishedDelay:(NSNumber *)err {
	[self hideProgress];
	
	if ([err longValue]) {
		[[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Login failed", nil) message:[NSString stringWithFormat:NSLocalizedString(@"Error: %d", nil), [err longValue]] delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil] autorelease] show];
	} else {
		[[NSNotificationCenter defaultCenter] postNotificationName:@"PreferenceChangedNotification" object:self userInfo:[NSDictionary dictionaryWithObject:@"SaveToTumblr" forKey:@"Key"]];
		[self.parentViewController dismissModalViewControllerAnimated:YES];
	}
}

- (void) pixService:(PixService *)sender loginFinished:(long)err {
	if (err) {
		//[[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Login failed", nil) message:[NSString stringWithFormat:NSLocalizedString(@"Error: %d", nil), [err code]] delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil] autorelease] show];
	} else {
		UDSetBool(YES, @"SaveToTumblr");
		UDSetString(self.username, @"TumblrUsername");
		UDSetString([self.password cryptedString], @"TumblrPassword");
		[[NSUserDefaults standardUserDefaults] synchronize];
	}
	
	[self performSelector:@selector(loginFinishedDelay:) withObject:[NSNumber numberWithLong:err] afterDelay:1.0];
}

#pragma mark-

- (void) progressCancel:(id)sender {
	[self hideProgress];
}

@end
