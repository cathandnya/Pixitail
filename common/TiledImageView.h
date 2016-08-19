//
//  TiledImageView.h
//  pixiViewer
//
//  Created by nya on 11/08/07.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>


@class CGImageObject;


@interface TiledImageLayer : CATiledLayer {
	CGImageObject *image;
}

@property(readwrite, nonatomic, retain) CGImageObject *image;

- (id) initWithCGImageObject:(CGImageObject *)img;

@end


@interface TiledImageView : UIView {
	CGImageObject *image;
	TiledImageLayer *layer;
}

@property(readwrite, nonatomic, retain) CGImageObject *image;

- (id) initWithImage:(CGImageObject *)img;

@end
