//
//  StatusMessageViewController.h
//  pixiViewer
//
//  Created by nya on 11/09/04.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SheetViewController.h"

@interface StatusMessageViewController : SheetViewController {
	UILabel *label;
	UILabel *label2;
	UIView *baseView;
	
	UILabel *showLabel;
	UILabel *hideLabel;
	
	NSTimer *timer;
	NSTimeInterval displayDuration;
	NSMutableArray *messageQueue;
}

@property (nonatomic, retain) IBOutlet UILabel *label;
@property (nonatomic, retain) IBOutlet UILabel *label2;
@property (nonatomic, retain) IBOutlet UIView *baseView;

@property(readwrite, nonatomic, assign) NSTimeInterval displayDuration;

+ (StatusMessageViewController *) sharedInstance;

- (void) showMessage:(NSString *)msg;
- (void) clear;

@end
