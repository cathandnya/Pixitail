//
//  PixivSlideshowViewController.h
//  pixiViewer
//
//  Created by nya on 09/09/06.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CHHtmlParser.h"
#import "CHHtmlParserConnection.h"
#import "MatrixParser.h"
#import "MediumParser.h"
#import "PixService.h"
#import "DefaultViewController.h"


@class ImageCache;
@class SlideshowImageStorage;
@protocol SlideshowImageStorageDelegate
- (void) storage:(SlideshowImageStorage *)sender loadIllust:(NSDictionary *)info finished:(long)err;
- (NSString *) referer;
- (PixService *) pixiv;
- (MediumParser *) mediumParser;
- (NSString *) mediumURL:(NSString *)str;
- (ImageCache *) cache;
@end


@class ClockView;
@class PixAccount;
@interface PixivSlideshowViewController : DefaultViewController<MatrixParserDelegate, CHHtmlParserConnectionDelegate, UIActionSheetDelegate, SlideshowImageStorageDelegate> {
	UIImageView		*imageView1_;
	UIImageView		*imageView2_;
	BOOL			transitioning;
	NSDictionary	*currentInfo_;
	ClockView		*clockView;

	NSTimer			*reloadTimer_;

	MatrixParser				*matrixParser_;
	CHHtmlParserConnection		*matrixConnection_;
	NSString					*method;
	int							loadedPage_;
	int							maxPage_;
	BOOL						pictureIsFound_;
	BOOL						loadingMatrix_;
	
	SlideshowImageStorage		*storage_;
	NSRange						needsLoadIllustIndexRange_;
	NSInteger							needsLoadIllustIndex_;
	
	NSTimer						*slideTimer_;
	
	NSMutableArray		*illustIDs_;
	NSMutableArray		*illustIDsTmp_;
	BOOL				paused_;
	BOOL				started_;
	BOOL				random_;
	BOOL				reverse;
	NSInteger			displayIllistIndex_;

	PixAccount *account;
	
	UIActionSheet *actionSheet_;
}

@property(retain, nonatomic, readwrite) NSString *method;
@property(retain, nonatomic, readwrite) IBOutlet ClockView *clockView;
@property(retain, nonatomic, readwrite) PixAccount *account;
@property(retain, nonatomic, readwrite) NSString *scrapingInfoKey;

- (void) setContents:(NSArray *)ary random:(BOOL)b;
- (void) setContents:(NSArray *)ary random:(BOOL)b reverse:(BOOL)rev;
- (void) setPage:(int)p;
- (void) setMaxPage:(int)p;

@end


@interface ClockView : UIView {
	UILabel *dateLabel;
	UILabel *timeLabel;
	NSTimer *timer_;
	NSDateFormatter *timeFormatter_;
	NSDateFormatter *dateFormatter_;
}

@property(readwrite, nonatomic, retain) IBOutlet UILabel *dateLabel;
@property(readwrite, nonatomic, retain) IBOutlet UILabel *timeLabel;

- (void)viewDidLoad;
- (void)viewDidUnload;

@end

