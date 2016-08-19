//
//  AlwaysSplitViewController.h
//  Pictures
//
//  Created by nya on 11/01/02.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface AlwaysSplitViewController : UIViewController {
	UIView *rootView;
	UIView *detailView;

	UIViewController *rootViewController;
	UIViewController *detailViewController;
}

@property(readwrite, nonatomic, retain) UIViewController *rootViewController;
@property(readwrite, nonatomic, retain) UIViewController *detailViewController;

- (BOOL) rootIsHidden;
- (void) setRootHidden:(BOOL)hide animated:(BOOL)b;

@end
