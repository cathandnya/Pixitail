//
//  PixivPicture.h
//  pixiViewerTest
//
//  Created by nya on 09/08/18.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


#ifdef MACOS
	#define UIImage NSImage
#endif


@interface PixivPicture : NSObject {
	NSString	*illustID;
	NSString	*userName;
	NSString	*userID;
	NSURL		*thumbnail;
	NSURL		*image;
}

@property(nonatomic, readwrite, retain) NSString *illustID;
@property(nonatomic, readwrite, retain) NSString *userName;
@property(nonatomic, readwrite, retain) NSString *userID;
@property(nonatomic, readwrite, retain) NSURL *thumbnail;
@property(nonatomic, readwrite, retain) NSURL *image;

@end
