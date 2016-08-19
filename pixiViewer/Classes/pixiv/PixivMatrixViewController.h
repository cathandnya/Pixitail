//
//  PixivMatrixViewController.h
//  pixiViewer
//
//  Created by nya on 09/08/19.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "DefaultViewController.h"
#import "MatrixParser.h"
#import "CHHtmlParserConnection.h"
//#import "CHMatrixView.h"
#import "PixivMatrixParser.h"
#import "CHURLImageLoader.h"
#import "PixService.h"


#define MATRIXPARSER_IMAGELOADER_COUNT	16


@class AsyncImageLoader;
@class PixAccount;
@class PerformMainObject;
@class ImageCache;


@interface PixivMatrixViewController : DefaultTableViewController<MatrixParserDelegate, CHHtmlParserConnectionDelegate, UIScrollViewDelegate, UIActionSheetDelegate, UITableViewDelegate, UITableViewDataSource, CHURLImageLoaderDelegate, PixServiceLoginHandler> {
	id							parser_;
	CHHtmlParserConnection		*connection_;
	NSString					*method;
	int							loadedPage_;
	int							maxPage_;
	BOOL						pictureIsFound_;
	
	NSMutableArray	*contents_;
	BOOL			showsNextButton_;
	NSInteger		columnSize_;
	BOOL			aspectFill;
	
	NSMutableSet	*loadingLoaders_;
	NSMutableArray	*pendingLoaders_;
	
	NSMutableDictionary *imageViews_;
	NSMutableDictionary *progressViews_;

	AsyncImageLoader *loader_;
	
	CGPoint displayedOffset_;
	
	PixAccount *account;

	NSArray	*storedContents;
	
	PerformMainObject *foundPicMain;
	PerformMainObject *finishedMain;
	PerformMainObject *loadedMain;
	
	UIActionSheet *actionSheet;
}

@property(retain, nonatomic, readwrite) NSString *method;
@property(retain, nonatomic, readwrite) PixAccount *account;
@property(retain, nonatomic, readwrite) NSString *scrapingInfoKey;

- (void) reflesh;
- (void) loadNextImage;
- (ImageCache *) cache;

- (CGFloat) topMargin;
- (UITableView *) matrixView;

- (NSString *) nextIID:(NSString *)iid;
- (NSString *) prevIID:(NSString *)iid;
- (NSDictionary *) nextInfo:(NSString *)iid;
- (NSDictionary *) prevInfo:(NSString *)iid;
- (NSDictionary *) infoForIllustID:(NSString *)iid;

- (void) push:(NSData *)data withInfo:(NSDictionary *)pic;

- (int) columnCount;
- (UIImage *) squareTrimmedImage:(UIImage *)img;

- (void) restoreContents;
- (void) loadImage:(NSDictionary *)info;

- (void) matrixParserFoundPictureMain:(NSDictionary *)pic;
- (void) matrixParserFinishedMain:(NSNumber *)num;

@end


@interface ButtonImageView : UIImageView {
	BOOL touchBegan_;
	SEL action_;
	id target_;
	id object;
}

@property(retain, nonatomic, readwrite) id object;

- (void) setTarget:(id)obj withAction:(SEL)sel;
+ (void)removeSelectLayer;

@end

