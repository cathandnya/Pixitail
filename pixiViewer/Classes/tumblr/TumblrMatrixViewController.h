//
//  TumblrMatrixViewController.h
//  pixiViewer
//
//  Created by nya on 10/01/22.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PixivMatrixViewController.h"


@class TwitterParser;
@class CHHtmlParserConnection;
@class PixAccount;

@interface TumblrMatrixViewController : PixivMatrixViewController {
	NSMutableSet	*loadingTumblrLoaders_;
	NSMutableArray	*pendingTumblrLoaders_;
	NSString *maxID_;
}

@end
