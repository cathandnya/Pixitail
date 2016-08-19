//
//  SheetViewController.h
//
//  Created by nya on 10/02/05.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DefaultViewController.h"


@interface SheetViewController : DefaultViewController {
    UIWindow *panel;
}

@property(readwrite, assign, nonatomic) BOOL isPresent;

- (CGFloat) height;
- (CGFloat) width;
- (CGFloat) animationDuration;
- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context;

- (void) hide;
- (void) show;

- (void) present;
- (void) dismiss;
- (void) toggle;

@end
