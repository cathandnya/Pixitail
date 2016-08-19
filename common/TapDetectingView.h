//
//  TapDetectingView.h
//  Tumbltail
//
//  Created by nya on 10/11/14.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@class TapDetectingView;
/*
 Protocol for the tap-detecting image view's delegate.
 */
@protocol TapDetectingViewDelegate <NSObject>

@optional
- (void)tapDetectingView:(TapDetectingView *)view gotSingleTapAtPoint:(CGPoint)tapPoint;
- (void)tapDetectingView:(TapDetectingView *)view gotDoubleTapAtPoint:(CGPoint)tapPoint;
- (void)tapDetectingView:(TapDetectingView *)view gotTwoFingerTapAtPoint:(CGPoint)tapPoint;

@end


@interface TapDetectingView : UIView {
    id <TapDetectingViewDelegate> delegate;
    
    // Touch detection
    CGPoint tapLocation;         // Needed to record location of single tap, which will only be registered after delayed perform.
    BOOL multipleTouches;        // YES if a touch event contains more than one touch; reset when all fingers are lifted.
    BOOL twoFingerTapIsPossible; // Set to NO when 2-finger tap can be ruled out (e.g. 3rd finger down, fingers touch down too far apart, etc).
}

@property (nonatomic, assign) id <TapDetectingViewDelegate> delegate;

@end
