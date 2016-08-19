//
//  TumblrBigViewController.h
//  pixiViewer
//
//  Created by nya on 10/01/25.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PixivBigViewController.h"


@interface TumblrBigViewController : PixivBigViewController {
	NSDictionary *info;
}

@property(retain, nonatomic, readwrite) NSDictionary *info;

@end
