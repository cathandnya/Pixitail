//
//  PasscodeLockViewController.m
//  Tumbltail
//
//  Created by nya on 11/04/19.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "PasscodeLockViewController.h"


@interface PasscodeLockViewController()
@property(strong) NSString *aNewPassword;
//@property(strong) UIImage *backImage;
@property(assign) UIInterfaceOrientation imageOrientation;
@end


@implementation PasscodeLockViewController

- (id) init {
	self = [super initWithNibName:@"PasscodeLockViewController" bundle:nil];
	if (self) {
		
	}
	return self;
}

- (void) dealloc {
}

#pragma mark-

- (int) windowLebel {
	return UIWindowLevelNormal + 10;
}

- (void) viewDidLoad {
	[super viewDidLoad];
	
	if (!self.password) {
		self.label.text = NSLocalizedString(@"Enter a passcode", nil);
	} else {
		self.label.text = NSLocalizedString(@"Enter Passcode", nil);
	}
	
	if ([UIDevice currentDevice].systemVersion.floatValue >= 8.0) {
		UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
		UIVisualEffectView *effectView = [[UIVisualEffectView alloc] initWithEffect:effect];
		effectView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
		effectView.autoresizingMask =UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
		[self.view insertSubview:effectView atIndex: 0];
		self.view.backgroundColor = [UIColor clearColor];
	}

}

- (void) viewDidUnload {
	[super viewDidUnload];
	
	self.label = nil;
	self.passField = nil;
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	
	[self.passField becomeFirstResponder];
	//[passField performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.1];
	
	//if ([UIDevice currentDevice].systemVersion.floatValue >= 8.0) {
	//	[self setBackView];
	//}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		return YES;
	} else {
		return interfaceOrientation == UIInterfaceOrientationPortrait;
	}
}

- (CGFloat) animationDuration {
	return 0;
}

- (void) reEnter {
	self.passField.text = @"";
	[self.passField becomeFirstResponder];
	
	[[UIApplication sharedApplication] endIgnoringInteractionEvents];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
	NSString *str = [textField.text stringByReplacingCharactersInRange:range withString:string];
	if (str.length >= 4) {
		{
			if (self.password == nil) {
				if (self.aNewPassword == nil) {
					self.aNewPassword = str;
					self.label.text = NSLocalizedString(@"Re-enter your Passcode", nil);
					
					[self performSelector:@selector(reEnter) withObject:nil afterDelay:0.2];
					[[UIApplication sharedApplication] beginIgnoringInteractionEvents];
				} else {
					if ([self.aNewPassword isEqualToString:str]) {
						self.password = str;
						[self.delegate passcodeLockViewControllerFinished:self];
					} else {
						self.aNewPassword = nil;
						
						self.label.text = NSLocalizedString(@"Enter a passcode", nil);
						
						[self performSelector:@selector(reEnter) withObject:nil afterDelay:0.2];
						[[UIApplication sharedApplication] beginIgnoringInteractionEvents];
					}
				}
			} else if ([self.password isEqualToString:str]) {
				[self.passField resignFirstResponder];
				[self.delegate passcodeLockViewControllerFinished:self];
			} else {
				[self performSelector:@selector(reEnter) withObject:nil afterDelay:0.2];
				[[UIApplication sharedApplication] beginIgnoringInteractionEvents];
			}
		}
		return YES;
	} else {
		return YES;
	}
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
	//[pass2 performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.3];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
	textField.text = @"";
}

/*
 UIInterfaceOrientationPortrait           = UIDeviceOrientationPortrait,			// 1
 UIInterfaceOrientationPortraitUpsideDown = UIDeviceOrientationPortraitUpsideDown,	// 2
 UIInterfaceOrientationLandscapeLeft      = UIDeviceOrientationLandscapeRight,		// 4
 UIInterfaceOrientationLandscapeRight     = UIDeviceOrientationLandscapeLeft		// 3
 */
+ (UIImageOrientation) orientation:(UIInterfaceOrientation)from to:(UIInterfaceOrientation)to {
	switch (from) {
		case UIInterfaceOrientationPortrait:
			switch (to) {
				case UIInterfaceOrientationPortrait:
					return UIImageOrientationUp;
				case UIInterfaceOrientationPortraitUpsideDown:
					return UIImageOrientationDown;
					break;
				case UIInterfaceOrientationLandscapeLeft:
					return UIImageOrientationLeft;
					break;
				case UIInterfaceOrientationLandscapeRight:
					return UIImageOrientationRight;
					break;
				default:
					break;
			}
			break;
			
		case UIInterfaceOrientationPortraitUpsideDown:
			switch (to) {
				case UIInterfaceOrientationPortrait:
					return UIImageOrientationDown;
				case UIInterfaceOrientationPortraitUpsideDown:
					return UIImageOrientationUp;
					break;
				case UIInterfaceOrientationLandscapeLeft:
					return UIImageOrientationRight;
					break;
				case UIInterfaceOrientationLandscapeRight:
					return UIImageOrientationLeft;
					break;
				default:
					break;
			}
			break;
			
		case UIInterfaceOrientationLandscapeLeft:
			switch (to) {
				case UIInterfaceOrientationPortrait:
					return UIImageOrientationRight;
				case UIInterfaceOrientationPortraitUpsideDown:
					return UIImageOrientationLeft;
					break;
				case UIInterfaceOrientationLandscapeLeft:
					return UIImageOrientationUp;
					break;
				case UIInterfaceOrientationLandscapeRight:
					return UIImageOrientationDown;
					break;
				default:
					break;
			}
			break;
			
		case UIInterfaceOrientationLandscapeRight:
			switch (to) {
				case UIInterfaceOrientationPortrait:
					return UIImageOrientationLeft;
				case UIInterfaceOrientationPortraitUpsideDown:
					return UIImageOrientationRight;
					break;
				case UIInterfaceOrientationLandscapeLeft:
					return UIImageOrientationDown;
					break;
				case UIInterfaceOrientationLandscapeRight:
					return UIImageOrientationUp;
					break;
				default:
					break;
			}
			break;
			
		default:
			break;
	}
	//assert(0);
	return UIInterfaceOrientationPortrait;
}

+ (CGAffineTransform) transform:(UIInterfaceOrientation)from to:(UIInterfaceOrientation)to {
	UIImageOrientation orientation = [self orientation:from to:to];
	switch (orientation) {
		case UIImageOrientationUp:
			return CGAffineTransformIdentity;
		case UIImageOrientationDown:
			return CGAffineTransformMakeRotation(M_PI);
		case UIImageOrientationLeft:
			return CGAffineTransformMakeRotation(M_PI_2);
		case UIImageOrientationRight:
			return CGAffineTransformMakeRotation(-M_PI_2);
			
		default:
			return CGAffineTransformIdentity;
	}
}

- (void) willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	
	self.imageView.transform = [[self class] transform:self.imageOrientation to:toInterfaceOrientation];
}

- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	if (UI_USER_INTERFACE_IDIOM() != UIUserInterfaceIdiomPad) {
		CGRect r = self.passField.frame;
		if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
			r.origin.y = 80;
		} else {
			r.origin.y = 32;
		}
		self.passField.frame = r;
	}
	
}

- (void) viewWillLayoutSubviews {
	[super viewWillLayoutSubviews];
	
	CGRect r = self.view.frame;
	r.origin = CGPointZero;
	if ([UIDevice currentDevice].systemVersion.floatValue < 8.0 && UIInterfaceOrientationIsLandscape(self.interfaceOrientation)) {
		r.size.width = self.view.frame.size.height;
		r.size.height = self.view.frame.size.width;
	}
	self.imageView.frame = r;
}

#pragma mark-

- (UIStatusBarStyle) preferredStatusBarStyle {
	return UIStatusBarStyleLightContent;
}

@end
