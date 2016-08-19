//
//  PixivBigViewController.h
//  pixiViewer
//
//  Created by nya on 09/08/19.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BigParser.h"
#import "CHHtmlParserConnection.h"
#import "DefaultViewController.h"


@class PixService;
@class ImageCache;
@class PixivMediumViewController;
@class CGImageObject;
@class PixivUgoIllust;
@class PixivUgoIllustPlayer;


@interface PixivBigViewController : DefaultViewController<UIScrollViewDelegate, CHHtmlParserConnectionDelegate> {
	UIScrollView	*scrollView_;
	UIProgressView *progressVIew;

	NSString		*illustID;
	NSString		*urlString_;
	
	id						parser_;
	CHHtmlParserConnection	*connection_;
	
	//NSURLConnection	*imageConnection_;
	//NSMutableData	*imageData_;
	//long long		imageSize_;
	
	UISlider *slider_;
	CGFloat fitScale;
	CGFloat initialScale;
	
	id parent;
	
	UIActionSheet *actionSheet_;
	PixivUgoIllustPlayer *player;
}

@property(readwrite, retain, nonatomic) IBOutlet UIScrollView *scrollView_;
@property (retain, nonatomic) IBOutlet UIImageView *imageView;
@property (nonatomic, retain) IBOutlet UIProgressView *progressVIew;
@property (retain, nonatomic) IBOutlet UITapGestureRecognizer *tapGestureRecognizer;
@property (retain, nonatomic) IBOutlet UITapGestureRecognizer *doubleTapGestureRecognizer;

@property(readwrite, retain, nonatomic) NSString *illustID;
@property(readwrite, retain, nonatomic) NSString *urlString;
@property(readwrite, retain, nonatomic) PixivUgoIllust *ugoIllust;


- (PixService *) pixiv;
- (void) update;
- (void) updateDisplay;
- (UIScrollView *) scrollView;
- (void) setImage:(UIImage *)img;
- (NSString *) currentImageKey;
- (void) loadImage;

- (PixivMediumViewController *) parentMedium;
- (BOOL) infoIsValid:(NSDictionary *)info;
- (NSString *) nextIID;
- (NSString *) prevIID;
- (void) replaceViewController:(UIViewController *)vc;

@end
