//
//  TiledImageView.m
//  pixiViewer
//
//  Created by nya on 11/08/07.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import "TiledImageView.h"
#import "CGImageObject.h"


static CGRect MaxCenter(CGSize s, CGRect ir) {
    CGRect result;
    if(ir.size.height/ir.size.width>s.height/s.width){
        result.size.width=ir.size.width;
        result.size.height=s.height*ir.size.width/s.width;
        result.origin.x=ir.origin.x;
        result.origin.y=ir.origin.y+(ir.size.height-result.size.height)/2;
    }else{
        result.size.height=ir.size.height;
        result.size.width=s.width*ir.size.height/s.height;
        result.origin.y=ir.origin.y;
        result.origin.x=ir.origin.x+(ir.size.width-result.size.width)/2;
    }
    return result;
}


@implementation TiledImageLayer

@synthesize image;

- (id) initWithCGImageObject:(CGImageObject *)img {
	self = [super init];
	if (self) {
		self.image = img;
		
		CGRect r;
		r.origin = CGPointZero;
		r.size = img.size;
		
		self.tileSize = CGSizeMake(1000, 1000);
		//self.tileSize = CGSizeMake(800, 800);
		self.levelsOfDetail = 512;
		self.levelsOfDetailBias = 512;
		self.frame = r;
		self.backgroundColor = [UIColor clearColor].CGColor;
	}
	return self;
}

- (void) dealloc {	
	self.image = nil;
	[super dealloc];
}

#pragma mark-

- (void) drawInContext:(CGContextRef)ctx {	
	if (image) {
		CGRect r = MaxCenter(image.size, self.bounds);
		CGRect toRect;
		CGRect clip = CGContextGetClipBoundingBox(ctx);
		clip = CGRectIntersection(clip, r);
		if (CGRectIsNull(clip)) {
			return;
		}
		toRect = clip;
		
		clip.origin.x -= r.origin.x;
		clip.origin.y -= r.origin.y;
		
		clip.origin.x *= self.bounds.size.width / r.size.width;
		clip.size.width *= self.bounds.size.width / r.size.width;
		clip.origin.y *= self.bounds.size.height / r.size.height;
		clip.size.height *= self.bounds.size.height / r.size.height;
		
		//CGContextSetRGBFillColor(ctx, 1.0, 1.0, 1.0, 1.0);
		//CGContextFillRect(ctx, CGRectIntersection(CGContextGetClipBoundingBox(ctx), r));
		//CGContextTranslateCTM(ctx, 0.0, self.bounds.size.height);
		CGContextTranslateCTM(ctx, 0.0, 2 * toRect.origin.y + toRect.size.height);
		CGContextScaleCTM(ctx, 1.0, -1.0);
		
		CGImageRef img = CGImageCreateWithImageInRect(image.image, clip);
		CGContextDrawImage(ctx, toRect, img);
		CGImageRelease(img);
	}
}

- (void) setFrame:(CGRect)r {
	if (!CGRectEqualToRect(self.frame, r)) {
		[self setNeedsDisplay];
	}
	
	[super setFrame:r];
	r.origin = CGPointZero;
	self.bounds = r;
}

@end


@implementation TiledImageView

@synthesize image;

- (id) initWithImage:(CGImageObject *)img {
	self = [super initWithFrame:CGRectMake(0, 0, CGImageGetWidth(img.image), CGImageGetHeight(img.image))];
	if (self) {
		self.image = img;
	}
	return self;
}

- (void) dealloc {
	self.image = nil;
	[super dealloc];
}

- (void) setImage:(CGImageObject *)img {
	if (img == image) {
		return;
	}
	
	[image release];
	image = [img retain];
	
	[layer removeFromSuperlayer];
	layer = nil;
	
	CGRect r = self.frame;
	r.origin = CGPointZero;
	layer = [[[TiledImageLayer alloc] initWithCGImageObject:image] autorelease];
	layer.frame = r;
	[self.layer addSublayer:layer];
	
	[self setNeedsDisplay];
}

@end
