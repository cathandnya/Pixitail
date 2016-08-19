//
//  PixivMatrixViewController.m
//  pixiViewer
//
//  Created by nya on 09/08/19.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PixivMatrixViewController.h"
#import "PixivMediumViewController.h"
#import "PixivMatrixParser.h"
#import "PixivSlideshowViewController.h"
#import "Pixiv.h"
#import "ImageDiskCache.h"
#import "AccountManager.h"
#import <QuartzCore/QuartzCore.h>
#import <pthread.h>
#import "PerformMainObject.h"
#import "PixiViewerAppDelegate.h"
#import "AlwaysSplitViewController.h"
#import "AdmobHeaderView.h"
#import "PixitailConstants.h"
#import "CHHtmlParserConnectionNoScript.h"


static CGRect maxCenter(CGSize s, CGRect ir) {
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

static CGContextRef createBitmapContext (int pixelsWide, int pixelsHigh) {
	CGContextRef   bitmapContext=NULL;
	void        *bitmapData;
	CGColorSpaceRef colorSpace;

	if( (bitmapData=calloc( 1,pixelsWide*pixelsHigh*4 )) ) // 画像用メモリ確保
	{
		colorSpace=CGColorSpaceCreateDeviceRGB(); // カラースペースを設定
		bitmapContext=CGBitmapContextCreate( bitmapData,pixelsWide,pixelsHigh,8,pixelsWide*4,colorSpace,kCGImageAlphaPremultipliedLast );
		if(!bitmapContext)  // オフスクリーン用CGContextRef作成
			free( bitmapData ); // 失敗した場合にはメモリを解放する
		CGColorSpaceRelease( colorSpace );
	}
	return bitmapContext;
}

static void fitBounds(BOOL fill, CGSize size, CGRect *fr, CGRect *dr) {
	if (fill) {
		// trim
		dr->size = size;
		dr->origin = CGPointZero;
		if (fr->size.width > fr->size.height) {
			fr->origin.x = (fr->size.width - fr->size.height) / 2.0;
			fr->origin.y = 0;
			fr->size.width = fr->size.height;
			fr->size.height = fr->size.height;
		} else {
			fr->origin.x = 0;
			fr->origin.y = (fr->size.height - fr->size.width) / 2.0;
			fr->size.width = fr->size.width;
			fr->size.height = fr->size.width;
		}
	} else {
		dr->size = size;
		dr->origin = CGPointZero;
		*dr = maxCenter(fr->size, *dr);
		fr->origin = CGPointZero;
		fr->size = size;
	}
}

static CGImageRef createResizedCGImage(CGImageRef simg, CGFloat width, CGFloat height, BOOL fill) {
	CGRect     srt,frt,drt;
	void      *bitmapData;
	CGImageRef  dimg=NULL;
	CGFloat     ww,hh;
	CGContextRef ctx;
	
	ww=(CGFloat)CGImageGetWidth( simg ); // 画像の幅を得る
	hh=(CGFloat)CGImageGetHeight( simg ); // 画像の高さを得る
	srt=CGRectMake( 0.0,0.0,ww,hh );
	
	if (fill) {
		if (ww < hh) {
			if (ww < width) {
				height *= ww / width;
				width = ww;
			} else if (hh < height) {
				width *= hh / height;
				height = hh;
			}
		} else {
			if (hh < height) {
				width *= hh / height;
				height = hh;
			} else if (ww < width) {
				height *= ww / width;
				width = ww;
			}
		}
	} else {
		if (ww < hh) {
			if (hh < height) {
				width *= hh / height;
				height = hh;
			} else if (ww < width) {
				height *= ww / width;
				width = ww;
			}
		} else {
			if (ww < width) {
				height *= ww / width;
				width = ww;
			} else if (hh < height) {
				width *= hh / height;
				height = hh;
			}
		}
	}
	frt=CGRectMake( 0.0,0.0,width,height );

	fitBounds( fill,frt.size,&srt,&drt );  //  矩形の縦横比を合わせる自作ルーチン
	ctx=createBitmapContext( width,height );
	if( ctx ) // オフスクリーン用CGContextRefが得られたか？
	{
		CGContextSetFillColor(ctx, CGColorGetComponents([UIColor whiteColor].CGColor));
		CGContextFillRect(ctx, drt);
		if (fill) {
			CGImageRef tmp = CGImageCreateWithImageInRect(simg, srt);
			CGContextDrawImage( ctx,drt,tmp );    // オリジナル画像を描画
			CGImageRelease(tmp);
		} else {
			CGContextDrawImage( ctx,drt,simg );    // オリジナル画像を描画
		}
		dimg=CGBitmapContextCreateImage( ctx ); // CGImageRefを得る
		if( (bitmapData=CGBitmapContextGetData( ctx )) ) // 使用メモリを解放
			free( bitmapData );
		CGContextRelease( ctx ); // CGImageRefを解放 
	}
	return dimg;
}

static UIImage *resizeImage(UIImage *img, CGSize size, BOOL fill) {
	CGImageRef cgimg = createResizedCGImage(img.CGImage, size.width, size.height, fill);	
	UIImage *ret = [UIImage imageWithCGImage:cgimg];
//#if (TARGET_IPHONE_SIMULATOR)
//#else
	CGImageRelease(cgimg);
//#endif
	return ret;
}
/*
static UIImage *whiteBackedImage(UIImage *img) {
	if (img == nil) {
		return nil;
	}
	
	UIImage *newImage;

	UIGraphicsBeginImageContext(img.size);
			
	[[UIColor whiteColor] set];
	UIRectFill(CGRectMake(0, 0, img.size.width, img.size.height));
			
	[img drawAtPoint:CGPointZero];
	newImage = UIGraphicsGetImageFromCurrentImageContext();

	UIGraphicsEndImageContext();	
	
	return newImage;		
}
*/

static UIImage *whiteBackedImage(UIImage *img) {
	NSData *jpeg = UIImageJPEGRepresentation(img, 0.8);
	return [UIImage imageWithData:jpeg];
}

/*
static UIImage *whiteBackedImage(UIImage *img) {
	// CGImageを取得する
	CGImageRef cgImage;
	cgImage = img.CGImage;
 
	// 画像情報を取得する
	size_t width;
	size_t height;
	size_t bitsPerComponent;
	size_t bitsPerPixel;
	size_t bytesPerRow;
	CGColorSpaceRef colorSpace;
	CGBitmapInfo bitmapInfo;
	bool shouldInterpolate;
	CGColorRenderingIntent intent;
	CGImageAlphaInfo alphaInfo;
	width = CGImageGetWidth(cgImage);
	height = CGImageGetHeight(cgImage);
	bitsPerComponent = CGImageGetBitsPerComponent(cgImage);
	bitsPerPixel = CGImageGetBitsPerPixel(cgImage);
	bytesPerRow = CGImageGetBytesPerRow(cgImage);
	colorSpace = CGImageGetColorSpace(cgImage);
	bitmapInfo = CGImageGetBitmapInfo(cgImage);
	shouldInterpolate = CGImageGetShouldInterpolate(cgImage);
	intent = CGImageGetRenderingIntent(cgImage);
	alphaInfo = CGImageGetAlphaInfo(cgImage);
	
	if (bitsPerPixel / bitsPerComponent != 4) {
		// alphaなし
		return img;
	}
 
	// データプロバイダを取得する
	CGDataProviderRef dataProvider = CGImageGetDataProvider(cgImage);
 
	// ビットマップデータを取得する
	CFDataRef data = CGDataProviderCopyData(dataProvider);
	UInt8* buffer = (UInt8*)CFDataGetBytePtr(data);
 
	// ビットマップに効果を与える
	NSUInteger i, j;
	NSUInteger idx = (alphaInfo == kCGImageAlphaLast ? 3 : 0);
	for (j = 0 ; j < height; j++) {
		for (i = 0; i < width; i++)  {
			// ピクセルのポインタを取得する
			if (bitsPerComponent == 8) {
				UInt8 *tmp = buffer + j * bytesPerRow + i * 4;
				tmp[idx] = 0xFF;
			} else if (bitsPerComponent == 16) {
				UInt16 *tmp = (UInt16 *)(buffer + j * bytesPerRow + i * 4 * 2);
				tmp[idx] = 0xffff;
			}
		}
	}
	
	// 効果を与えたデータを作成する
	CFDataRef effectedData;
	effectedData = CFDataCreate(NULL, buffer, CFDataGetLength(data));
 
	// 効果を与えたデータプロバイダを作成する
	CGDataProviderRef effectedDataProvider;
	effectedDataProvider = CGDataProviderCreateWithCFData(effectedData);
 
	// 画像を作成する
	CGImageRef effectedCgImage = CGImageCreate(
		 width, height, 
		 bitsPerComponent, bitsPerPixel, bytesPerRow, 
		 colorSpace, bitmapInfo, effectedDataProvider, 
		 NULL, shouldInterpolate, intent);
 
	UIImage* effectedImage = [[[UIImage alloc] initWithCGImage:effectedCgImage] autorelease];
 
	// 作成したデータを解放する
	CGImageRelease(effectedCgImage);
	CFRelease(effectedDataProvider);
	CFRelease(effectedData);
	CFRelease(data);	
 
	return effectedImage;
}
*/
/*
static UIImage *whiteBackedImage(UIImage *img) {
	if (img == nil) {
		return nil;
	}
	
	UIImage *newImage;

	UIGraphicsBeginImageContext(img.size);
			
	[[UIColor whiteColor] set];
	UIRectFill(CGRectMake(0, 0, img.size.width, img.size.height));
			
	[img drawAtPoint:CGPointZero];
	newImage = UIGraphicsGetImageFromCurrentImageContext();

	UIGraphicsEndImageContext();	
	
	return newImage;		
}
*/


@implementation ButtonImageView

@synthesize object;
static CALayer *selectLayer = nil;

- (id) init {
	self = [super init];
	if (self) {
		self.userInteractionEnabled = YES;
		touchBegan_ = NO;
	}
	return self;
}

- (void) dealloc {
	DLog(@"ButtonImageView dealloc: %@", [self.object objectForKey:@"IllustID"]);
	self.image = nil;
	[object release];
	[super dealloc];
}

- (void) setTarget:(id)obj withAction:(SEL)sel {
	target_ = obj;
	action_ = sel;
}

#pragma mark tauches

+ (void)removeSelectLayer
{
    [selectLayer removeFromSuperlayer];
    selectLayer = nil;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITableView *tableView = (UITableView *)self.superview;
	while (tableView != nil && ![tableView isKindOfClass:[UITableView class]]) {
		tableView = (UITableView *)tableView.superview;
	}
	if (!tableView) {
		return;
	}
    if (tableView.decelerating) return;

	UITouch *touch = [touches anyObject];
	CGPoint point = [touch locationInView:self];
	CGRect rect = self.frame;
	rect.origin = CGPointZero;

	if (target_ && CGRectContainsPoint(rect, point)) {
		[CATransaction begin];
		[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
		[[self class] removeSelectLayer];
		selectLayer = [CALayer layer];
		selectLayer.frame = rect;
		selectLayer.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5].CGColor;
		[self.layer addSublayer:selectLayer];
		[CATransaction commit];
		
		touchBegan_ = YES;
	}

    [super touchesBegan:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	UITouch *touch = [touches anyObject];
	CGRect rect = self.frame;
	rect.origin = CGPointZero;
	CGPoint point = [touch locationInView:self];
	if (!CGRectContainsPoint(rect, point)) {
		[[self class] removeSelectLayer];
		touchBegan_ = NO;
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];

    [[self class] performSelector:@selector(removeSelectLayer) withObject:nil afterDelay:0.3];
	
	if (touchBegan_) {
		[target_ performSelector:action_ withObject:self];
	}
	touchBegan_ = NO;
}

- (void)animationDidStop:(CAAnimation *)animation finished:(BOOL)flag
{
    [[self class] removeSelectLayer];
	touchBegan_ = NO;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [[self class] removeSelectLayer];
	touchBegan_ = NO;
}

@end


static void *asyncImageLoaderThread(void *arg);


@interface AsyncImageLoader : NSObject {
	pthread_t			thread;
	pthread_mutex_t		mutex;
	pthread_cond_t		cond;
	BOOL				stopFlag;
	NSMutableArray		*queue;
	id					delegate;
}

@property(readwrite, assign, nonatomic) id delegate;

@end


@implementation AsyncImageLoader

@synthesize delegate;

- (id) init {
	self = [super init];
	if (self) {
		pthread_mutex_init(&mutex, NULL);
		pthread_cond_init(&cond, NULL);
		queue = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void) dealloc {
	pthread_cond_destroy(&cond);
	pthread_mutex_destroy(&mutex);
	[queue release];

	[super dealloc];
}

- (void) start {
	if (!thread) {
		stopFlag = NO;
		pthread_create(&thread, NULL, asyncImageLoaderThread, self);
	}
}

- (void) stop {
	if (thread) {
		void *ret = NULL;
		stopFlag = YES;
		pthread_mutex_lock(&mutex);
		pthread_cond_signal(&cond);
		pthread_mutex_unlock(&mutex);
		pthread_join(thread, &ret);
		thread = NULL;
	}
}

- (void) clear {
	pthread_mutex_lock(&mutex);
	[queue removeAllObjects];
	pthread_mutex_unlock(&mutex);
}

- (void) push:(NSDictionary *)info {
	pthread_mutex_lock(&mutex);
	[queue addObject:info];
	pthread_cond_signal(&cond);
	pthread_mutex_unlock(&mutex);
}

- (void) load:(NSDictionary *)info {
	NSData *data = [info objectForKey:@"Data"];
	CGSize size = CGSizeFromString([info objectForKey:@"Size"]);
	BOOL fill = [[info objectForKey:@"Fill"] boolValue];
	NSDictionary *pic = [info objectForKey:@"Info"];
	UIImage *img = [UIImage imageWithData:data];
	
	img = resizeImage(img, size, fill);
	
	ButtonImageView *iview = [[ButtonImageView alloc] init];
	iview.object = pic;
	iview.contentMode = UIViewContentModeScaleAspectFit;
	//[iview setTarget:self withAction:@selector(selectImage:)];
	[iview setImage:img];
	//[imageViews_ setObject:iview forKey:[pic objectForKey:@"IllustID"]];
	//[imageViewIDs_ insertObject:[pic objectForKey:@"IllustID"] atIndex:0];
	
	[delegate performSelector:@selector(asyncLoaderLoaded:) withObject:iview];
	[iview release];	
}

- (BOOL) loading:(id)key {
	BOOL ret = NO;
	pthread_mutex_lock(&mutex);
	for (NSDictionary *info in queue) {
		if ([[[info objectForKey:@"Info"] objectForKey:@"IllustID"] isEqualToString:key]) {
			ret = YES;
			break;
		}
	}
	pthread_mutex_unlock(&mutex);
	return ret;
}

- (void *) thread {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	while (1) {
		NSAutoreleasePool *pool2 = [[NSAutoreleasePool alloc] init];
		NSDictionary *info = nil;
		
		pthread_mutex_lock(&mutex);
		while (stopFlag == NO && [queue count] == 0) {
			pthread_cond_wait(&cond, &mutex);
		}
		if (stopFlag) {
			[pool2 release];
			pthread_mutex_unlock(&mutex);
			break;
		} else if ([queue count] > 0) {
			info = [[queue objectAtIndex:0] retain];
			[queue removeObjectAtIndex:0];
		}
		pthread_mutex_unlock(&mutex);
		
		[self performSelectorOnMainThread:@selector(load:) withObject:info waitUntilDone:NO];
		//[self load:info];
		[info release];
		[pool2 release];
	}
	
	[pool release];
	return NULL;
}

@end


static void *asyncImageLoaderThread(void *arg) {
	return [(AsyncImageLoader *)arg thread];
}


@interface PixivMatrixViewController(Private)
- (void) updateImageViewsThread;
- (CGFloat) imageWidth;
- (CGFloat) imageHeight;
@end


static void *updateImageViewThreadProc(void *arg) {
	[(PixivMatrixViewController *)arg updateImageViewsThread];
	return NULL;
}


@implementation PixivMatrixViewController

@synthesize method;
@synthesize account;
@synthesize scrapingInfoKey;

- (ImageCache *) cache {
	return [ImageCache pixivSmallCache];
}

//- (ImageCache *) matrixViewGetCache:(CHMatrixView *)view {
//	return [self cache];
//}

- (PixService *) pixiv {
	return [Pixiv sharedInstance];
}

- (UIImage *) squareTrimmedImage:(UIImage *)img {
	CGRect		fr;
	CGImageRef	cgimg;
			
	// trim
	if (img.size.width > img.size.height) {
		fr.size.width = img.size.height;
		fr.size.height = img.size.height;
		fr.origin.x = (img.size.width - img.size.height) / 2.0;
		fr.origin.y = 0;
	} else {
		fr.size.width = img.size.width;
		fr.size.height = img.size.width;
		fr.origin.x = 0;
		fr.origin.y = (img.size.height - img.size.width) / 2.0;
	}
	
	cgimg = CGImageCreateWithImageInRect(img.CGImage, fr);
	UIImage *ret = [UIImage imageWithCGImage:cgimg];
	CGImageRelease(cgimg);
	return ret;
}

- (UIImage *) imageForID:(NSString *)iid {
	UIImage *img;

	img = [[self cache] imageForKey:iid];
	return img;
}

- (void) storeImageView:(NSDictionary *)pic {
	UIImage *img = [self imageForID:[pic objectForKey:@"IllustID"]];
	img = resizeImage(img, CGSizeMake([self imageWidth], [self imageHeight]), aspectFill);
	
	ButtonImageView *iview = [[ButtonImageView alloc] init];
	iview.object = pic;
	iview.contentMode = UIViewContentModeScaleAspectFit;
	[iview setTarget:self withAction:@selector(selectImage:)];
	[iview setImage:img];
	[imageViews_ setObject:iview forKey:[pic objectForKey:@"IllustID"]];
	[iview release];	
}

- (ButtonImageView *) imageViewForID:(NSString *)key {
	return [imageViews_ objectForKey:key];
}

 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    //assert(0);
	if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
		foundPicMain = [[PerformMainObject alloc] init];
		foundPicMain.target = self;
		foundPicMain.selector = @selector(matrixParserFoundPictureMain:);
		finishedMain = [[PerformMainObject alloc] init];
		finishedMain.target = self;
		finishedMain.selector = @selector(matrixParserFinishedMain:);
		loadedMain = [[PerformMainObject alloc] init];
		loadedMain.target = self;
		loadedMain.selector = @selector(asyncLoaderLoadedMain:);
		
		imageViews_ = [[NSMutableDictionary alloc] init];
		progressViews_ = [[NSMutableDictionary alloc] init];
		
		loadingLoaders_ = [[NSMutableSet alloc] init];
		pendingLoaders_ = [[NSMutableArray alloc] init];

		loader_ = [[AsyncImageLoader alloc] init];
		loader_.delegate = self;
    }
    return self;
}

- (id)init {
    if (self = [super init]) {
        // Custom initialization
		foundPicMain = [[PerformMainObject alloc] init];
		foundPicMain.target = self;
		foundPicMain.selector = @selector(matrixParserFoundPictureMain:);
		finishedMain = [[PerformMainObject alloc] init];
		finishedMain.target = self;
		finishedMain.selector = @selector(matrixParserFinishedMain:);
		loadedMain = [[PerformMainObject alloc] init];
		loadedMain.target = self;
		loadedMain.selector = @selector(asyncLoaderLoadedMain:);
		
		imageViews_ = [[NSMutableDictionary alloc] init];
		progressViews_ = [[NSMutableDictionary alloc] init];
		
		loadingLoaders_ = [[NSMutableSet alloc] init];
		pendingLoaders_ = [[NSMutableArray alloc] init];

		loader_ = [[AsyncImageLoader alloc] init];
		loader_.delegate = self;
    }
    return self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	loader_.delegate = nil;
	[loader_ stop];
	
	[connection_ cancel];
	[connection_ release];
	connection_ = nil;
	
	[parser_ addDataEnd];
	[parser_ release];
	parser_ = nil;
	
	//[self.tableView release];
	//self.tableView = nil;
	
	[imageViews_ removeAllObjects];
	
	for (CHURLImageLoader *loader in loadingLoaders_) {
		[loader cancel];
		CHURLImageLoader *tmp = [loader copy];
		[pendingLoaders_ addObject:tmp];
		[tmp release];
	}
	[loadingLoaders_ removeAllObjects];
	
	[ButtonImageView removeSelectLayer];

	
	foundPicMain.target = nil;
	[foundPicMain release];
	foundPicMain = nil;
	finishedMain.target = nil;
	[finishedMain release];
	finishedMain = nil;
	loadedMain.target = nil;
	[loadedMain release];
	loadedMain = nil;
	
	[contents_ release];
	self.method = nil;
	for (CHURLImageLoader *loader in loadingLoaders_) {
		[loader cancel];
	}
	[loadingLoaders_ release];
	[pendingLoaders_ release];
	[imageViews_ release];
	[progressViews_ release];
	[loader_ release];
	[account release];
	
	self.scrapingInfoKey = nil;
	
    [super dealloc];
}

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/

- (UIScrollView *) matrixView {
	return self.tableView;
}

- (NSString *) referer {
	return @"http://www.pixiv.net/";
}

- (void) restoreContents {
		[contents_ release];
		contents_ = [storedContents mutableCopy];
		[storedContents release];
		storedContents = nil;
		
		/*
		for (NSDictionary *pic in contents_) {
			if ([[self cache] conteinsImageForKey:[pic objectForKey:@"IllustID"]] == NO) {
				CHURLImageLoader *loader = [[CHURLImageLoader alloc] init];
				loader.delegate = self;
				loader.object = pic;
				loader.referer = [self referer];
				loader.url = [NSURL URLWithString:[[pic objectForKey:@"ThumbnailURLString"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
		
				if ([loadingLoaders_ count] > MATRIXPARSER_IMAGELOADER_COUNT) {
					[pendingLoaders_ addObject:loader];
				} else {
					[loader load];
					[loadingLoaders_ addObject:loader];
				}
				[loader release];
				
				UIProgressView *prog = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
				prog.progress = 0.0;
				[progressViews_ setObject:prog forKey:[pic objectForKey:@"IllustID"]];
				[prog release];
			} else {
				NSData *data = [[self cache] imageDataForKey:[pic objectForKey:@"IllustID"]];
		
				[self push:data withInfo:pic];
			}
		}
		*/
		
		showsNextButton_ = YES;
		[self.tableView reloadData];
		self.tableView.contentOffset = displayedOffset_;
		displayedOffset_ = CGPointZero;
}

- (long) reload {
	long	err = [[self pixiv] allertReachability];
	if (err) {
		return err;
	}
	/*
	if (err == -1) {
		[self pixiv].username = account.username;
		[self pixiv].password = account.password;
	
		err = [[self pixiv] login:self];
		if (err) {
			UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"ログインに失敗しました。" message:@"" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil] autorelease];
			[alert show];
			return err;
		} else {
			[self showProgress:YES withTitle:@"ログイン中..." tag:1000];
		}
		return 0;
	} else if (err) {
		return err;
	}
	 */
	
	if (storedContents) {
		[self restoreContents];
		return 0;
	}
	
	PixivMatrixParser		*parser = [[PixivMatrixParser alloc] initWithEncoding:NSUTF8StringEncoding async:NO];
	if (scrapingInfoKey) {
		NSDictionary *d = [[PixitailConstants sharedInstance] valueForKeyPath:scrapingInfoKey];
		if (d) {
			parser.scrapingInfo = d;
		}
	}
	CHHtmlParserConnection	*con;
	
	//[[self matrixView] setShowsLoadNextButton:NO];
	showsNextButton_ = NO;
	[self.tableView reloadData];

	pictureIsFound_ = NO;
	parser.delegate = self;
	if (0 && [self.method hasPrefix:@"ranking"]) {
		con = [[CHHtmlParserConnectionNoScript alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.pixiv.net/%@num=%d", self.method, loadedPage_ + 1]]];
	} else {
		con = [[CHHtmlParserConnectionNoScript alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.pixiv.net/%@p=%d", self.method, loadedPage_ + 1]]];
	}
	
	con.referer = @"http://www.pixiv.net/mypage.php";
	con.delegate = self;
	parser_ = parser;
	connection_ = con;
	
	[con startWithParser:parser];
	return 0;
}

- (void) reflesh {
	[loader_ stop];
	[loader_ clear];

	NSRange range = [self.method rangeOfString:@"mode=rand&"];
	if (range.location != NSNotFound) {
		self.method = [self.method stringByReplacingCharactersInRange:range withString:@""];
	}
	
	[contents_ removeAllObjects];
	[imageViews_ removeAllObjects];
		
	loadedPage_ = 0;
	[self reload];

	[loader_ start];
}

- (CGFloat) topMargin {
	return 0;//[[UIApplication sharedApplication] statusBarFrame].size.height + self.navigationController.navigationBar.frame.size.height;
}

- (void) setupHeaderFooter {
	/*
	UIView *header = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 22 + self.navigationController.navigationBar.frame.size.height)];
	header.backgroundColor = [UIColor clearColor];
	self.tableView.tableHeaderView = header;
	[header release];	

	UIView *footer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.navigationController.toolbar.frame.size.height)];
	footer.backgroundColor = [UIColor clearColor];
	self.tableView.tableFooterView = footer;
	[footer release];
	*/
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	[super viewDidLoad];
	
	if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) {
		self.edgesForExtendedLayout = UIRectEdgeNone;
	}
	
	//self.wantsFullScreenLayout = YES;
	//[self matrixView].matrixDelegate = self;
	//[self matrixView].topMargin = [self topMargin];
	//[self matrixView].referer = [self referer];
	
	columnSize_ = [[NSUserDefaults standardUserDefaults] integerForKey:@"MatrixViewColumnCount"];
	if (columnSize_ < 2 || 4 < columnSize_) {
		columnSize_ = 4;
	}
	aspectFill = ![[NSUserDefaults standardUserDefaults] boolForKey:@"MatrixViewThumbnailFit"];
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DisableAd"] == NO && [NSStringFromClass([self class]) rangeOfString:@"Search"].location == NSNotFound) {
		UIViewController *adroot;
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
			adroot = (UIViewController *)((PixiViewerAppDelegate *)[UIApplication sharedApplication].delegate).alwaysSplitViewController;
		} else {
			adroot = self;
		}
		
		UIView *header = [[[AdmobHeaderView alloc] initWithViewController:adroot] autorelease];
		CGRect r = header.frame;
		r.size.width = self.view.frame.size.width;
		header.frame = r;
		self.tableView.tableHeaderView = header;//[[[AdmobHeaderBGView alloc] init] autorelease];
	}

	self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
	//self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg.png"]];
	self.tableView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"bg.png"]];
	self.tableView.indicatorStyle = UIScrollViewIndicatorStyleWhite;

    //[super viewDidLoad];
	
	if (contents_) {
		//[[self matrixView] setShowsLoadNextButton:showsNextButton_];
		//[[self matrixView] layout];	
	} else if (storedContents == NO) {
		contents_ = [[NSMutableArray alloc] init];
		showsNextButton_ = NO;
		
		[self reload];
	}	
	
	[self loadNextImage];
	
	[self.tableView setContentOffset:displayedOffset_ animated:NO];

	if (storedContents) {
		[self reload];
	}

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loginFinished:) name:@"LoginFinishedNotification" object:nil];
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[loader_ stop];

	[connection_ cancel];
	[connection_ release];
	connection_ = nil;
	
	[parser_ addDataEnd];
	[parser_ release];
	parser_ = nil;
	
	//[self.tableView release];
	//self.tableView = nil;

	[imageViews_ removeAllObjects];
	
	for (CHURLImageLoader *loader in loadingLoaders_) {
		[loader cancel];
		CHURLImageLoader *tmp = [loader copy];
		[pendingLoaders_ addObject:tmp];
		[tmp release];
	}
	[loadingLoaders_ removeAllObjects];
	
	[ButtonImageView removeSelectLayer];

	[super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
	//[[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationNone];
	[self setStatusBarHidden:NO animated:NO];

	//[self.navigationController setNavigationBarHidden:YES animated:NO];
	[self.navigationController setNavigationBarHidden:NO animated:NO];

	[self setupHeaderFooter];

	[loader_ start];
	[self.tableView reloadData];

	[self.navigationController setToolbarHidden:NO animated:YES];
}

- (BOOL) enableShuffle {
	return NO;
	//return ([self.method hasPrefix:@"tags.php?tag="] || [self.method rangeOfString:@"tags="].location != NSNotFound);
}

- (NSString *) tag {
	NSMutableData	*data = [NSMutableData data];
	NSScanner		*scanner = [NSScanner scannerWithString:self.method];
	NSString		*str = nil;
	NSRange			range;
	
	[scanner scanString:@"tags.php?tag=" intoString:nil];
	[scanner scanUpToString:@"&" intoString:&str];
		
	range.length = 3;
	for (range.location = 0; range.location + range.length <= [str length]; range.location += 3) {
		NSString	*substr = [str substringWithRange:range];
		if ([substr hasPrefix:@"%"]) {
			substr = [substr substringFromIndex:1];
			UInt8	val = strtol([substr cStringUsingEncoding:NSASCIIStringEncoding], NULL, 16);
			[data appendBytes:&val length:1];
		} else {
			return nil;
		}
	}
	
	str = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
	return str;
}

- (BOOL) enableAdd {
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		return ([self.method hasPrefix:@"tags.php?tag="] || [self.method rangeOfString:@"tags="].location != NSNotFound);
	} else {
		return ([self.method hasPrefix:@"tags.php?tag="] || [self.method rangeOfString:@"tags="].location != NSNotFound);
	}
}

- (void)viewDidAppear:(BOOL)animated {
	UIBarButtonItem	*right = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Home", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(goToTop)];
	self.navigationItem.rightBarButtonItem = right;
	[right release];

	self.navigationController.navigationBar.translucent = YES;
	self.navigationController.toolbar.translucent = YES;

	//self.navigationController.toolbar.barStyle = UIBarStyleBlackTranslucent;
	//[self.navigationController setToolbarHidden:YES animated:NO];
	//[self.navigationController setToolbarHidden:NO animated:NO];

	//[self.navigationController setNavigationBarHidden:YES animated:NO];
	//[self.navigationController setNavigationBarHidden:NO animated:NO];

	//[[UIApplication sharedApplication] setStatusBarHidden:YES animated:NO];
	//[[UIApplication sharedApplication] setStatusBarHidden:NO animated:NO];

	{
		NSMutableArray	*tmp = [NSMutableArray array];
		UIBarButtonItem	*item;
        
        item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(reflesh)];
		//item = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"gototop.png"] style:UIBarButtonItemStylePlain target:self action:@selector(goToTop)];
		[tmp addObject:item];
		[item release];

		item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
		[tmp addObject:item];
		[item release];
		
		/*
		item = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"matrix_zoom.png"] style:UIBarButtonItemStylePlain target:self action:@selector(toggleChangeSize:)];
		[tmp addObject:item];
		[item release];
		
		item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
		[tmp addObject:item];
		[item release];
		*/
		
		item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(slideshow:)];
		[tmp addObject:item];
		[item release];
		
		/*
		item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
		[tmp addObject:item];
		[item release];
		*/
		
		/*
		if ([self enableShuffle]) {
			item = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"shuffle.png"] style:UIBarButtonItemStylePlain target:self action:@selector(random)];
			[item setEnabled:YES];		
			[tmp addObject:item];
			[item release];
		} else {
			item = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"clear.png"] style:UIBarButtonItemStylePlain target:nil action:nil];
			[item setEnabled:NO];
			[tmp addObject:item];
			[item release];
		}
		 */
		
		//if ([self enableAdd]) {
			item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
			[tmp addObject:item];
			[item release];

			item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addTag:)];
			[item setEnabled:[self enableAdd]];		
			[tmp addObject:item];
			[item release];
			/*
		} else {
			item = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"clear.png"] style:UIBarButtonItemStylePlain target:nil action:nil];
			[item setEnabled:NO];
			[tmp addObject:item];
			[item release];
			 */
		//}
		
		[self setToolbarItems:tmp animated:NO];
	}
	
	if (progressShowing_) {
		for (UIBarButtonItem *item in self.toolbarItems) {
			item.enabled = NO;
		}
		//self.navigationItem.rightBarButtonItem.enabled = NO;
	}

	[self.tableView flashScrollIndicators];
}

- (void)viewWillDisappear:(BOOL)animated {
	if (actionSheet) [actionSheet dismissWithClickedButtonIndex:[actionSheet cancelButtonIndex] animated:NO];

	if ([contents_ count] > 0) {
		UIImage *image = [[self cache] imageForKey:[[contents_ objectAtIndex:0] objectForKey:@"IllustID"]];
		if (image) {
			if (image.size.width != image.size.height) {
				image = [self squareTrimmedImage:image];
			}
			[[NSNotificationCenter defaultCenter] postNotificationName:@"TopImageChangedNotification" object:self.account userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
				image,			@"Image",
				self.method,	@"Method",
				nil]];
		}
	}
}

- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
	[loader_ stop];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	[self setupHeaderFooter];
	[self.tableView reloadData];
}

- (void) loginFinished:(NSNotification *)notif {
	[self reload];
}

#pragma mark-

/*
- (void) garbageCollect {
	//[[self matrixView] garbgeCollect];
	needsUpdateTimer_ = nil;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
	DLog(@"scrollViewDidEndDragging");
	[needsUpdateTimer_ invalidate];
	needsUpdateTimer_ = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(garbageCollect) userInfo:nil repeats:NO];
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
	DLog(@"scrollViewDidEndDecelerating");
	[needsUpdateTimer_ invalidate];
	needsUpdateTimer_ = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(garbageCollect) userInfo:nil repeats:NO];
}
*/

- (void) push:(NSData *)data withInfo:(NSDictionary *)pic {
	[loader_ push:[NSDictionary dictionaryWithObjectsAndKeys:
		data,			@"Data",
		pic,			@"Info",
		NSStringFromCGSize(CGSizeMake([self imageWidth] * 2, [self imageHeight] * 2)),		@"Size",
		[NSNumber numberWithBool:aspectFill],		@"Fill",
		nil]];
}

- (void) loadNextImage {
	if ([loadingLoaders_ count] <= MATRIXPARSER_IMAGELOADER_COUNT && [pendingLoaders_ count] > 0) {
		CHURLImageLoader *loader = [pendingLoaders_ objectAtIndex:0];
		[loader load];
		[loadingLoaders_ addObject:loader];
		[pendingLoaders_ removeObjectAtIndex:0];
	}
}

#pragma mark-

//- (void) matrixParser:(MatrixParser *)parser foundPicture:(NSDictionary *)pic {
- (void) matrixParserFoundPictureMain:(NSDictionary *)pic {
	DLog(@"foundFavorite: %@", [pic description]);
	pictureIsFound_ = YES;

	for (NSDictionary *dic in contents_) {
		if ([[pic objectForKey:@"IllustID"] isEqualToString:[dic objectForKey:@"IllustID"]]) {
			// 既にある
			return;
		}
	}
	
	if ([[self cache] conteinsImageForKey:[pic objectForKey:@"IllustID"]] == NO) {
		CHURLImageLoader *loader = [[CHURLImageLoader alloc] init];
		loader.delegate = self;
		loader.object = pic;
		loader.referer = [self referer];
		loader.url = [NSURL URLWithString:[[pic objectForKey:@"ThumbnailURLString"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
		//assert([pic objectForKey:@"ThumbnailURLString"]);
		//DLog([pic description]);
		
		if ([loadingLoaders_ count] > MATRIXPARSER_IMAGELOADER_COUNT) {
			[pendingLoaders_ addObject:loader];
		} else {
			[loader load];
			[loadingLoaders_ addObject:loader];
		}
		[loader release];
		
		UIProgressView *prog = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
		prog.progress = 0.0;
		[progressViews_ setObject:prog forKey:[pic objectForKey:@"IllustID"]];
		[prog release];
	} else {
		NSData *data = [[self cache] imageDataForKey:[pic objectForKey:@"IllustID"]];
		
		[self push:data withInfo:pic];
	}
				
	[contents_ addObject:pic];
	
	//[needsUpdateTimer_ invalidate];
	//needsUpdateTimer_ = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(loadImagesTimer:) userInfo:nil repeats:NO];
	//[self.tableView reloadData];
}

- (void) matrixParser:(MatrixParser *)parser foundPicture:(NSDictionary *)pic {
	DLog(@"performselector foundPicture");
	[foundPicMain performSelectorOnMainThread:@selector(performMain:) withObject:pic waitUntilDone:NO];
	//[self performSelectorOnMainThread:@selector(matrixParserFoundPictureMain:) withObject:pic waitUntilDone:NO];
}

//- (void) matrixParser:(MatrixParser *)parser finished:(long)err {
- (void) matrixParserFinishedMain:(NSNumber *)num {
		if (pictureIsFound_) {
			loadedPage_++;
			maxPage_ = ((PixivMatrixParser *)parser_).maxPage;
			/*
			if (maxPage_ > 100) {
				// 制限
				maxPage_ = 100;
			}
			*/
			
			showsNextButton_ = NO;
			if ([self class] == [PixivMatrixViewController class] && [self.method hasPrefix:@"ranking"]) {
				if (loadedPage_ < 6) {
					showsNextButton_ = YES;
					//[[self matrixView] setShowsLoadNextButton:YES];
				}
			} else if (loadedPage_ < maxPage_) {
				showsNextButton_ = YES;
				//[[self matrixView] setShowsLoadNextButton:YES];
			}
		}

		//[parser_ addDataEnd];
		[parser_ release];
		parser_ = nil;
		
		[self.tableView reloadData];
}

- (void) matrixParser:(MatrixParser *)parser finished:(long)err {
	//[self matrixParserFinishedMain:[NSNumber numberWithLong:err]];
	DLog(@"performselector finish");
	[finishedMain performSelectorOnMainThread:@selector(performMain:) withObject:[NSNumber numberWithLong:err] waitUntilDone:NO];
	//[self performSelectorOnMainThread:@selector(matrixParserFinishedMain:) withObject:[NSNumber numberWithLong:err] waitUntilDone:NO];
}

- (void) connection:(CHHtmlParserConnection *)con finished:(long)err {
		if (err) {
			UIAlertView	*alert = [[UIAlertView alloc] initWithTitle:@"読み込みに失敗しました" message:[NSString stringWithFormat:@"エラー: %ld", err] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];				
			[alert show];
			[alert release];

			showsNextButton_ = YES;
		}

		[connection_ release];
		connection_ = nil;
}

#pragma mark-

- (void) selectImage:(ButtonImageView *)sender {
//- (void) matrixView:(CHMatrixView *)view action:(id)senderObject {
	id senderObject = sender.object;
	DLog(@"favoriteAction: %@", [senderObject description]);
	
	PixivMediumViewController *controller = [[PixivMediumViewController alloc] init];
	controller.illustID = [senderObject objectForKey:@"IllustID"];
	controller.account = self.account;
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		PixiViewerAppDelegate *app = (PixiViewerAppDelegate *)[UIApplication sharedApplication].delegate;
		UINavigationController *nc = [[[UINavigationController alloc] initWithRootViewController:controller] autorelease];
		app.alwaysSplitViewController.detailViewController = nc;
	} else {
		[self.navigationController pushViewController:controller animated:YES];
	}
	[controller release];
}

- (void) loadNext:(id)senderObject {
//- (void) matrixView:(CHMatrixView *)view loadNext:(id)senderObject {
	[self reload];
}

/*
- (void) matrixViewBeginLayout:(CHMatrixView *)view {
	for (UIBarButtonItem *item in self.navigationController.toolbar.items) {
		if (item.action) {
			item.enabled = NO;
		}
	}
	[self.navigationItem setHidesBackButton:YES animated:YES];
	self.navigationItem.rightBarButtonItem.enabled = NO;
}

- (void) matrixViewEndLayout:(CHMatrixView *)view {
	for (UIBarButtonItem *item in self.navigationController.toolbar.items) {
		if (item.action) {
			item.enabled = YES;
		}
	}
	[self.navigationItem setHidesBackButton:NO animated:YES];
	self.navigationItem.rightBarButtonItem.enabled = YES;
}

- (NSArray *) matrixViewContents:(CHMatrixView *)view {
	return contents_;
}

- (BOOL) matrixViewShowsNextButton:(CHMatrixView *)view {
	return showsNextButton_;
}
*/

#pragma mark-

- (IBAction) doSlideshow:(BOOL)random reverse:(BOOL)rev {
	PixivSlideshowViewController *controller = [[PixivSlideshowViewController alloc] initWithNibName:@"PixivSlideshowViewController" bundle:nil];
	controller.method = self.method;
	controller.scrapingInfoKey = self.scrapingInfoKey;
	[controller setPage:loadedPage_];
	[controller setMaxPage:maxPage_];
	[controller setContents:contents_ random:random reverse:rev];
	//[controller setContents:[NSArray arrayWithObject:[contents_ objectAtIndex:0]] random:random reverse:rev];
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		PixiViewerAppDelegate *app = (PixiViewerAppDelegate *)[UIApplication sharedApplication].delegate;
		[app pushViewController:controller animated:YES];
	} else {
		[self.navigationController pushViewController:controller animated:YES];
	}
	[controller release];
}

- (IBAction) slideshow:(id)sender {
	if (actionSheet) [actionSheet dismissWithClickedButtonIndex:[actionSheet cancelButtonIndex] animated:NO];

	UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Start slideshow?", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Start.", nil), NSLocalizedString(@"Start reverse.", nil), NSLocalizedString(@"Start at random.", nil), nil];
	sheet.tag = 300;
	if (([[UIDevice currentDevice] respondsToSelector:@selector(userInterfaceIdiom)] ? [[UIDevice currentDevice] userInterfaceIdiom] : 0) != 0) {
		[sheet showFromBarButtonItem:sender animated:YES];
	} else {
		[sheet showFromToolbar:self.navigationController.toolbar];
	}
	actionSheet = sheet;
	[sheet release];
}

- (void) removeContent:(id)obj {
	[contents_ removeObject:obj];
}

- (NSInteger) indexOfIllustID:(NSString *)iid {
	NSDictionary	*tmp = nil;
	for (NSDictionary *info in contents_) {
		if ([iid isEqualToString:[info objectForKey:@"IllustID"]]) {
			tmp = info;
			break;
		}
	}
	if (tmp) {
		return [contents_ indexOfObject:tmp];
	} else {
		return -1;
	}
}

- (NSString *) nextIID:(NSString *)iid {
	NSInteger				idx = [self indexOfIllustID:iid];
	if (idx + 1 < [contents_ count]) {
		NSDictionary	*info = [contents_ objectAtIndex:idx + 1];
		return [info objectForKey:@"IllustID"];
	} else {
		return nil;
	}
}

- (NSString *) prevIID:(NSString *)iid {
	NSInteger				idx = [self indexOfIllustID:iid];
	if (idx > 0) {
		NSDictionary	*info = [contents_ objectAtIndex:idx - 1];
		return [info objectForKey:@"IllustID"];
	} else {
		return nil;
	}
}

- (NSDictionary *) nextInfo:(NSString *)iid {
	NSInteger				idx = [self indexOfIllustID:iid];
	if (idx + 1 < [contents_ count]) {
		NSDictionary	*info = [contents_ objectAtIndex:idx + 1];
		return info;
	} else {
		return nil;
	}
}

- (NSDictionary *) prevInfo:(NSString *)iid {
	NSInteger				idx = [self indexOfIllustID:iid];
	if (idx > 0) {
		NSDictionary	*info = [contents_ objectAtIndex:idx - 1];
		return info;
	} else {
		return nil;
	}
}

- (NSDictionary *) infoForIllustID:(NSString *)iid {
	NSInteger	idx = [self indexOfIllustID:iid];
	if (idx < [contents_ count]) {
		return [contents_ objectAtIndex:idx];
	} else {
		return nil;
	}
}

- (void) goToTop {
	if ([self.navigationController.viewControllers count] > 2) {
		[self.navigationController popToViewController:[self.navigationController.viewControllers objectAtIndex:1] animated:YES];
	} else {
		[self.navigationController popToRootViewControllerAnimated:YES];
	}
}

- (void) changeSize:(int)col {
	[loader_ stop];
	[loader_ clear];

	columnSize_ = col;

	for (ButtonImageView *v in [imageViews_ allValues]) {
		//[self push:[[self cache] imageDataForKey:[v.object objectForKey:@"IllustID"]] withInfo:v.object];
		[v removeFromSuperview];
	}

	[imageViews_ removeAllObjects];

	[[NSUserDefaults standardUserDefaults] setInteger:col forKey:@"MatrixViewColumnCount"];
	[[NSUserDefaults standardUserDefaults] synchronize];

	[self.tableView reloadData];
	[loader_ start];
}

- (void) toggleChangeSize:(id)sender {
	if (actionSheet) [actionSheet dismissWithClickedButtonIndex:[actionSheet cancelButtonIndex] animated:NO];

	UIActionSheet *sheet;
	
	if (columnSize_ == 4) {
		sheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Change matrix image size.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"3 cols.", nil), NSLocalizedString(@"2 cols.", nil), nil];
	} else if (columnSize_ == 3) {
		sheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Change matrix image size.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"4 cols.", nil), NSLocalizedString(@"2 cols.", nil), nil];
	} else {
		sheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Change matrix image size.", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"4 cols.", nil), NSLocalizedString(@"3 cols.", nil), nil];
	}
	sheet.tag = 200;
	if (([[UIDevice currentDevice] respondsToSelector:@selector(userInterfaceIdiom)] ? [[UIDevice currentDevice] userInterfaceIdiom] : 0) != 0) {
		[sheet showFromBarButtonItem:sender animated:YES];
	} else {
		[sheet showFromToolbar:self.navigationController.toolbar];
	}
	actionSheet = sheet;
	[sheet release];
}

- (NSString *) savedTagsName {
	return @"SavedTags";
}

- (NSString *) tags {
	NSMutableData	*data = [NSMutableData data];
	NSScanner		*scanner = [NSScanner scannerWithString:self.method];
	NSString		*str = nil;
	NSRange			range;
	
	[scanner scanString:@"tags.php?tag=" intoString:nil];
	[scanner scanUpToString:@"&" intoString:&str];
	
	range.length = 3;
	for (range.location = 0; range.location + range.length <= [str length]; range.location += 3) {
		NSString	*substr = [str substringWithRange:range];
		if ([substr hasPrefix:@"%"]) {
			substr = [substr substringFromIndex:1];
			UInt8	val = strtol([substr cStringUsingEncoding:NSASCIIStringEncoding], NULL, 16);
			[data appendBytes:&val length:1];
		} else {
			assert(0);
			return nil;
		}
	}
	
	str = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
	return str;
}

- (void) doAddTag {
	NSMutableArray	*ary = [[NSUserDefaults standardUserDefaults] objectForKey:[self savedTagsName]] ? [[[[NSUserDefaults standardUserDefaults] objectForKey:[self savedTagsName]] mutableCopy] autorelease] : [NSMutableArray array];
	NSString		*str = [self tags];

	if ([ary containsObject:str]) {
		[ary removeObject:str];
	}
	[ary insertObject:str atIndex:0];
	[[NSUserDefaults standardUserDefaults] setObject:ary forKey:[self savedTagsName]];
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Add to tag bookmark ok.", @"") message:@"" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];				
	[alert show];
	[alert release];
}

- (void) addTag:(id)sender {
	if (actionSheet) [actionSheet dismissWithClickedButtonIndex:[actionSheet cancelButtonIndex] animated:NO];

	UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:NSLocalizedString(@"Add to tag bookmark?", nil) delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Add ok.", nil), nil];
	sheet.tag = 100;
	if (([[UIDevice currentDevice] respondsToSelector:@selector(userInterfaceIdiom)] ? [[UIDevice currentDevice] userInterfaceIdiom] : 0) != 0) {
		[sheet showFromBarButtonItem:sender animated:YES];
	} else {
		[sheet showFromToolbar:self.navigationController.toolbar];
	}
	actionSheet = sheet;
	[sheet release];
}

- (void) random {
	if ([self.method rangeOfString:@"mode=rand"].location == NSNotFound) {
		self.method = [self.method stringByAppendingString:@"mode=rand&"];
	}

	[contents_ removeAllObjects];
	
	loadedPage_ = 0;
	[self reload];
}

- (void)actionSheet:(UIActionSheet *)sheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	actionSheet = nil;
	
	switch (sheet.tag) {
	case 100:
		if (buttonIndex == 0) {
			[self doAddTag];
		}
		break;
	case 200:
		switch (buttonIndex) {
		case 0:
			if (columnSize_ == 4) {
				[self changeSize:3];
			} else {	
				[self changeSize:4];
			}
			break;
		case 1:
			if (columnSize_ == 2) {
				[self changeSize:3];
			} else {	
				[self changeSize:2];
			}
			break;
		default:
			break;
		}
		break;
	case 300:
		if (buttonIndex == 0) {
			[self doSlideshow:NO reverse:NO];
		} else if (buttonIndex == 1) {
			[self doSlideshow:NO reverse:YES];
		} else if (buttonIndex == 2) {
			[self doSlideshow:YES reverse:NO];
		}
		break;
	default:
		break;
	}
}

#pragma mark-

- (void) loader:(CHURLImageLoader *)loader progress:(NSInteger)percent {
    if ([loader.object objectForKey:@"IllustID"]) {
        UIProgressView *prog = [progressViews_ objectForKey:[loader.object objectForKey:@"IllustID"]];
        prog.progress = percent / 100.0;
    }
}

- (void) loader:(CHURLImageLoader *)loader finished:(NSData *)data {
    if ([loader.object objectForKey:@"IllustID"]) {
        DLog(@"CHURLImageLoader loaded: %@ (%@)", [loader.object objectForKey:@"IllustID"], @([data length]));
        
        if (data) {
            [[self cache] setImageData:data forKey:[loader.object objectForKey:@"IllustID"]];
            
            UIProgressView *prog = [progressViews_ objectForKey:[loader.object objectForKey:@"IllustID"]];
            if (prog) {
                UIView *cellView = [prog superview];
                CGRect frame = prog.frame;
                
                [prog removeFromSuperview];
                [progressViews_ removeObjectForKey:[loader.object objectForKey:@"IllustID"]];
                
                UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
                frame.origin.x += (frame.size.width - indicator.frame.size.width) / 2.0;
                frame.origin.y -= (indicator.frame.size.height - frame.size.height) / 2.0;
                frame.size = indicator.frame.size;
                indicator.frame = frame;
                [cellView addSubview:indicator];
                [indicator startAnimating];
                [indicator release];
            }
            
            [self push:data withInfo:loader.object];
        } else if (loader.retryCount < 4) {
            CHURLImageLoader *newloader = [loader copy];
            newloader.retryCount = newloader.retryCount + 1;
            
            [pendingLoaders_ addObject:newloader];
            //[newloader load];
            [newloader release];
        } else {
            [progressViews_ removeObjectForKey:[loader.object objectForKey:@"IllustID"]];
            
            UIImage *img = [UIImage imageNamed:@"load_failed.png"];
            ButtonImageView *iview = [[ButtonImageView alloc] init];
            iview.object = nil;
            iview.contentMode = UIViewContentModeCenter;
            [iview setImage:img];
            [imageViews_ setObject:iview forKey:[loader.object objectForKey:@"IllustID"]];
            [iview release];
        }
    }
    
    [loadingLoaders_ removeObject:loader];
	[self loadNextImage];
}

#pragma mark-

- (NSInteger) count {
	return [contents_ count];
}

- (id) objectAtIndex:(NSInteger)idx {
	if (idx < [contents_ count]) {
		return [contents_ objectAtIndex:idx];
	} else {
		return nil;
	}
}

- (CGFloat) imageWidth {
	return (int)[self width] / columnSize_ - 2 * [self columnSpacing];
}

- (CGFloat) imageHeight {
	return [self imageWidth];
}

- (float) columnSpacing {
	switch (columnSize_) {
	case 4:
		return 5;
	case 3:
		return 5;
	case 2:
		return 6;
	default:
		assert(0);
		return 5;
	}
}

- (float) width {
	if (([[UIDevice currentDevice] respondsToSelector:@selector(userInterfaceIdiom)] ? [[UIDevice currentDevice] userInterfaceIdiom] : 0) != 0) {
		return 320;
		
		if ([UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationPortrait || [UIApplication sharedApplication].statusBarOrientation == UIInterfaceOrientationPortraitUpsideDown) {
			return 768;
		} else {
			return 1024;
		}
	} else {
		return [UIScreen mainScreen].bounds.size.width;
	}
}

- (int) columnCount {
	return [self width] / ([self imageWidth] + [self columnSpacing]);
}

- (float) columnSpacingEdge {
	return ([self width] - (([self imageWidth] + [self columnSpacing]) * [self columnCount])) / 2.0;
}

- (int) rowCount {
	if (columnSize_ > 0) {
		return ((int)[contents_ count] - 1) / [self columnCount] + 1;
	} else {
		return 0;
	}
}

- (float) rowSpacing {
	return [self columnSpacing];//(self.frame.size.height - [self imageHeight] * [self rowCount]) / ([self rowCount] + 1);
}

- (float) height {
	return [self imageHeight] * [self rowCount] + [self rowSpacing] * ([self rowCount] + 1) + 44 + self.topMargin;
}

- (CGFloat)tableView:(UITableView *)aTableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.row < [self rowCount]) {
		return [self imageHeight] + [self rowSpacing];
	} else {
		return 39;
	}
}

- (NSInteger)tableView:(UITableView *)aTableView numberOfRowsInSection:(NSInteger)section {
	return [self rowCount] + 1;
}

- (void) loadImage:(NSDictionary *)info {
	CHURLImageLoader *loader = [[CHURLImageLoader alloc] init];
	loader.delegate = self;
	loader.object = info;
	loader.referer = [self referer];
	loader.url = [NSURL URLWithString:[[info objectForKey:@"ThumbnailURLString"] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
			
	if ([loadingLoaders_ count] > MATRIXPARSER_IMAGELOADER_COUNT) {
		[pendingLoaders_ addObject:loader];
	} else {
		[loader load];
		[loadingLoaders_ addObject:loader];
	}
	[loader release];
				
	UIProgressView *prog = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
	prog.progress = 0.0;
	[progressViews_ setObject:prog forKey:[info objectForKey:@"IllustID"]];
	[prog release];
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.row < [self rowCount]) {
		static NSString *CellIdentifier = @"ListCell";
		UITableViewCell *cell = (UITableViewCell *)[aTableView dequeueReusableCellWithIdentifier:CellIdentifier];
		if (cell == nil) {
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
			cell.backgroundColor = [UIColor clearColor];
		}
		
		UIView *cellView = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, [self width], [self imageHeight] + [self rowSpacing])] autorelease];
		NSInteger idx = indexPath.row;
		
		cellView.backgroundColor = [UIColor clearColor];
		for (NSInteger i = 0; i < [self columnCount]; i++) {
			NSInteger index = idx * [self columnCount] + i;
			if (index < [contents_ count]) {
				NSDictionary *info = [contents_ objectAtIndex:index];
				ButtonImageView *iview = [self imageViewForID:[info objectForKey:@"IllustID"]];
				BOOL hasCache = NO;
				
				hasCache = [[self cache] conteinsImageForKey:[info objectForKey:@"IllustID"]];
				
				CGRect frame;
				frame.origin.y = (int)([self rowSpacing] / 2.0);
				frame.origin.x = [self columnSpacingEdge] + i * ([self imageWidth] + [self columnSpacing]);
				frame.size.width = [self imageWidth];
				frame.size.height = [self imageHeight];
				
				if (iview) {
					iview.frame = CGRectIntegral(frame);
					[cellView addSubview:iview];
				} else if ([info objectForKey:@"IllustID"]) {
					UIProgressView *prog = [progressViews_ objectForKey:[info objectForKey:@"IllustID"]];
					if (prog) {
						 frame.size.height = [prog frame].size.height;
						 frame.size.width *= 3.0 / 4.0;
						 frame.origin.y += ([self imageHeight] - [prog frame].size.height) / 2.0;
						 frame.origin.x += ([self imageWidth] - frame.size.width) / 2.0;
						 
						 prog.frame = CGRectIntegral(frame);
						[cellView addSubview:prog];						 
					} else if (hasCache) {
						if (![loader_ loading:[info objectForKey:@"IllustID"]]) {
							// load
							[self push:[[self cache] imageDataForKey:[info objectForKey:@"IllustID"]] withInfo:info];
						}
						
						// 読んでる
						UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
						
						frame.size = indicator.frame.size;
						frame.origin.x += ([self imageWidth] - frame.size.width) / 2.0;
						frame.origin.y += ([self imageHeight] - frame.size.height) / 2.0;
						indicator.frame = CGRectIntegral(frame);
						[cellView addSubview:indicator];
						[indicator startAnimating];
						[indicator release];
					} else {
						[self loadImage:info];
						// 失敗
						/*
						UIImage *failed = [UIImage imageNamed:@"load_failed.png"];
						UIImageView *imgView = [[UIImageView alloc] init];
						imgView.image = failed;
						imgView.frame = CGRectIntegral(frame);
						imgView.contentMode = UIViewContentModeCenter;
						[cellView addSubview:imgView];
						[imgView release];
						*/
					}
				}
			}
		}
		
		for (UIView *v in [cell.contentView subviews]) {
			[v removeFromSuperview];
		}
		
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		[cell.contentView addSubview:cellView];
		//assert([cell.subviews count] == 1);
		
		return cell;
	} else {
		static NSString *CellIdentifier = @"ListCellNext";
		UITableViewCell *cell = (UITableViewCell *)[aTableView dequeueReusableCellWithIdentifier:CellIdentifier];
		if (cell == nil) {
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
			cell.backgroundColor = [UIColor clearColor];
		}
		
		UIView *cellView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, [self width], [self imageHeight] + [self rowSpacing])];		
		cellView.backgroundColor = [UIColor clearColor];
		
		for (UIView *v in [cell.contentView subviews]) {
			[v removeFromSuperview];
		}
		
		if (showsNextButton_) {
			UIButton *btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
			btn.frame = CGRectMake(10, 2, [self width] - 20, 35);
			[btn setTitle:NSLocalizedString(@"Load next illist...", nil) forState:UIControlStateNormal];
			[btn addTarget:self action:@selector(loadNext:) forControlEvents:UIControlEventTouchUpInside];
			[cellView addSubview:btn];
		}
		
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
		[cell.contentView addSubview:cellView];
		[cellView release];

		return cell;
	}
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
   //        NSLog(@"scroll: %3.2f:%3.2f %3.2f:%3.2f", scrollView.contentOffset.x, scrollView.contentOffset.y, 
   //              scrollView.frame.size.width, scrollView.frame.size.height);
   const int offsetForAutopagerize = -10; /* 微調整用 */
   if ((CGSizeEqualToSize(scrollView.contentSize, CGSizeZero) == NO) && (scrollView.contentOffset.y + scrollView.frame.size.height > scrollView.contentSize.height + offsetForAutopagerize)) {
//        NSLog(@"左辺 %f : 右辺 %f",scrollView.contentOffset.y + scrollView.frame.size.height, scrollView.contentSize.height + offset);
       if (showsNextButton_) {
           DLog(@"Autopagerize!!!!!!!!!!!!!");
           [self reload];
       }
   }
}


#pragma mark-

- (void)removeSelectLayers {
	[ButtonImageView removeSelectLayer];
/*
    if ([contents_ count] == 0) return;

NS_DURING    
    NSArray *visiblePaths = [tableView indexPathsForVisibleRows];
    for (NSIndexPath *indexPath in visiblePaths) {
		UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
		
		if ([cell.contentView.subviews count] > 0) {
			for (UIView *v in [[cell.contentView.subviews objectAtIndex:0] subviews]) {
				if ([v respondsToSelector:@selector(removeSelectLayer)]) {
					[v performSelector:@selector(removeSelectLayer)];
				}
			}
		}
    }
NS_HANDLER
NS_ENDHANDLER	
	//[tableView reloadData];
*/
}

- (NSInteger) loadImagesForOnscreenRows {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSInteger i = 0;
	
	BOOL loaded = NO;
    NSArray *visiblePaths = [self.tableView indexPathsForVisibleRows];
    for (NSIndexPath *indexPath in visiblePaths) {
		NSInteger idx = indexPath.row * [self columnCount];
		
		for (i = idx; i < idx + [self columnCount]; i++) {
			if (i < [contents_ count]) {
				NSDictionary *info = [contents_ objectAtIndex:i];
				if ([self imageViewForID:[info objectForKey:@"IllustID"]] == nil && [[self cache] conteinsImageForKey:[info objectForKey:@"IllustID"]]) {
					[self storeImageView:info];
					loaded = YES;
					break;
				}
			}
		}
    }
	
	//[self removeOldImageView];
	
	[pool release];
	return loaded ? -1 : i;
}

/*
- (void) loadImagesTimer:(NSTimer *)timer {
	needsUpdateTimer_ = nil;
	
	[self performSelectorInBackground:@selector(loadImagesForOnscreenRows) withObject:nil];
	return;
	
	if (tableView.dragging == NO && tableView.decelerating == NO) {
		[self loadImagesForOnscreenRows];
	}
}
*/

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
	[self removeSelectLayers];
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (!decelerate) {
        //[self loadImagesForOnscreenRows];
		displayedOffset_ = scrollView.contentOffset;
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    //[self loadImagesForOnscreenRows];
	displayedOffset_ = scrollView.contentOffset;
}

- (void) reloadData {
	[self.tableView reloadData];
}

- (void) updateImageViews {
	NSInteger idx = [self loadImagesForOnscreenRows];
	if (idx < 0) {
		return;
	}

	for (NSInteger i = 0; i < [contents_ count]; i++, idx++) {
		if (idx >= [contents_ count]) {
			idx = 0;
		}
		NSDictionary *info = [contents_ objectAtIndex:idx];
		if ([self imageViewForID:[info objectForKey:@"IllustID"]] == nil && [[self cache] conteinsImageForKey:[info objectForKey:@"IllustID"]]) {
			[self storeImageView:info];
			return;
		}
	}
}

#define CACHE_COUNT 200

- (void) garbageCollect {
	// メモリ不足対策
	if (self.tableView != nil && [imageViews_ count] <= CACHE_COUNT) {
		return;
	}
	
	CGRect r;
	r.origin = self.tableView.contentOffset;
	r.size = self.tableView.contentSize;
    NSArray *visiblePaths = [self.tableView indexPathsForRowsInRect:r];
	if ([visiblePaths count] > 0) {
		NSIndexPath *startIndex = [visiblePaths objectAtIndex:0];
		NSIndexPath *endIndex = [visiblePaths lastObject];
		NSInteger startIdx = startIndex.row * [self columnCount];
		NSInteger endIdx = endIndex.row * [self columnCount];
		
		int i = 0;
		for (NSDictionary *info in contents_) {
			if (startIdx <= i && i <= endIdx) {
				i++;
				continue;
			}
		
			id key = [info objectForKey:@"IllustID"];
			[imageViews_ removeObjectForKey:key];
			[progressViews_ removeObjectForKey:key];
			if ([imageViews_ count] <= CACHE_COUNT) {
				break;
			}
			i++;
		}
	}
}

- (void) asyncLoaderLoadedMain:(ButtonImageView *)iview {
	[iview setTarget:self withAction:@selector(selectImage:)];
	if ([iview.object objectForKey:@"IllustID"] != nil && [imageViews_ objectForKey:[iview.object objectForKey:@"IllustID"]] == nil) {
		[imageViews_ setObject:iview forKey:[iview.object objectForKey:@"IllustID"]];
		
		//[NSObject cancelPreviousPerformRequestsWithTarget:self.tableView selector:@selector(reloadData) object:nil];
		//[self.tableView performSelector:@selector(reloadData) withObject:nil afterDelay:0.5];
		[self.tableView reloadData];
	}
	
	//[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(garbageCollect) object:nil];
	//[self performSelector:@selector(garbageCollect) withObject:nil afterDelay:0.5];
	[self garbageCollect];
	//[self.tableView reloadData];
}

- (void) asyncLoaderLoaded:(ButtonImageView *)iview {
	DLog(@"performselector loaded");
	[loadedMain performSelectorOnMainThread:@selector(performMain:) withObject:iview waitUntilDone:NO];
	//[self performSelectorOnMainThread:@selector(asyncLoaderLoadedMain:) withObject:iview waitUntilDone:NO];
}

#pragma mark-

- (void) hideProgress {
	[super hideProgress];
	
	for (UIBarButtonItem *item in self.toolbarItems) {
		item.enabled = YES;
	}
}

- (void) showProgress:(BOOL)activity withTitle:(NSString *)str tag:(int)tag {
	[super showProgress:activity withTitle:str tag:tag];
	
	for (UIBarButtonItem *item in self.toolbarItems) {
		item.enabled = NO;
	}
}

#pragma mark-

- (void) pixService:(PixService *)sender loginFinished:(long)err {
	[self hideProgress];
	if (err) {
		// もいっかい
		err = [[self pixiv] login:self];
		if (err) {
			UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:@"ログインに失敗しました。" message:@"" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"OK", nil] autorelease];
			[alert show];
			[self.navigationController popToRootViewControllerAnimated:YES];
			return;
		}
	} else {
		[self reload];
	}
}

- (void) progressCancel:(ProgressViewController *)sender {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:nil];

	[[self pixiv] loginCancel];
	[self.navigationController popToRootViewControllerAnimated:YES];
	
	[self hideProgress];
}

#pragma mark-

- (NSMutableDictionary *) storeInfo {
	NSMutableDictionary *info = [super storeInfo];
	
	assert(account);
	[info setObject:[account info] forKey:@"Account"];
	if (method) [info setObject:method forKey:@"Method"];
	
	if (storedContents) {
		[info setObject:storedContents forKey:@"Contents"];
	} else if (contents_) {
		[info setObject:contents_ forKey:@"Contents"];
	}
	[info setObject:[NSNumber numberWithInt:loadedPage_] forKey:@"LoadedPage"];
	[info setObject:[NSNumber numberWithInt:maxPage_] forKey:@"MaxPage"];
	if (CGPointEqualToPoint(displayedOffset_, CGPointZero) == NO) {
		[info setObject:NSStringFromCGPoint(displayedOffset_) forKey:@"ScrollOffset"];
	} else {
		[info setObject:NSStringFromCGPoint(self.tableView.contentOffset) forKey:@"ScrollOffset"];
	}
	
	return info;
}

- (BOOL) needsStore {
	return YES;
}

- (BOOL) restore:(NSDictionary *)info {
	id obj;
	
	if ([super restore:info] == NO) {
		return NO;
	}
	
	obj = [info objectForKey:@"Method"];
	if (obj == nil) {
		return NO;
	}
	self.method = obj;

	obj = [info objectForKey:@"Account"];
	PixAccount *acc = [[AccountManager sharedInstance] accountWithInfo:obj];
	if (acc == nil) {
		return NO;
	}	
	self.account = acc;

	storedContents = [[info objectForKey:@"Contents"] retain];
	loadedPage_ = [[info objectForKey:@"LoadedPage"] intValue];
	maxPage_ = [[info objectForKey:@"MaxPage"] intValue];
	obj = [info objectForKey:@"ScrollOffset"];
	if (obj) {
		displayedOffset_ = CGPointFromString(obj);
	}
	
	//self.view;
	return YES;
}

@end
