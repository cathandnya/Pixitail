//
//  RoundedRectView.h
//
//  Created by nya on 11/04/13.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface RoundedRectView : UIView {
    UIColor *color;
	CGFloat radius;
}

@property(readwrite, nonatomic, retain) UIColor *color;
@property(readwrite, nonatomic, assign) CGFloat radius;

@end
