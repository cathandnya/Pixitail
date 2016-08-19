//
//  StatusMessageViewController.m
//  pixiViewer
//
//  Created by nya on 11/09/04.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import "StatusMessageViewController.h"


@interface SheetWindow : UIWindow
@end


@implementation SheetWindow

- (void) layoutSubviews {
	[super layoutSubviews];
	
	//DLog(@"self.frame: %@", NSStringFromCGRect(self.frame));
	//DLog(@"0.frame: %@", NSStringFromCGRect([[self.subviews objectAtIndex:0] frame]));
	UIView *v = [self.subviews objectAtIndex:0];
	CGRect r = self.frame;
	r.origin = CGPointZero;
	v.frame = r;
}

@end


@interface StatusMessageViewController(Private)
- (void) showNext;
@end


@implementation StatusMessageViewController

@synthesize label;
@synthesize label2;
@synthesize baseView;
@synthesize displayDuration;

+ (StatusMessageViewController *) sharedInstance {
	static StatusMessageViewController *obj = nil;
	if (!obj) {
		obj = [[StatusMessageViewController alloc] initWithNibName:@"StatusMessageViewController" bundle:nil];
		[obj view];
	}
	return obj;
}

- (id) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
	self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
	if (self) {
		messageQueue = [[NSMutableArray alloc] init];
		displayDuration = 2.5;
	}
	return self;
}

- (void)dealloc {
    [label release];
	[messageQueue release];
	
	[label2 release];
	[baseView release];
    [super dealloc];
}

- (void) viewDidLoad {
	//[super viewDidLoad];
	
	showLabel = label;
	hideLabel = label2;
}

- (void)viewDidUnload {
    [self setLabel:nil];
	[self setLabel2:nil];
	showLabel = nil;
	hideLabel = nil;
	
	[self setBaseView:nil];
    [super viewDidUnload];
}

#pragma mark-

- (CGFloat) height {
	return 20;
}

- (CGFloat) width {
	if ([UIDevice currentDevice].systemVersion.floatValue >= 8.0) {
		return self.view.frame.size.width;
	} else {
		if (UIInterfaceOrientationIsPortrait(self.interfaceOrientation)) {
			return self.view.frame.size.width;
		} else {
			return self.view.frame.size.height;
		}
	}
}

#pragma mark-

- (BOOL) isPresent {
	return panel != nil && !panel.hidden;
}

- (void) hide {
	showLabel.frame = CGRectMake(0, [self height], [self width], [self height]);
}

- (void) show {
    showLabel.frame = CGRectMake(0, 0, [self width], [self height]);
}

- (void)present {
    if (self.isPresent) {
		return;
	}
	
    showLabel.frame = CGRectMake(0, -[self height], [self width], [self height]);
    
    //[panel release];
	UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
	if (!panel) {
		CGRect r = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
		panel = [[SheetWindow alloc] initWithFrame:r];
		panel.windowLevel = UIWindowLevelStatusBar + 1;
		panel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
		panel.userInteractionEnabled = NO;
		r.origin = CGPointZero;
		self.view.frame = r;
		[panel setRootViewController:self];
		//[panel addSubview:self.view];
		[panel makeKeyAndVisible];
		[keyWindow makeKeyWindow];
	} else {
		panel.hidden = NO;
	}
	
	baseView.frame = CGRectMake(0, 0, [self width], 20);
	showLabel.frame = CGRectMake(0, -[self height], [self width], [self height]);
	hideLabel.frame = CGRectMake(0, -[self height], [self width], [self height]);
    
	if ([self animationDuration] > 0) {
		[UIView beginAnimations:@"showAnimation" context:nil];
		[UIView setAnimationDuration:[self animationDuration]];
		[UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
		[UIView setAnimationDelegate:self];
		[UIView setAnimationDidStopSelector:@selector(showAnimationDidStop:finished:context:)];
    }
    [self show];
	if ([self animationDuration] > 0) {
		[UIView commitAnimations];
	}
}

- (void)dismiss
{
    if (!self.isPresent) {
		return;
	}
	
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    [keyWindow makeKeyWindow];
	if ([self animationDuration] > 0) {
		[UIView beginAnimations:@"presentEmojiPanel" context:nil];
		[UIView setAnimationDelegate:self];
		[UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
		[UIView setAnimationDuration:[self animationDuration]];
	}
	[self hide];
	if ([self animationDuration] > 0) {
		[UIView commitAnimations];
	} else {
		//[panel resignKeyWindow];
		//[panel release];
		//panel = nil;
		panel.hidden = YES;
	}
}

- (void) showAnimationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
	
}

- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
	panel.hidden = YES;
	//[panel resignKeyWindow];
	//[panel release];
	//panel = nil;
	[self showNext];
}

#pragma mark-

- (void) showNext {
	[self view];
	if (timer) {
		return;
	}
	
	if (messageQueue.count == 0) {
		if (!panel.hidden) {
			[self dismiss];
		}
	} else {
		NSString *msg = nil;
		do {
			msg = [[[messageQueue objectAtIndex:0] retain] autorelease];
			[messageQueue removeObjectAtIndex:0];
		} while (msg.length == 0 && messageQueue.count > 0);
		
		if (panel && !panel.hidden) {
			if (showLabel.frame.origin.y == 0) {
				// 表示中
				id tmp = hideLabel;
				hideLabel = showLabel;
				showLabel = tmp;

				showLabel.text = msg;
				showLabel.frame = CGRectMake(0, -[self height], [self width], [self height]);
				[UIView beginAnimations:@"showAnimation" context:nil];
				[UIView setAnimationDuration:[self animationDuration]];
				[UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
				showLabel.frame = CGRectMake(0, 0, [self width], [self height]);
				hideLabel.frame = CGRectMake(0, [self height], [self width], [self height]);
				[UIView commitAnimations];
			} else {
				// 非表示アニメーション中
				[messageQueue insertObject:msg atIndex:0];
				return;
			}
		} else {
			// 非表示中
			showLabel.text = msg;
			[self present];
		}
		
		[timer invalidate];
		timer = [NSTimer scheduledTimerWithTimeInterval:displayDuration target:self selector:@selector(timerAction:) userInfo:nil repeats:NO];
	}
}

- (void) showMessage:(NSString *)msg {
	if (msg) {
		[messageQueue addObject:msg];
		[self showNext];
	}
}

- (void) clear {
	[timer invalidate];
	timer = nil;
	
	[messageQueue removeAllObjects];
	[self showNext];
}

- (void) timerAction:(NSTimer *)t {
	timer = nil;
	[self showNext];
}

@end
