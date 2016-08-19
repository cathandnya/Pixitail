//
//  CGImageObject.m
//  ComicViewer_iPhone
//
//  Created by nya on 11/05/07.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "CGImageObject.h"


@implementation CGImageObject

@synthesize image;
@dynamic size;

- (id) initWithCGImage:(CGImageRef)img {
	self = [super init];
	if (self) {
		if (!img) {
			[self release];
			return nil;
		}
		self.image = img;
	}
	return self;
}

- (id) initWithJPG:(NSData *)data {
	self = [super init];
	if (self) {
		CGImageRef img = NULL;
		if (data) {
			CGDataProviderRef prov = CGDataProviderCreateWithCFData((CFDataRef)data);
			img = CGImageCreateWithJPEGDataProvider(prov, NULL, FALSE, kCGRenderingIntentDefault);
			CGDataProviderRelease(prov);
		}
		if (img) {
			self.image = img;
			CGImageRelease(img);
		} else {
			[self release];
			return nil;
		}
	}
	return self;
}

- (id) initWithPNG:(NSData *)data {
	self = [super init];
	if (self) {
		CGImageRef img = NULL;
		if (data) {
			CGDataProviderRef prov = CGDataProviderCreateWithCFData((CFDataRef)data);
			img = CGImageCreateWithPNGDataProvider(prov, NULL, FALSE, kCGRenderingIntentDefault);
			CGDataProviderRelease(prov);
		}
		if (img) {
			self.image = img;
			CGImageRelease(img);
		} else {
			[self release];
			return nil;
		}
	}
	return self;
}

- (void) dealloc {
	self.image = NULL;
	[super dealloc];
}

- (void) setImage:(CGImageRef)img {
	if (image != img) {
		if (image) {
			CGImageRelease(image);
			image = NULL;
		}
		image = img;
		if (image) {
			CGImageRetain(image);
		}
	}
}

- (CGSize) size {
	return CGSizeMake(CGImageGetWidth(image), CGImageGetHeight(image));
}

@end
