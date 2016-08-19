//
//  PixivMangaPageViewController.h
//  pixiViewer
//
//  Created by nya on 10/05/16.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@class PixService;
@class ImageCache;

@protocol PixivMangaPageViewControllerDelegate
- (PixService *) pixiv;
- (ImageCache *) cache;
- (NSString *) referer;
- (void) singleTapAtPoint:(CGPoint)tapPoint;
- (void) loadImageFinished:(id)sender;
@end


@interface PixivMangaPageViewController : UIViewController<UIScrollViewDelegate> {
	UIScrollView	*scrollView;
	UIImageView *imageView;

	NSString		*illustID;
	NSString		*urlString;

	NSURLConnection	*imageConnection;
	NSMutableData	*imageData;
	long long		imageSize;

	CGFloat fitScale;
	CGFloat initialScale;

	id<PixivMangaPageViewControllerDelegate> delegate;
}

@property(readwrite, nonatomic, assign) id<PixivMangaPageViewControllerDelegate> delegate;
@property(readwrite, nonatomic, retain) NSString *urlString;
@property(readwrite, nonatomic, retain) NSString *illustID;
@property(readonly, nonatomic, assign) UIImage *image;

- (void) load;
- (void) loadImageCancel;
- (void) clear;
- (void) setImage:(UIImage *)img;
- (UIScrollView *) scrollView;

@end
