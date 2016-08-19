//
//  ProgressViewController.h
//  EchoPro
//
//  Created by nya on 09/10/03.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@class ProgressBackView;
@interface ProgressViewController : UIViewController {
	UIProgressView	*progressView;
	UIActivityIndicatorView *activityView;
	UILabel *textView;
	UIButton *cancelButton;
	ProgressBackView *backView;
	
	SEL		cancelAction;
	id		cancelTarget;
	
	BOOL showActivity;
	int tag;
	NSString *text;
}

@property(readwrite, retain, nonatomic) IBOutlet UIProgressView *progressView;
@property(readwrite, retain, nonatomic) IBOutlet UIActivityIndicatorView *activityView;
@property(readwrite, retain, nonatomic) IBOutlet UILabel *textView;
@property(readwrite, retain, nonatomic) IBOutlet UIButton *cancelButton;
@property(readwrite, retain, nonatomic) IBOutlet ProgressBackView *backView;
@property(readwrite, assign, nonatomic) BOOL showActivity;
@property(readwrite, assign, nonatomic) int tag;
@property(readwrite, retain, nonatomic) NSString *text;

- (void) setDoubleValue:(double)val;
- (void) setCancelAction:(SEL)sel toTarget:(id)target;

- (IBAction) cancel;

@end
