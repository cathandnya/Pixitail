//
//  PasscodeLockViewController.h
//  Tumbltail
//
//  Created by nya on 11/04/19.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SheetViewController.h"


@class PasscodeLockViewController;


@protocol PasscodeLockViewControllerDelegate <NSObject>
- (void) passcodeLockViewControllerFinished:(PasscodeLockViewController *)sender;
@end


@interface PasscodeLockViewController : SheetViewController {
}

@property(weak, nonatomic) IBOutlet UIImageView *imageView;
@property(weak, nonatomic) IBOutlet UILabel *label;
@property(weak, nonatomic) IBOutlet UITextField *passField;
@property(strong) NSString *password;
@property(weak) id<PasscodeLockViewControllerDelegate> delegate;

- (id) init;

//- (void) setBackView:(UIView *)view;

@end
