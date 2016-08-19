//
//  CHURLImageView.h
//  pixiViewer
//
//  Created by nya on 09/08/19.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@class ImageCache;


typedef enum {
	CHURLImageViewImagePosition_Fill,
	CHURLImageViewImagePosition_MaxCenter,
} CHURLImageViewImagePosition;


@interface CHURLImageView : UIImageView {
	NSString	*urlString;
	id			object;
	CHURLImageViewImagePosition	imagePosition;
	
	NSString		*referer;
	NSURLConnection	*imageConnection_;
	NSMutableData	*imageData_;
	long long		imageDataLength_;
	
	ImageCache	*cache;
}

@property(retain, readwrite, nonatomic) NSString *urlString;
@property(retain, readwrite, nonatomic) NSString *referer;
@property(retain, readwrite, nonatomic) id object;
@property(assign, readwrite, nonatomic) CHURLImageViewImagePosition imagePosition;
@property(assign, readwrite, nonatomic) ImageCache *cache;

- (void) setLoadedImage:(NSData *)img;

- (void) clear;
- (void) cancel;

@end
