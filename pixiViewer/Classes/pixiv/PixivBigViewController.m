//
//  PixivBigViewController.m
//  pixiViewer
//
//  Created by nya on 09/08/19.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PixivBigViewController.h"
//#import "URLCache.h"
#import "Pixiv.h"
#import "JpegImageUtility.h"
#import "CHHttpTimeoutableConnection.h"
#import "PixivMangaViewController.h"
#import "PixivBigParser.h"
#import <pthread.h>
#import "ImageDiskCache.h"

#import "UserDefaults.h"
#import "DropBoxTail.h"
#import "EvernoteTail.h"
#import "PixivMatrixViewController.h"
#import "PixivMediumViewController.h"
#import "PixiViewerAppDelegate.h"
#import "AlwaysSplitViewController.h"
#import "ImageLoaderManager.h"
#import "TiledImageView.h"
#import "CGImageObject.h"
#import "SharedAlertView.h"
#import "CHHtmlParserConnectionNoScript.h"
#import "PixitailConstants.h"
#import "NSData+GIF.h"
#import "UIImage+animatedGIF.h"
#import "PixivUgoIllust.h"


#define ZOOM_IMG_VIEW_TAG 300
#define ZOOM_VIEW_TAG 200
#define ZOOM_STEP 2
#define ZOOM_MAX ZOOM_STEP


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

static UIImage *scaleAndRotatedImage(UIImage *image, int kMaxResolution) {
	CGImageRef imgRef = image.CGImage;
	CGFloat width = CGImageGetWidth(imgRef);
	CGFloat height = CGImageGetHeight(imgRef);
	
	CGAffineTransform transform = CGAffineTransformIdentity;
	CGRect bounds = CGRectMake(0, 0, width, height);
	if (width > kMaxResolution || height > kMaxResolution) {
		CGFloat ratio = width/height;
		if (ratio > 1) {
			bounds.size.width = kMaxResolution;
			bounds.size.height = bounds.size.width / ratio;
		} else {
			bounds.size.height = kMaxResolution;
			bounds.size.width = bounds.size.height * ratio;
		}
	}
	
	CGFloat scaleRatio = bounds.size.width / width;
	CGSize imageSize = CGSizeMake(CGImageGetWidth(imgRef), CGImageGetHeight(imgRef));
	CGFloat boundHeight;
	
	UIImageOrientation orient = image.imageOrientation;
	switch(orient) {
		case UIImageOrientationUp:
			transform = CGAffineTransformIdentity;
			break;
		case UIImageOrientationUpMirrored:
			transform = CGAffineTransformMakeTranslation(imageSize.width, 0.0);
			transform = CGAffineTransformScale(transform, -1.0, 1.0);
			break;
		case UIImageOrientationDown:
			transform = CGAffineTransformMakeTranslation(imageSize.width, imageSize.height);
			transform = CGAffineTransformRotate(transform, M_PI);
			break;
		case UIImageOrientationDownMirrored:
			transform = CGAffineTransformMakeTranslation(0.0, imageSize.height);
			transform = CGAffineTransformScale(transform, 1.0, -1.0);
			break;
		case UIImageOrientationLeftMirrored:
			boundHeight = bounds.size.height;
			bounds.size.height = bounds.size.width;
			bounds.size.width = boundHeight;
			transform = CGAffineTransformMakeTranslation(imageSize.height, imageSize.width);
			transform = CGAffineTransformScale(transform, -1.0, 1.0);
			transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
			break;
		case UIImageOrientationLeft:
			boundHeight = bounds.size.height;
			bounds.size.height = bounds.size.width;
			bounds.size.width = boundHeight;
			transform = CGAffineTransformMakeTranslation(0.0, imageSize.width);
			transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
			break;
		case UIImageOrientationRightMirrored:
			boundHeight = bounds.size.height;
			bounds.size.height = bounds.size.width;
			bounds.size.width = boundHeight;
			transform = CGAffineTransformMakeScale(-1.0, 1.0);
			transform = CGAffineTransformRotate(transform, M_PI / 2.0);
			break;
		case UIImageOrientationRight:
			boundHeight = bounds.size.height;
			bounds.size.height = bounds.size.width;
			bounds.size.width = boundHeight;
			transform = CGAffineTransformMakeTranslation(imageSize.height, 0.0);
			transform = CGAffineTransformRotate(transform, M_PI / 2.0);
			break;
		default:
			[NSException raise:NSInternalInconsistencyException format:@"Invalid image orientation"];
	}
	
	UIGraphicsBeginImageContext(bounds.size);
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSaveGState(context);
	if (orient == UIImageOrientationRight || orient == UIImageOrientationLeft) {
		CGContextScaleCTM(context, -scaleRatio, scaleRatio);
		CGContextTranslateCTM(context, -height, 0);
	} else {
		CGContextScaleCTM(context, scaleRatio, -scaleRatio);
		CGContextTranslateCTM(context, 0, -height);
	}
	CGContextConcatCTM(context, transform);
	CGContextDrawImage(context, CGRectMake(0, 0, width, height), imgRef);
	UIImage *imageCopy = UIGraphicsGetImageFromCurrentImageContext();
	CGContextRestoreGState(context);
	UIGraphicsEndImageContext();
	
	return imageCopy;
}


@implementation PixivBigViewController
@synthesize progressVIew;

@synthesize illustID, scrollView_;
@synthesize urlString = urlString_;

- (PixService *) pixiv {
	return [Pixiv sharedInstance];
}

- (NSDictionary *) infoForIllustID:(NSString *)iid {
	return [[self pixiv] infoForIllustID:iid];
}

- (BigParser *) bigParser {
	return (BigParser *)parser_;
}

- (UIScrollView *) scrollView {
	return (UIScrollView *)scrollView_;
}

- (PixivMediumViewController *) parentMedium {
	if (parent) {
		return parent;
	}
	
	PixivMediumViewController *prev = nil;
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		PixiViewerAppDelegate *app = (PixiViewerAppDelegate *)[UIApplication sharedApplication].delegate;
		prev = (PixivMediumViewController *)((UINavigationController *)app.alwaysSplitViewController.detailViewController).visibleViewController;
	} else {
		if (self.navigationController.viewControllers.count > 1) {
			prev = ((PixivMediumViewController *)[self.navigationController.viewControllers objectAtIndex:[self.navigationController.viewControllers indexOfObject:self] - 1]);
			if ([prev isKindOfClass:[PixivMediumViewController class]]) {
				parent = prev;
				return prev;
			}
		}
	}

	if ([prev isKindOfClass:[PixivMediumViewController class]]) {
		parent = prev;
		return prev;
	}
	//assert(0);
	return nil;
}

- (NSString *) nextIID {
	return [[self parentMedium] nextIID];
}

- (NSString *) prevIID {
	return [[self parentMedium] prevIID];
}

- (void) updateSegment {
	UISegmentedControl *seg = (UISegmentedControl *)self.navigationItem.rightBarButtonItem.customView;
	if (progressShowing_) {
		[seg setEnabled:NO forSegmentAtIndex:0];
		[seg setEnabled:NO forSegmentAtIndex:1];
	} else {
		[seg setEnabled:[self prevIID] != nil forSegmentAtIndex:0];
		[seg setEnabled:[self nextIID] != nil forSegmentAtIndex:1];
	}
}

- (UIBarButtonItem *) saveButton {
	return [self.toolbarItems lastObject];
}

- (void) updateDisplay {
	if ([self.view viewWithTag:100]) {
		// ロード中
		[[self saveButton] setEnabled:NO];
	} else {
		// ロード済
		[[self saveButton] setEnabled:YES];	
	}
	[self updateSegment];
}

- (void) setImage:(UIImage *)img isLandscape:(BOOL)isLandscape {
	CGSize imageSize = img.size;
	//CGRect imageRect = maxCenter(imageSize, self.scrollView.frame);
	self.imageView.image = img;
	self.scrollView_.zoomScale = 1.0;
	
	DLog(@"image size: %@", NSStringFromCGSize(imageSize));
	if (imageSize.width * 4 < imageSize.height) {
		// マッチ棒
		initialScale = 1;
		scrollView_.contentSize = CGSizeMake(self.scrollView_.frame.size.width, self.scrollView_.frame.size.width * imageSize.height / imageSize.width);
		fitScale = imageSize.height / self.scrollView.contentSize.height;
	} else {
		scrollView_.contentSize = scrollView_.frame.size;
		if (imageSize.height / imageSize.width < self.scrollView.frame.size.height / self.scrollView.frame.size.width){
			// 幅木順
			initialScale = 1.0;
			fitScale = imageSize.width / self.scrollView.frame.size.width;
		} else {
			// 高崎淳
			initialScale = 1.0;
			fitScale = imageSize.height / self.scrollView.frame.size.height;
		}
	}
	DLog(@"fit size: %@", NSStringFromCGSize(CGSizeMake(self.scrollView.frame.size.width * fitScale, self.scrollView.frame.size.height * fitScale)));
		
	self.imageView.frame = CGRectMake(0, 0, scrollView_.contentSize.width, scrollView_.contentSize.height);
	self.scrollView.minimumZoomScale = MIN(fitScale, 1);
	self.scrollView.maximumZoomScale = MAX(fitScale, 2);
	self.scrollView.zoomScale = initialScale;
	
	[self.view setNeedsLayout];
}

- (void) setImage:(id)img {
	[self setImage:img isLandscape:UIInterfaceOrientationIsLandscape(self.interfaceOrientation)];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	//[self setImage:image isLandscape:UIInterfaceOrientationIsPortrait(fromInterfaceOrientation)];
	[self.scrollView setZoomScale:1 animated:YES];
}

- (NSString *) currentImageKey {
	return self.illustID;
}

- (NSString *) referer {
	return @"http://www.pixiv.net/";
}

- (ImageLoaderManager *) imageLoaderManager {
	ImageLoaderManager *loader = [ImageLoaderManager loaderWithType:ImageLoaderType_PixivBig];
	loader.referer = [self referer];
	return loader;
}

- (void) loadImage {
	[[self imageLoaderManager] loadImageForID:self.illustID url:urlString_];
	
	/*
	NSMutableURLRequest			*req = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[urlString_ stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
	assert(connection_ == nil);
	[req setValue:[self referer] forHTTPHeaderField:@"Referer"];
	imageConnection_ = [[NSURLConnection alloc] initWithRequest:req delegate:self];
	imageData_ = [[NSMutableData alloc] init];
	[req release];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorStartNotification" object:nil];
	[imageConnection_ start];
	 */
}

/*
- (void) connection:(NSURLConnection *)con didReceiveResponse:(NSURLResponse *)response {
	imageSize_ = [response expectedContentLength];
}

- (void) connection:(NSURLConnection *)con didReceiveData:(NSData *)data {
	[imageData_ appendData:data];

	UIProgressView	*view = (UIProgressView *)[self.view viewWithTag:100];
	if (view) {
		view.progress = (double)[imageData_ length] / (double)imageSize_;
	}
}

- (void) connection:(NSURLConnection *)con didFailWithError:(NSError *)error {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:nil];
	[self loaded:nil];
}

- (void) connectionDidFinishLoading:(NSURLConnection *)con {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:nil];
	[self loaded:imageData_];
}

- (NSCachedURLResponse *) connection:(NSURLConnection *)con willCacheResponse:(NSCachedURLResponse *)cachedResponse {
    return nil;
}
*/

- (void) startParser {
	NSString *fmt = [[PixitailConstants sharedInstance] valueForKeyPath:@"urls.big"];
	if (!fmt) {
		fmt = @"http://www.pixiv.net/member_illust.php?mode=big&illust_id=%@";
	}
	
	PixivBigParser			*parser = [[PixivBigParser alloc] initWithEncoding:NSUTF8StringEncoding];
	CHHtmlParserConnection	*con = [[CHHtmlParserConnectionNoScript alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:fmt, self.illustID]]];
	
	fmt = [[PixitailConstants sharedInstance] valueForKeyPath:@"urls.medium"];
	if (!fmt) {
		fmt = @"http://www.pixiv.net/member_illust.php?mode=medium&illust_id=%@";
	}
	//con.referer = @"http://www.pixiv.net/";
	con.referer = [NSString stringWithFormat:fmt, self.illustID];
	con.delegate = self;
	parser_ = parser;
	connection_ = con;
	
	[con startWithParser:parser];
}

- (void) update {
	if (self.ugoIllust) {
		[player stop];
		[player release];
		player = [[PixivUgoIllustPlayer alloc] initWithUgoIllust:self.ugoIllust];
		player.delegate = (id<PixivUgoIllustPlayerDelegate>)self;
		[player play];
		
		progressVIew.hidden = YES;
		[self scrollView].alpha = 1.0;
		[self setImage:self.ugoIllust.firstImage isLandscape:UIInterfaceOrientationIsLandscape(self.interfaceOrientation)];
		
		[self setStatusBarHidden:YES animated:YES];
		[self.navigationController setNavigationBarHidden:YES animated:YES];
		[self.navigationController setToolbarHidden:YES animated:YES];
	} else if (urlString_) {
		if ([[self imageLoaderManager] imageIsLoadedForID:self.illustID]) {
			progressVIew.hidden = YES;
			[self scrollView].alpha = 1.0;
			
			NSData *data = [[self imageLoaderManager] dataWithID:self.illustID];
			UIImage *img;
			img = [data isGIF] ? [UIImage animatedImageWithAnimatedGIFData:data] : [UIImage imageWithData:data];
			if (img) {
				[self setImage:img isLandscape:UIInterfaceOrientationIsLandscape(self.interfaceOrientation)];
				
				[self setStatusBarHidden:YES animated:YES];
				[self.navigationController setNavigationBarHidden:YES animated:YES];
				[self.navigationController setToolbarHidden:YES animated:YES];
			} else {
				[[SharedAlertView sharedInstance] showWithTitle:NSLocalizedString(@"Image load failed.", nil) message:@"" cancelButtonTitle:nil okButtonTitle:@"OK"];
			}
		} else if ([[self imageLoaderManager] imageIsLoadingForID:self.illustID]) {
			progressVIew.hidden = NO;
			progressVIew.progress = [[self imageLoaderManager] imageLoadingPercentForID:self.illustID] / 100.0;
		} else {
			progressVIew.hidden = NO;
			progressVIew.progress = 0;
			[self loadImage];
		}
	} else {
		progressVIew.hidden = NO;
		progressVIew.progress = 0;
		[self startParser];
	}
}

- (void) connection:(CHHtmlParserConnection *)con finished:(long)err {
	if (con == connection_) {
		[connection_ release];
		connection_ = nil;
		
		[urlString_ release];
		urlString_ = [[self bigParser].urlString retain];
		
		// cache
		if (urlString_) {		
			[[self pixiv] addEntries:[NSDictionary dictionaryWithObject:urlString_ forKey:@"BigURLString"] forIllustID:self.illustID];
		
			DLog(@"Big update: %@", urlString_);
			[self update];
		} else {
			[[SharedAlertView sharedInstance] showWithTitle:NSLocalizedString(@"Image load failed.", nil) message:@"" cancelButtonTitle:nil okButtonTitle:@"OK"];
		}

		[parser_ release];
		parser_ = nil;
	}
}

- (void) urlLoadCompleted:(NSNotification *)notif {
	NSString	*str = [[notif userInfo] objectForKey:@"URLString"];
	if ([urlString_ isEqualToString:str]) {
		[self performSelectorOnMainThread:@selector(update) withObject:nil waitUntilDone:NO];
	}
}

- (long) reload {
	long	err = [[self pixiv] allertReachability];
	if (err) {
		return err;
	}
	
	NSDictionary	*info = [self infoForIllustID:self.illustID];
	if ([info objectForKey:@"BigURLString"]) {
		[urlString_ release];
		urlString_ = [[info objectForKey:@"BigURLString"] retain];
		//[self update];
	} else {
		//[self startParser];
	}
	[self update];
	
	return 0;
}

#pragma mark-

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
	//self.navigationController.navigationBar.translucent = YES;
	//[self.navigationController setNavigationBarHidden:YES animated:YES];
	
	if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) {
		self.edgesForExtendedLayout = UIRectEdgeAll;
		self.automaticallyAdjustsScrollViewInsets = NO;
	}
	if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
		[self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
	}
	self.wantsFullScreenLayout = YES;
	
    [super viewDidLoad];
	
	[self.tapGestureRecognizer requireGestureRecognizerToFail:self.doubleTapGestureRecognizer];

	//[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(urlLoadCompleted:) name:@"URLCacheCompletedNotification" object:[URLCache sharedInstance]];
	
	long err = [self reload];
	if (err) {
		if (err == -1) {
		
		} else if (err == -2) {
		
		} else {
		
		}
	}
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mediumUpdated:) name:@"MediumViewControllerLoadedNotification" object:[self parentMedium]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(imageLoaded:) name:@"ImageLoaderManagerFinishedNotification" object:[self imageLoaderManager]];
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(imageLoadProgress:) name:@"ImageLoaderManagerProgressNotification" object:[self imageLoaderManager]];
}

- (void) imageLoaded:(NSNotification *)notif {
	NSString *ID = [[notif userInfo] objectForKey:@"ID"];
	if ([ID isEqualToString:self.illustID]) {
		if ([[notif userInfo] objectForKey:@"Error"]) {
			// エラー
		} else {
			[self update];
		}
	}
}

- (void) imageLoadProgress:(NSNotification *)notif {
	NSString *ID = [[notif userInfo] objectForKey:@"ID"];
	if ([ID isEqualToString:self.illustID]) {
		[self update];
	}
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	[self setProgressVIew:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[scrollView_ release];
	scrollView_ = nil;
	self.illustID = nil;
	[urlString_ release];
	urlString_ = nil;
		
	[connection_ cancel];
	connection_ = nil;
	[parser_ release];
	parser_ = nil;
	
	[self setImageView:nil];
	[self setTapGestureRecognizer:nil];
	[self setDoubleTapGestureRecognizer:nil];
	[super viewDidUnload];
}

- (void)viewWillAppear:(BOOL)animated {
	/*
	UISegmentedControl *seg = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:[UIImage imageNamed:@"up.png"], [UIImage imageNamed:@"down.png"], nil]];
	seg.segmentedControlStyle = UISegmentedControlStyleBar;
	seg.momentary = YES;
	[seg addTarget:self action:@selector(segmentAction:) forControlEvents:UIControlEventValueChanged];
	UIBarButtonItem	*item = [[UIBarButtonItem alloc] initWithCustomView:seg];
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:seg] autorelease];
	[seg release];
	[item release];
	 */
	
	[super viewWillAppear:animated];
	[self updateDisplay];
}

- (void) viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	
	[self setupToolbar];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	
	if (actionSheet_) [actionSheet_ dismissWithClickedButtonIndex:[actionSheet_ cancelButtonIndex] animated:NO];

	//[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
	//[[UIApplication sharedApplication] setStatusBarHidden:NO animated:YES];

	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		[self.navigationController setNavigationBarHidden:YES animated:YES];
		[self.navigationController setToolbarHidden:YES animated:YES];
	}
	
	/*
	if (imageConnection_) {
		[imageConnection_ cancel];
		[imageConnection_ release];
		imageConnection_ = nil;
		[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:nil];
	}
	 */
	
	player.delegate = nil;
	[player stop];
}

- (void) setupToolbar {
	NSMutableArray	*tmp = [NSMutableArray array];
	UIBarButtonItem	*item;
		
	item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
	[tmp addObject:item];
	[item release];

	CGRect rect = CGRectZero;
	rect.size.width = 160;
	rect.size.height = 40;
	if (!slider_) {
		slider_ = [[UISlider alloc] initWithFrame:rect];
	} else {
		slider_.frame = rect;
	}
	slider_.maximumValue = [[self scrollView] maximumZoomScale];
	slider_.minimumValue = [[self scrollView] minimumZoomScale];
	slider_.value = [[self scrollView] zoomScale];
	[slider_ addTarget:self action:@selector(sliderAcion:) forControlEvents:UIControlEventAllTouchEvents];
	item = [[UIBarButtonItem alloc] initWithCustomView:slider_];
	[tmp addObject:item];
	[item release];
	//slider_ = slider;
	//[slider release];

	item = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"equal.png"] style:UIBarButtonItemStylePlain target:self action:@selector(equal)];
	[tmp addObject:item];
	[item release];

	item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
	[tmp addObject:item];
	[item release];
	
	[self setToolbarItems:tmp animated:NO];
	//[self.navigationController.toolbar setItems:tmp animated:YES];
}

- (UIStatusBarStyle) preferredStatusBarStyle {
	return UIStatusBarStyleLightContent;
}

- (BOOL) prefersStatusBarHidden {
	return self.navigationController.navigationBarHidden;
}

- (void)dealloc {
	[self setProgressVIew:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	player.delegate = nil;
	[player release];
	player = nil;
	self.ugoIllust = nil;
	
	[scrollView_ release];
	scrollView_ = nil;
	self.illustID = nil;
	[urlString_ release];
	urlString_ = nil;
		
	[connection_ cancel];
	connection_ = nil;
	[parser_ release];
	parser_ = nil;

	[slider_ release];
	[progressVIew release];
	[_imageView release];
	[_tapGestureRecognizer release];
	[_doubleTapGestureRecognizer release];
    [super dealloc];
}

- (CGRect)zoomRectForScale:(float)scale withCenter:(CGPoint)center {
    CGRect zoomRect;
    
    // the zoom rect is in the content view's coordinates. 
    //    At a zoom scale of 1.0, it would be the size of the imageScrollView's bounds.
    //    As the zoom scale decreases, so more content is visible, the size of the rect grows.
    zoomRect.size.height = [[self scrollView] frame].size.height / scale;
    zoomRect.size.width  = [[self scrollView] frame].size.width  / scale;
    
    // choose an origin so as to get the right center.
    zoomRect.origin.x    = center.x - (zoomRect.size.width  / 2.0);
    zoomRect.origin.y    = center.y - (zoomRect.size.height / 2.0);
    
    return zoomRect;
}

#pragma mark UIScrollViewDelegate methods

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.imageView;
}

/************************************** NOTE **************************************/
/* The following delegate method works around a known bug in zoomToRect:animated: */
/* In the next release after 3.0 this workaround will no longer be necessary      */
/**********************************************************************************/
- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale {
    [scrollView setZoomScale:scale+0.01 animated:NO];
    [scrollView setZoomScale:scale animated:NO];
	slider_.value = scale;
}

#pragma mark TapDetectingViewDelegate methods

- (IBAction)tapGesture:(id)sender {
	if (self.navigationController.navigationBarHidden) {
		if ([UIDevice currentDevice].systemVersion.floatValue < 7.0) {
			[self setStatusBarHidden:NO animated:YES];
		}
		[self.navigationController setNavigationBarHidden:NO animated:YES];
		[self.navigationController setToolbarHidden:NO animated:YES];
	} else {
		if ([UIDevice currentDevice].systemVersion.floatValue < 7.0) {
			[self setStatusBarHidden:YES animated:YES];
		}
		[self.navigationController setNavigationBarHidden:YES animated:YES];
		[self.navigationController setToolbarHidden:YES animated:YES];
	}
	if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
		[self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
	}
}

- (IBAction)doubleTapGesture:(UITapGestureRecognizer *)sender {
	CGPoint tapPoint = [sender locationInView:self.scrollView];
    float newScale;
	if ([[self scrollView] zoomScale] == initialScale) {
		newScale = fitScale;
    } else {
		newScale = initialScale;
	}
	CGRect zoomRect = [self zoomRectForScale:newScale withCenter:tapPoint];
    [[self scrollView] zoomToRect:zoomRect animated:YES];
}

/*
- (void)tapDetectingView:(TapDetectingView *)view gotSingleTapAtPoint:(CGPoint)tapPoint {
    // single tap does nothing for now
	
	if (self.navigationController.navigationBarHidden) {
		//[[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
		[self setStatusBarHidden:NO animated:YES];
		[self.navigationController setNavigationBarHidden:NO animated:YES];
		[self.navigationController setToolbarHidden:NO animated:YES];
	} else { 
		//self.navigationController.navigationBar.translucent = YES;
		//[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
		[self setStatusBarHidden:YES animated:YES];
		[self.navigationController setNavigationBarHidden:YES animated:YES];
		[self.navigationController setToolbarHidden:YES animated:YES];
		//self.navigationController.navigationBar.translucent = YES;
	}
}

- (void)tapDetectingView:(TapDetectingView *)view gotDoubleTapAtPoint:(CGPoint)tapPoint {
    // double tap zooms in
    float newScale;
	if ([[self scrollView] zoomScale] == fitScale) {
		newScale = [[self scrollView] zoomScale] * ZOOM_STEP;
    } else {
		newScale = fitScale;
	}
	CGRect zoomRect = [self zoomRectForScale:newScale withCenter:tapPoint];
    [[self scrollView] zoomToRect:zoomRect animated:YES];
}

- (void)tapDetectingView:(TapDetectingView *)view gotTwoFingerTapAtPoint:(CGPoint)tapPoint {
    // two-finger tap zooms out
    float newScale = [[self scrollView] zoomScale] / ZOOM_STEP;
    CGRect zoomRect = [self zoomRectForScale:newScale withCenter:tapPoint];
    [[self scrollView] zoomToRect:zoomRect animated:YES];
}
*/

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	if ([[NSUserDefaults standardUserDefaults] objectForKey:@"Autorotate"]) {
		return [[NSUserDefaults standardUserDefaults] boolForKey:@"Autorotate"];
	} else {
		return YES;
	}
}

- (NSString *) serviceName {
	return @"pixiv";
}

- (NSString *) url {
	return [NSString stringWithFormat:@"http://www.pixiv.net/member_illust.php?mode=medium&illust_id=%@", self.illustID];
}

- (NSString *) parserClassName {
	return @"PixivBigParser";
}

- (NSString *) sourceURL {
	return [NSString stringWithFormat:@"http://www.pixiv.net/member_illust.php?mode=big&illust_id=%@", self.illustID];
}

/*
- (void) save {
	NSData *data = [[self cache] imageDataForKey:self.illustID];

		NSDictionary	*info = [self infoForIllustID:self.illustID];
		NSString		*title = [info objectForKey:@"Title"];
		NSString		*user = [info objectForKey:@"UserName"];
		NSMutableArray	*tags = [NSMutableArray array];
		for (NSDictionary *tag in [info objectForKey:@"Tags"]) {
			[tags addObject:[tag objectForKey:@"Name"]];
		}
		[tags addObject:[self serviceName]];
		if (!title) {
			title = [urlString_ lastPathComponent];
		}
		if (!title) {
			title = self.illustID;
		}
		
		NSArray *a_paths = NSSearchPathForDirectoriesInDomains( NSCachesDirectory, NSUserDomainMask, YES );
		NSString *local = nil;
		if ([a_paths count] > 0) {
			CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
			NSString *uuidStr = [(id)CFUUIDCreateString(kCFAllocatorDefault, uuid) autorelease];
			CFRelease(uuid);
			local = [[a_paths objectAtIndex:0] stringByAppendingPathComponent:uuidStr];
		} else {
			assert(0);
		}
		
		if (local && UDBoolWithDefault(@"SaveToDropBox", NO)) {
			NSString *p = [local stringByAppendingString:@"_db"];
			[data writeToFile:p atomically:YES];

			[[DropBoxTail sharedInstance] upload:[NSDictionary dictionaryWithObjectsAndKeys:
				[self parserClassName],	@"ParserClass",
				[self sourceURL],		@"SourceURL",
				p,						@"Path",
				title,					@"Name",
				user,					@"Username",
				[self serviceName],		@"ServiceName",
				nil]];
		}

		if (local && UDBoolWithDefault(@"SaveToEvernote", NO)) {
			NSString *p = [local stringByAppendingString:@"_en"];
			[data writeToFile:p atomically:YES];

			[[EvernoteTail sharedInstance] upload:[NSDictionary dictionaryWithObjectsAndKeys:
				[self parserClassName],				@"ParserClass",
				[self sourceURL],					@"SourceURL",
				title,								@"Title",
				p,									@"Path",
				NSStringFromCGSize(image_.size),	@"Size",
				user,								@"Username",
				[self serviceName],					@"ServiceName",
				tags,								@"Tags",
				[self url],							@"URL",
				nil]];
		}

	if (UDBoolWithDefault(@"SaveToCameraRoll", YES)) {
		UIImageWriteToSavedPhotosAlbum(image_, nil, nil, nil);
	}
	
	[self saveButton].enabled = NO;
}
 */

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
	UIAlertView	*alert;
	if (error) {
		alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Save failed.", @"") message:@"" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];	
	} else {
		alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Save ok.", @"") message:@"" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
	}
	[alert show];
	[alert release];	
}
		
- (void) sliderAcion:(id)sender {
	[[self scrollView] setZoomScale:[slider_ value]];
}

- (void) goToTop {
	[self.navigationController popToViewController:[self.navigationController.viewControllers objectAtIndex:1] animated:YES];
}

- (void) equal {
	[[self scrollView] setZoomScale:fitScale];
	slider_.value = fitScale;
}

#pragma mark-

/*- (void) pixService:(PixService *)sender loginFinished:(long)err {
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
*/

#pragma mark-

- (NSMutableDictionary *) storeInfo {
	NSMutableDictionary *info = [super storeInfo];
	
	[info setObject:illustID forKey:@"IllustID"];
	if (urlString_) [info setObject:urlString_ forKey:@"URLString"];

	return info;
}

- (BOOL) needsStore {
	return NO;
}

- (BOOL) restore:(NSDictionary *)info {
	id obj;
	
	obj = [info objectForKey:@"IllustID"];
	if (obj == nil) {
		return NO;
	}
	self.illustID = obj;

	obj = [info objectForKey:@"URLString"];
	[urlString_ release];
	urlString_ = [obj retain];

	return YES;
}

#pragma mark-

/*
- (PixivMatrixViewController *) parentMatrix {
	if (self.navigationController.viewControllers.count > 3) {
		PixivMatrixViewController *prev = ((PixivMatrixViewController *)[self.navigationController.viewControllers objectAtIndex:[self.navigationController.viewControllers count] - 3]);
		if ([prev isKindOfClass:[PixivMatrixViewController class]]) {
			return prev;
		}
	}
	return nil;
}
*/

- (Class) mangaClass {
	return [PixivMangaViewController class];
}

- (UIViewController *) viewControllerWithID:(NSString *)idt {
	NSDictionary	*info = [self infoForIllustID:idt];
	
	PixivBigViewController *controller = nil;
	if ([[info objectForKey:@"IllustMode"] isEqualToString:@"manga"]) {
		// manga
		controller = [[[self mangaClass] alloc] init];
	} else if ([info objectForKey:@"Images"] != nil) {
		// manga
		controller = [[[self mangaClass] alloc] init];

		NSMutableArray *ary = [NSMutableArray array];
		for (NSDictionary *i in [info objectForKey:@"Images"]) {
			[ary addObject:[i objectForKey:@"URLString"]];
		}
		[controller performSelector:@selector(setURLs:) withObject:ary];
	} else {
		// big
		controller = [[[self class] alloc] initWithNibName:@"PixivBigViewController" bundle:nil];
	}
	controller.illustID = idt;
	//controller.navigationController = self.navigationController;
	return [controller autorelease];
}

- (void) replaceViewController:(UIViewController *)vc {
	//[[self retain] autorelease];
	
	NSMutableArray *ary = [NSMutableArray arrayWithArray:self.navigationController.viewControllers];
	[ary removeObject:self];
	[ary addObject:vc];
	self.navigationController.viewControllers = ary;
	
	//[self.navigationController popViewControllerAnimated:NO];
	//[self.navigationController pushViewController:vc animated:NO];
	//[self performSelector:@selector(pushDelay:) withObject:vc afterDelay:0.1];
}

- (void) pushDelay:(UIViewController *)vc {
	[self.navigationController pushViewController:vc animated:NO];
}

- (BOOL) infoIsValid:(NSDictionary *)info {
	return [info objectForKey:@"MediumURLString"] != nil;
}

- (void) go:(NSString *)idt {
	NSDictionary	*info = [self infoForIllustID:idt];
	if ([self infoIsValid:info]) {
		[self replaceViewController:[self viewControllerWithID:idt]];
	} else {
		UIActivityIndicatorView	*act = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
		CGRect	frame = [act frame];
		//frame.size.width = [UIScreen mainScreen].bounds.size.width * 2.0 / 3.0;
		frame.origin.x = (self.view.frame.size.width - frame.size.width) / 2.0;
		frame.origin.y = (self.view.frame.size.height - frame.size.height) / 2.0;
		[act setFrame:frame];
		[act setTag:1000];
		act.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
		[self.view addSubview:act];
		[act startAnimating];
		[act release];
		[self scrollView].alpha = 0.25;
		
		UISegmentedControl *seg = (UISegmentedControl *)self.navigationItem.rightBarButtonItem.customView;
		[seg setEnabled:NO forSegmentAtIndex:0];
		[seg setEnabled:NO forSegmentAtIndex:1];
		
		[self saveButton].enabled = NO;
	}
}

- (void) next {
	[self go:[self nextIID]];

	[[self parentMedium] next];
}

- (void) prev {
	[self go:[self prevIID]];

	[[self parentMedium] prev];
}

- (IBAction ) segmentAction:(id)sender {
	UISegmentedControl	*seg = sender;
	if (seg.selectedSegmentIndex == 0 && [self prevIID]) {
		// up
		[self prev];
	} else if ([self nextIID]) {
		//
		[self next];
	}
}

- (void) mediumUpdated:(NSNotification *)notif {
	PixivMediumViewController *medium = [self parentMedium];
	if (medium == nil) {
		return;
	}
	
	if ([medium.illustID isEqual:self.illustID] == NO) {
		NSDictionary	*info = [self infoForIllustID:medium.illustID];
		if ([info objectForKey:@"MediumURLString"]) {
			[self replaceViewController:[self viewControllerWithID:medium.illustID]];
		} else {
			[medium reload];
		}
	}
}

- (void) frameChanged:(id)sender image:(UIImage *)image {
	self.imageView.image = image;
}

@end
