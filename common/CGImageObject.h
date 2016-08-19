//
//  CGImageObject.h
//  ComicViewer_iPhone
//
//  Created by nya on 11/05/07.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface CGImageObject : NSObject {
	CGImageRef image;
}

- (id) initWithCGImage:(CGImageRef)img;
- (id) initWithJPG:(NSData *)data;
- (id) initWithPNG:(NSData *)data;

@property(readwrite, nonatomic, assign) CGImageRef image;
@property(readonly, nonatomic, assign) CGSize size;

@end


