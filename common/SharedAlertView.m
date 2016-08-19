//
//  SharedAlertView.m
//
//  Created by nya on 11/07/04.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "SharedAlertView.h"


@implementation SharedAlertView

+ (SharedAlertView *) sharedInstance {
	static SharedAlertView *obj = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		obj = [[SharedAlertView alloc] init];
	});
	return obj;
}

- (void) showWithTitle:(NSString *)title message:(NSString *)msg cancelButtonTitle:(NSString *)cancel okButtonTitle:(NSString *)ok {
	if (!isPresent) {
		UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:title message:msg delegate:self cancelButtonTitle:cancel otherButtonTitles:ok, nil] autorelease];
		[alert show];
		isPresent = YES;
	}
}

- (void) showError:(NSError *)err withTitle:(NSString *)title {
	[self showWithTitle:title message:err ? [err localizedDescription] : @"" cancelButtonTitle:nil okButtonTitle:NSLocalizedString(@"OK", nil)];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
	isPresent = NO;
}

@end
