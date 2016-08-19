//
//  TumblrMatrixViewController2.h
//  pixiViewer
//
//  Created by nya on 10/02/15.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PixivMatrixViewController.h"


@class PixAccount;

@interface TumblrMatrixViewController2 : PixivMatrixViewController {
	NSString *name;
	BOOL needsAuth;
	NSTimer *reloadTimer;
}

@property(readwrite, nonatomic, retain) NSString *name;
@property(readwrite, nonatomic, assign) BOOL needsAuth;

@end
