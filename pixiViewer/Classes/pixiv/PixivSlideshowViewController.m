//
//  PixivSlideshowViewController.m
//  pixiViewer
//
//  Created by nya on 09/09/06.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PixivSlideshowViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "PixivMediumViewController.h"
#import "Pixiv.h"
#import "PixivMatrixParser.h"
#import "PixivMediumParser.h"
#import "ImageDiskCache.h"
#import "AccountManager.h"
#import "PixitailConstants.h"
#import "CHHtmlParserConnectionNoScript.h"
#import "PixivUgoIllust.h"
#import "RegexKitLite.h"


@class SlideshowImageLoader;
@protocol SlideshowImageLoaderDelegate
- (void) loader:(SlideshowImageLoader *)sender finished:(long)err;
- (NSString *) referer;
- (PixService *) pixiv;
- (MediumParser *) mediumParser;
- (NSString *) mediumURL:(NSString *)str;
- (ImageCache *) cache;
@end


@interface SlideshowImageLoader : NSObject<CHHtmlParserConnectionDelegate> {
	int				index;
	NSString		*illustID;
	NSDictionary	*info;
	id<SlideshowImageLoaderDelegate> delegate;

	MediumParser				*mediumParser_;
	CHHtmlParserConnection		*mediumConnection_;

	NSURLConnection		*imageConnection_;
	NSMutableData		*imageData_;
	
	PixivUgoIllust *ugoIllust_;
}

@property(assign, readwrite, nonatomic) int index;
@property(retain, readwrite, nonatomic) NSString *illustID;
@property(retain, readwrite, nonatomic) NSDictionary *info;
@property(assign, readwrite, nonatomic) id<SlideshowImageLoaderDelegate> delegate;
@property(assign, readonly, nonatomic) BOOL loading;

- (long) load;
- (void) cancel;

@end


@implementation SlideshowImageLoader

@synthesize index;
@synthesize illustID;
@synthesize info;
@synthesize delegate;
@dynamic loading;

- (void) dealloc {
	[self cancel];

	self.illustID = nil;
	self.info = nil;
	[ugoIllust_ release];
	ugoIllust_ = nil;
	
	[super dealloc];
}

- (BOOL) loading {
	return (mediumConnection_ || imageConnection_);
}

- (long) loadMediumImage {
	DLog(@"loadMediumImage: %@", self.illustID);
	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorStartNotification" object:self];
	if (self.info[@"UgoInfo"]) {
		[ugoIllust_ release];
		ugoIllust_ = [[PixivUgoIllust alloc] initWithInfo:self.info[@"UgoInfo"]];
		ugoIllust_.delegate = (id<PixivUgoIllustDelegate>)self;
		[ugoIllust_ load];
	} else {
		NSMutableURLRequest	*req;
		req = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[self.info objectForKey:@"MediumURLString"]]];
		[req setValue:[self.delegate referer] forHTTPHeaderField:@"Referer"];
		
		NSURLConnection	*con = [[NSURLConnection alloc] initWithRequest:req delegate:self];
		[req release];
		
		imageData_ = [[NSMutableData alloc] init];
		imageConnection_ = con;
		[con start];
	}
	return 0;
}

- (long) loadMedium {
	DLog(@"loadMedium");
	NSMutableDictionary		*inf;
	
	inf = [[[[self.delegate pixiv] infoForIllustID:self.illustID] mutableCopy] autorelease];
	if (!inf) {
		MediumParser			*parser = [self.delegate mediumParser];
		CHHtmlParserConnection	*con = [[CHHtmlParserConnectionNoScript alloc] initWithURL:[NSURL URLWithString:[self.delegate mediumURL:self.illustID]]];
		[con setReferer:[self.delegate referer]];
		con.delegate = self;
		
		[mediumConnection_ cancel];
		[mediumConnection_ release];
		mediumConnection_ = nil;
		
		mediumParser_ = [parser retain];
		mediumConnection_ = con;
		
		[mediumConnection_ startWithParser:mediumParser_];
	} else {		
		[inf setObject:[NSNumber numberWithInt:self.index] forKey:@"Index"];
		
		self.info = inf;
		return [self loadMediumImage];	
	}
	return 0;
}

- (void) finishDelay {
	[self.delegate loader:self finished:0];
}

- (long) load {
	DLog(@"load: %@", self.illustID);
	UIImage *img = [[self.delegate cache] imageForKey:self.illustID];
	if (img) {
		if ([[self.delegate cache] isGifPng:self.illustID]) {
			CGRect ir;
			ir.origin = CGPointZero;
			ir.size = img.size;
			UIGraphicsBeginImageContext(img.size);
			
			[[UIColor whiteColor] set];
			UIRectFill(ir);
			
			[img drawAtPoint:CGPointZero];
			img = UIGraphicsGetImageFromCurrentImageContext();

			UIGraphicsEndImageContext();						
		}
	
		NSMutableDictionary	*ret = [NSMutableDictionary dictionary];
		[ret setObject:[NSNumber numberWithInt:self.index] forKey:@"Index"];
		[ret setObject:self.illustID forKey:@"IllustID"];
		[ret setObject:img forKey:@"Image"];
		self.info = ret;
	
		[self performSelector:@selector(finishDelay) withObject:nil afterDelay:0.2];
		return 0;
	} else {
		return [self loadMedium];
	}
}

- (void) cancel {
	[mediumConnection_ cancel];
	[mediumConnection_ release];
	mediumConnection_ = nil;
	[mediumParser_ release];
	mediumParser_ = nil;
	
	if (imageConnection_) {
		[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:self];	
	}
	[imageConnection_ cancel];
	[imageConnection_ release];
	imageConnection_ = nil;
	[imageData_ release];
	imageData_ = nil;
	
	self.delegate = nil;
}

#pragma mark-

- (void) connection:(CHHtmlParserConnectionNoScript *)con finished:(long)err {
	DLog(@"loaded: %@", self.illustID);

	NSMutableDictionary *parserInfo = [[mediumParser_.info mutableCopy] autorelease];
	if ([con respondsToSelector:@selector(scripts)]) {
		NSString *regex = [[PixitailConstants sharedInstance] valueForKeyPath:@"constants.ugo_info_regex"];
		if (regex) {
			NSString *ugoString = nil;
			for (NSString *str in con.scripts) {
				NSArray *ary = [str captureComponentsMatchedByRegex:regex];
				if (ary.count > 0) {
					ugoString = ary.lastObject;
					break;
				}
			}
			if (ugoString) {
				id ugo = [NSJSONSerialization JSONObjectWithData:[ugoString dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
				if (ugo) {
					[parserInfo setObject:ugo forKey:@"UgoInfo"];
				}
			}
		}
	}
	
	if ([parserInfo objectForKey:@"MediumURLString"] || [parserInfo objectForKey:@"UgoInfo"]) {
		[parserInfo setObject:[NSNumber numberWithInt:self.index] forKey:@"Index"];
		[parserInfo setObject:self.illustID forKey:@"IllustID"];
				
		[[self.delegate pixiv] addEntries:parserInfo forIllustID:self.illustID];
		self.info = parserInfo;
		[self loadMediumImage];
	} else {
		if (err == 0) {
			err = -1;
		}
	}
	
	[mediumParser_ release];
	mediumParser_ = nil;
	[mediumConnection_ release];
	mediumConnection_ = nil;		

	if (err) {
		[self.delegate loader:self finished:err];
	}
}

#pragma mark-

- (void) connection:(NSURLConnection *)con didReceiveResponse:(NSURLResponse *)response {
}

- (void) connection:(NSURLConnection *)con didReceiveData:(NSData *)data {
	[imageData_ appendData:data];
}

- (void) connection:(NSURLConnection *)con didFailWithError:(NSError *)error {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:self];

	[imageData_ release];
	imageData_ = nil;
	[imageConnection_ release];
	imageConnection_ = nil;

	[self.delegate loader:self finished:[error code]];
}

- (void) connectionDidFinishLoading:(NSURLConnection *)con {
	DLog(@"loadMediumImage finish: %@", self.illustID);
	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:self];

	UIImage	*img = [[[UIImage alloc] initWithData:imageData_] autorelease];
	long err = 0;
	if (img) {
		[[self.delegate cache] setImageData:imageData_ forKey:self.illustID];
		if ([[self.delegate cache] isGifPng:self.illustID]) {
			CGRect ir;
			ir.origin = CGPointZero;
			ir.size = img.size;
			UIGraphicsBeginImageContext(img.size);
			
			[[UIColor whiteColor] set];
			UIRectFill(ir);
			
			[img drawAtPoint:CGPointZero];
			img = UIGraphicsGetImageFromCurrentImageContext();

			UIGraphicsEndImageContext();						
		}

		NSMutableDictionary	*ret = [self.info mutableCopy];
		[ret setObject:img forKey:@"Image"];
		self.info = ret;
		[ret release];
	} else {
		err = -1;
		//assert(0);
	}
	[imageData_ release];
	imageData_ = nil;
	[imageConnection_ release];
	imageConnection_ = nil;
	
	[self.delegate loader:self finished:0];
}

- (NSCachedURLResponse *) connection:(NSURLConnection *)con willCacheResponse:(NSCachedURLResponse *)cachedResponse {
    return nil;
}

#pragma mark-

- (void) ugoIllustLoaded:(id)sender error:(NSError *)err {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:self];
	
	NSMutableDictionary	*ret = [self.info mutableCopy];
	[ret setObject:[[[PixivUgoIllustPlayer alloc] initWithUgoIllust:ugoIllust_] autorelease] forKey:@"Player"];
	self.info = ret;
	[ret release];
	
	[self.delegate loader:self finished:[err code]];
}

@end


@interface SlideshowImageStorage : NSObject<SlideshowImageLoaderDelegate> {
	id<SlideshowImageStorageDelegate>	delegate;

	NSMutableDictionary		*loader_;
	NSString				*loadingIllustID;
}

@property(assign, readwrite, nonatomic) id<SlideshowImageStorageDelegate> delegate;
@property(assign, readonly, nonatomic) NSString *loadingIllustID;

- (void) setLoadIllusts:(NSArray *)ary;
- (void) getIllust:(NSString *)iid;
- (void) cancel;

@end


@implementation SlideshowImageStorage

@synthesize delegate;
@synthesize loadingIllustID;

- (ImageCache *) cache {
	return [delegate cache];
}

- (id) init {
	self = [super init];
	if (self) {
		loader_ = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (void) dealloc {
	NSAutoreleasePool	*pool = [[NSAutoreleasePool alloc] init];
	[self cancel];
	[loader_ release];
	[pool release];
	
	[super dealloc];
}

- (void) cancel {
	for (SlideshowImageLoader *loader in [loader_ allValues]) {
		[loader cancel];
	}
	[loader_ removeAllObjects];
}

- (void) setLoadIllusts:(NSArray *)ary {
	NSMutableArray	*remove = [NSMutableArray array];
	for (NSString *key in [loader_ allKeys]) {
		if (![ary containsObject:key]) {
			[remove addObject:key];
		}
	}
	
	for (NSString *i in remove) {
		SlideshowImageLoader *l = [loader_ objectForKey:i];
		[l cancel];
	}
	[loader_ removeObjectsForKeys:remove];
	for (NSString *iid in ary) {
		if (![[loader_ allKeys] containsObject:iid]) {
			SlideshowImageLoader *loader = [[SlideshowImageLoader alloc] init];
			loader.illustID = iid;
			loader.delegate = self;
		
			[loader_ setObject:loader forKey:iid];
			[loader load];
			[loader release];
		}
	}
}

- (void) getIllust:(NSString *) iid {
	DLog(@"getIllust: %@", iid);
@synchronized(self) {
	SlideshowImageLoader *loader = [loader_ objectForKey:iid];
	if (loader) {
		if ([loader.info objectForKey:@"Image"] || [loader.info objectForKey:@"Player"]) {
			[self.delegate storage:self loadIllust:loader.info finished:0];
		} else if (loader.loading) {
			loadingIllustID = [iid retain];
		} else {
			[self.delegate storage:self loadIllust:nil finished:-1];	
		}
	} else {
		[self.delegate storage:self loadIllust:nil finished:-1];	
	}
}
}

- (void) loader:(SlideshowImageLoader *)sender finished:(long)err {
@synchronized(self) {
	if ([loadingIllustID isEqualToString:sender.illustID]) {
		[self.delegate storage:self loadIllust:sender.info finished:err];
		[loadingIllustID release];
		loadingIllustID = nil;
	}
}
}

- (NSString *) referer {
	return [self.delegate referer];
}

- (PixService *) pixiv {
	return [self.delegate pixiv];
}

- (MediumParser *) mediumParser {
	return [self.delegate mediumParser];
}

- (NSString *) mediumURL:(NSString *)str {
	return [self.delegate mediumURL:str];
}

@end



@interface PixivSlideshowViewController(Private)
- (void) reload;
- (void) reflesh;

- (void) loadImageThreadStart;
- (void) loadImageThreadStop;

- (void) startSlideThread;
- (void) stopSlideThread;
- (void) slideThreadOneShot;

- (void) start;
- (void) stop;
- (void) pause;
- (void) resume;
- (void) next;
- (void) prev;

- (BOOL) paused;

- (void) updateDisplay;

- (NSTimeInterval) slideInterval;
- (NSInteger) currentImageIndex;

- (void) slideTimer:(NSTimer *)timer;
@end


@implementation PixivSlideshowViewController

@synthesize method, clockView, account, scrapingInfoKey;

- (BOOL) enableClock {
	return [[NSUserDefaults standardUserDefaults] boolForKey:@"SlideshowEnableClock"];
}

- (ImageCache *) cache {
	return [ImageCache pixivMediumCache];
}

- (NSString *) referer {
	return @"http://www.pixiv.net/";
}

- (NSString *) matrixURL {
	return [NSString stringWithFormat:@"http://www.pixiv.net/%@p=%d", self.method, loadedPage_ + 1];
}

- (NSString *) mediumURL:(NSString *)iid {
	return [NSString stringWithFormat:@"http://www.pixiv.net/member_illust.php?mode=medium&illust_id=%@", iid];
}

- (MediumParser *) mediumParser {
	return (MediumParser *)[[[PixivMediumParser alloc] initWithEncoding:NSUTF8StringEncoding] autorelease];
}

- (MatrixParser *) matrixParser {
	PixivMatrixParser *parser = [[[PixivMatrixParser alloc] initWithEncoding:NSUTF8StringEncoding async:NO] autorelease];
	if (scrapingInfoKey) {
		NSDictionary *d = [[PixitailConstants sharedInstance] valueForKeyPath:scrapingInfoKey];
		if (d) {
			parser.scrapingInfo = d;
		}
	}
	return (MatrixParser *)parser;
}

- (PixivMediumViewController *) mediumViewController {
	return [[[PixivMediumViewController alloc] init] autorelease];
}

- (PixService *) pixiv {
	return [Pixiv sharedInstance];
}


/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        // Custom initialization
    }
    return self;
}
*/

- (NSTimeInterval) slideInterval {
	//return 1;
	NSTimeInterval intv = [[NSUserDefaults standardUserDefaults] integerForKey:@"SlideshowInterval"];
	if (intv == 0) intv = 10;
	return intv;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	CGRect	frame;
	frame.size = [self.view frame].size;
	frame.origin = CGPointZero;
	
	self.wantsFullScreenLayout = YES;

	imageView1_ = [[UIImageView alloc] initWithFrame:frame];
	imageView2_ = [[UIImageView alloc] initWithFrame:frame];
	if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"SlideshowDisplay"] isEqualToString:@"AspectFill"]) {
		imageView1_.contentMode = UIViewContentModeScaleAspectFill;
		imageView2_.contentMode = UIViewContentModeScaleAspectFill;
	} else {
		imageView1_.contentMode = UIViewContentModeScaleAspectFit;
		imageView2_.contentMode = UIViewContentModeScaleAspectFit;
	}
	imageView1_.hidden = YES;
	imageView2_.hidden = YES;
	imageView1_.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
	imageView2_.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
	[self.view addSubview:imageView1_];
	[self.view addSubview:imageView2_];
	transitioning = NO;
	
	if (!illustIDs_) {
		illustIDs_ = [[NSMutableArray alloc] init];
	}
	
	if (!storage_) {
		storage_ = [[SlideshowImageStorage alloc] init];
		storage_.delegate = self;
	}
	
	paused_ = NO;
	started_ = NO;
	
	loadedPage_ = 0;
	displayIllistIndex_ = 0;
	//[self reflesh];
	
	if ([self enableClock]) {
		[self.view bringSubviewToFront:self.clockView];
		[self.clockView viewDidLoad];
		self.clockView.hidden = NO;
	}

    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	[matrixConnection_ cancel];
	[matrixConnection_ release];
	matrixConnection_ = nil;
	
	[matrixParser_ release];
	matrixParser_ = nil;
	
	[self stop];
	
	//[storage_ release];
	//storage_ = nil;

	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
	[imageView1_ release];
	imageView1_ = nil;
	[imageView2_ release];
	imageView2_ = nil;

	self.view = nil;
	
	[currentInfo_ release];
	currentInfo_ = nil;

	self.method = nil;
	
	[self.clockView viewDidUnload];
	self.clockView = nil;
}


- (void)dealloc {
	[matrixConnection_ cancel];
	[matrixConnection_ release];
	matrixConnection_ = nil;
	
	[matrixParser_ release];
	matrixParser_ = nil;
	
	[self stop];
	
	//[storage_ release];
	//storage_ = nil;
	
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
	[imageView1_ release];
	imageView1_ = nil;
	[imageView2_ release];
	imageView2_ = nil;
	
	self.view = nil;
	
	[currentInfo_ release];
	currentInfo_ = nil;
	
	self.method = nil;
	self.clockView = nil;
	
	[storage_ release];
	[illustIDs_ release];
	[illustIDsTmp_ release];
	
	[account release];
	self.scrapingInfoKey = nil;
	
    [super dealloc];
}


- (void)viewWillAppear:(BOOL)animated {	
/*
	UIBarButtonItem	*right = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(goMedium)];
	[right setEnabled:YES];
	self.navigationItem.rightBarButtonItem = right;
	[right release];
	
	//[[UIApplication sharedApplication] setStatusBarHidden:NO animated:NO];
	[[UIApplication sharedApplication] setStatusBarHidden:YES animated:NO];

	self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
	self.navigationController.navigationBar.translucent = YES;
	[self.navigationController setNavigationBarHidden:YES animated:NO];
	[self.navigationController setNavigationBarHidden:NO animated:NO];
	
	self.navigationController.toolbar.barStyle = UIBarStyleBlackTranslucent;
	[self.navigationController setToolbarHidden:NO animated:NO];

	[self start];
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"SlideshowDisableIdleTimer"]) {
		[UIApplication sharedApplication].idleTimerDisabled = YES;
	}

	if (imageView1_.image == nil && imageView2_.image == nil && ![self.view viewWithTag:100]) {
		UIActivityIndicatorView	*indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
		CGRect	rect = [indicator frame];
		rect.origin.x = ([self.view frame].size.width - rect.size.width) / 2;
		rect.origin.y = ([self.view frame].size.height - rect.size.height) / 2 + 44;
		[indicator setFrame:rect];
		[indicator setTag:100];
		[self.view addSubview:indicator];
		[indicator startAnimating];
	}
*/
	//[self reload];

	//[self start];
}

- (void)viewWillDisappear:(BOOL)animated {
	if (actionSheet_) [actionSheet_ dismissWithClickedButtonIndex:[actionSheet_ cancelButtonIndex] animated:NO];

	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		[self.navigationController setNavigationBarHidden:YES animated:YES];
		[self.navigationController setToolbarHidden:YES animated:YES];
	}

	[UIApplication sharedApplication].idleTimerDisabled = NO;
	
	[self stop];
	if (matrixConnection_) {
		[matrixConnection_ cancel];
		[matrixConnection_ release];
		matrixConnection_ = nil;
	}
}

- (void)viewDidAppear:(BOOL)animated {
	UIBarButtonItem	*right = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(action:)];
	[right setEnabled:YES];
	self.navigationItem.rightBarButtonItem = right;
	[right release];
	
	//[[UIApplication sharedApplication] setStatusBarHidden:NO animated:NO];
	//[[UIApplication sharedApplication] setStatusBarHidden:YES animated:NO];

	//self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
	//self.navigationController.navigationBar.translucent = YES;
	//[self.navigationController setNavigationBarHidden:YES animated:NO];
	//[self.navigationController setNavigationBarHidden:NO animated:NO];
	
	//self.navigationController.toolbar.barStyle = UIBarStyleBlackTranslucent;
	//[self.navigationController setToolbarHidden:NO animated:NO];

	//[self start];
	
	if ([[NSUserDefaults standardUserDefaults] boolForKey:@"SlideshowDisableIdleTimer"]) {
		[UIApplication sharedApplication].idleTimerDisabled = YES;
	}

	if (imageView1_.image == nil && imageView2_.image == nil && ![self.view viewWithTag:100]) {
		UIActivityIndicatorView	*indicator = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge] autorelease];
		CGRect	rect = [indicator frame];
		rect.origin.x = ([self.view frame].size.width - rect.size.width) / 2;
		rect.origin.y = ([self.view frame].size.height - rect.size.height) / 2;
		[indicator setFrame:rect];
		[indicator setTag:100];
		[self.view addSubview:indicator];
		[indicator startAnimating];
	}

	//self.navigationController.toolbar.barStyle = UIBarStyleBlackTranslucent;
	//[self.navigationController setToolbarHidden:NO animated:NO];
	//[self.navigationController.toolbar setNeedsDisplay];
	
	[self updateDisplay];
	if ([illustIDs_ count] == 0) {
		[self reload];
	}
	[self start];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	if ([self.view viewWithTag:100]) {
		// 読み込み中
		return;
	}
	
	if (self.navigationController.navigationBarHidden) {
		//[[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
		[self setStatusBarHidden:NO animated:YES];
		[self.navigationController setNavigationBarHidden:NO animated:YES];
		[self.navigationController setToolbarHidden:NO animated:YES];
	} else { 
		[self setStatusBarHidden:YES animated:YES];
		//[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
		[self.navigationController setNavigationBarHidden:YES animated:YES];
		[self.navigationController setToolbarHidden:YES animated:YES];
	}

	if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
		[self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
	}
	
	[self updateDisplay];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	if ([[NSUserDefaults standardUserDefaults] objectForKey:@"Autorotate"]) {
		return [[NSUserDefaults standardUserDefaults] boolForKey:@"Autorotate"];
	} else {
		return YES;
	}
}

- (void) updateDisplay {
	UIBarButtonItem	*item;
	BOOL			b;
	
	// action
	item = self.navigationItem.rightBarButtonItem;
	b = NO;
	if ([self paused] && (imageView1_.image != nil || imageView2_.image != nil)) {
		b = YES;
	}
	[item setEnabled:b];
	
	
	//pthread_mutex_lock(&imageCacheMutex_);
	{
		NSMutableArray	*tmp = [NSMutableArray array];
		UIBarButtonItem	*item;
		NSInteger				currentIndex = [self currentImageIndex];
		
		item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRewind target:self action:@selector(prevAction)];
		[tmp addObject:item];
		[item setEnabled:currentIndex > 0 && currentIndex < [illustIDs_ count]];
		[item release];

		item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
		[tmp addObject:item];
		[item release];

		if ([self paused]) {
			item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(playAction)];
		} else {
			item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPause target:self action:@selector(playAction)];
		}
		[tmp addObject:item];
		[item setEnabled:currentIndex >= 0];
		[item release];
		
		item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
		[tmp addObject:item];
		[item release];

		item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFastForward target:self action:@selector(nextAction)];
		[tmp addObject:item];
		[item setEnabled:currentIndex >= 0 && currentIndex < [illustIDs_ count] - 1];
		[item release];
		
		[self setToolbarItems:tmp animated:NO];
		//[self.navigationController.toolbar setItems:tmp animated:NO];
	}
	//pthread_mutex_unlock(&imageCacheMutex_);

	if ([self enableClock]) {
		[self.view bringSubviewToFront:self.clockView];
	}
}

- (void) setContents:(NSArray *)ary random:(BOOL)b reverse:(BOOL)rev {
	if (!illustIDs_) {
		illustIDs_ = [[NSMutableArray alloc] initWithCapacity:[ary count]];
	} else {
		//[illustIDs_ removeAllObjects];
	}
	
	if (b) {
		NSMutableArray *tmp = [NSMutableArray arrayWithArray:ary];
		while ([tmp count] > 0) {
			srand((unsigned)time(NULL));
			
			NSUInteger idx = rand() % [tmp count];
			NSDictionary *info = [tmp objectAtIndex:idx];
			NSString *iid;
			if ([info isKindOfClass:[NSDictionary class]]) {
				iid = [info objectForKey:@"IllustID"];
			} else {
				iid = (NSString *)info;
			}
			if (![illustIDs_ containsObject:iid]) {
				[illustIDs_ addObject:iid];
			}
			[tmp removeObjectAtIndex:idx];
		}
	} else if (rev) {
		NSMutableArray *mary = [NSMutableArray array];
		for (NSDictionary *info in ary) {
			NSString *iid;
			if ([info isKindOfClass:[NSDictionary class]]) {
				iid = [info objectForKey:@"IllustID"];
			} else {
				iid = (NSString *)info;
			}
			if (![illustIDs_ containsObject:iid]) {
				[mary addObject:iid];
			} else {
				break;
			}
		}
		for (NSString *iid in [mary reverseObjectEnumerator]) {
			[illustIDs_ addObject:iid];
		}
	} else {
		for (NSDictionary *info in ary) {
			NSString *iid;
			if ([info isKindOfClass:[NSDictionary class]]) {
				iid = [info objectForKey:@"IllustID"];
			} else {
				iid = (NSString *)info;
			}
			if (![illustIDs_ containsObject:iid]) {
				[illustIDs_ addObject:iid];
			}
		}
	}
	random_ = b;
	reverse = rev;
}

- (void) setContents:(NSArray *)ary random:(BOOL)b {
	[self setContents:ary random:b reverse:NO];
}

- (void) setPage:(int)p {
	loadedPage_ = p;
}

- (void) setMaxPage:(int)p {
	maxPage_ = p;
}

#pragma mark-

- (void) playAction {
	if ([self paused]) {
		[self resume];
	} else {
		[self pause];
	}
}

- (void) nextAction {
	[self next];
}

- (void) prevAction {
	[self prev];
}

#pragma mark-

- (void) start {
	if (started_) {
		return;
	}
	
	[slideTimer_ invalidate];
	slideTimer_ = nil;
	slideTimer_ = [NSTimer scheduledTimerWithTimeInterval:0.0 target:self selector:@selector(slideTimer:) userInfo:nil repeats:NO];
	started_ = YES;
}

- (void) stop {
	[slideTimer_ invalidate];
	slideTimer_ = nil;
	[reloadTimer_ invalidate];
	reloadTimer_ = nil;
	started_ = NO;
	//[illustIDs_ removeAllObjects];
}

- (void) pause {
	[slideTimer_ invalidate];
	slideTimer_ = nil;
	paused_ = YES;

	[self updateDisplay];
}

- (void) resume {
	paused_ = NO;
	[slideTimer_ invalidate];
	slideTimer_ = nil;
	slideTimer_ = [NSTimer scheduledTimerWithTimeInterval:0.0 target:self selector:@selector(slideTimer:) userInfo:nil repeats:NO];

	[self updateDisplay];
}

- (void) setCurrentIndex:(int)idx {	
}

- (void) next {
	displayIllistIndex_ = [self currentImageIndex] + 1;
	[slideTimer_ invalidate];
	slideTimer_ = [NSTimer scheduledTimerWithTimeInterval:0.0 target:self selector:@selector(slideTimer:) userInfo:nil repeats:NO];

	[self updateDisplay];
}

- (void) prev {
	displayIllistIndex_ = [self currentImageIndex] - 1;
	[slideTimer_ invalidate];
	slideTimer_ = [NSTimer scheduledTimerWithTimeInterval:0.0 target:self selector:@selector(slideTimer:) userInfo:nil repeats:NO];

	[self updateDisplay];
}

- (BOOL) paused {
	return paused_;
}

- (IBAction) goMedium {
	if ([currentInfo_ objectForKey:@"IllustID"]) {
		PixivMediumViewController *controller = [self mediumViewController];
		controller.illustID = [currentInfo_ objectForKey:@"IllustID"];
		if ([controller respondsToSelector:@selector(setInfo:)]) {
			[controller performSelector:@selector(setInfo:) withObject:currentInfo_];
		}
		[self.navigationController pushViewController:controller animated:YES];
	}
}

- (void) action:(id)sender {	
	if (actionSheet_) [actionSheet_ dismissWithClickedButtonIndex:[actionSheet_ cancelButtonIndex] animated:NO];

	UIActionSheet	*alert = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Go to this illust", nil), nil];
	if (([[UIDevice currentDevice] respondsToSelector:@selector(userInterfaceIdiom)] ? [[UIDevice currentDevice] userInterfaceIdiom] : 0) != 0) {
		[alert showFromBarButtonItem:sender animated:YES];
	} else {
		[alert showFromToolbar:self.navigationController.toolbar];
	}
	actionSheet_ = alert;
	[alert release];
}

- (void)actionSheet:(UIActionSheet *)sheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	actionSheet_ = nil;
	
	switch (buttonIndex) {
	case 0:
		[self goMedium];
		break;
	default:
		break;
	}
}

#pragma mark-

-(void) performTransition {
	// First create a CATransition object to describe the transition
	CATransition *transition = [CATransition animation];
	// Animate over 3/4 of a second
	transition.duration = 0.75;
	// using the ease in/out timing function
	transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
	
	transition.type = kCATransitionFade;
	
	// Finally, to avoid overlapping transitions we assign ourselves as the delegate for the animation and wait for the
	// -animationDidStop:finished: message. When it comes in, we will flag that we are no longer transitioning.
	transitioning = YES;
	transition.delegate = self;
	
	// Next add it to the containerView's layer. This will perform the transition based on how we change its contents.
	[self.view.layer addAnimation:transition forKey:nil];
	
	// Here we hide view1, and show view2, which will cause Core Animation to animate view1 away and view2 in.
	imageView1_.hidden = YES;
	imageView2_.hidden = NO;
	
	// And so that we will continue to swap between our two images, we swap the instance variables referencing them.
	UIImageView *tmp = imageView2_;
	imageView2_ = imageView1_;
	imageView1_ = tmp;
}

-(void)animationDidStop:(CAAnimation *)theAnimation finished:(BOOL)flag {
	transitioning = NO;
}

- (void) setImage:(UIImage *)img {
	if ([self.view viewWithTag:100]) {
		[[self.view viewWithTag:100] removeFromSuperview];

		//[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
		[self setStatusBarHidden:YES animated:YES];
		[self.navigationController setNavigationBarHidden:YES animated:YES];
		[self.navigationController setToolbarHidden:YES animated:YES];
	}
	
	imageView2_.image = img;
	[self performTransition];
}

- (void) setInfo:(NSDictionary *)info {
	if (currentInfo_[@"Player"]) {
		PixivUgoIllustPlayer *player = currentInfo_[@"Player"];
		[player stop];
		player.delegate = nil;
	}
	
	[currentInfo_ release];
	currentInfo_ = [info retain];

	[self updateDisplay];
}

- (void) storage:(SlideshowImageStorage *)sender loadIllust:(NSDictionary *)info finished:(long)err {
	DLog(@"storage loadfinished");
	
	BOOL	skip = YES;
	if (err == 0 && ([info objectForKey:@"Image"] || [info objectForKey:@"Player"])) {
		if ([info objectForKey:@"Player"]) {
			PixivUgoIllustPlayer *player = info[@"Player"];
			[self setImage:player.ugoIllust.firstImage];
			player.delegate = (id<PixivUgoIllustPlayerDelegate>)self;
			[player play];
		} else {
			[self setImage:[info objectForKey:@"Image"]];
			
		}
		[self setInfo:info];
		skip = NO;
	}

	if (![self paused] || skip) {
		//if (displayIllistIndex_ == [self currentImageIndex]) {
		displayIllistIndex_++;	
		//}
		if (loadingMatrix_ == NO && displayIllistIndex_ >= [illustIDs_ count]) {
			DLog(@"reload next: %@", @(displayIllistIndex_));
		
			// 越えた
			if (reverse) {
				loadedPage_ = 0;
				[self reload];
			} else {
				if (loadedPage_ < maxPage_) {
					loadedPage_++;
					[self reload];
				} else {
					displayIllistIndex_ = 0;
				}
			}
		}

		[slideTimer_ invalidate];
		slideTimer_ = nil;
		slideTimer_ = [NSTimer scheduledTimerWithTimeInterval:skip ? 0 : [self slideInterval] target:self selector:@selector(slideTimer:) userInfo:nil repeats:NO];
	}
}

- (NSInteger) currentImageIndex {
	if (currentInfo_) {
		return [illustIDs_ indexOfObject:[currentInfo_ objectForKey:@"IllustID"]];
	} else {
		return -1;
	}
}

#define IMAGE_CACHE_SIZE	(7)

- (NSRange) loadToCache:(NSRange)range {
	NSRange	ret = {0, 0};
	if (range.location < [illustIDs_ count]) {
		// load
		NSMutableArray	*ary = [NSMutableArray array];
		NSInteger				i;
		
		ret = range;
		if ([illustIDs_ count] < ret.location + ret.length) {
			ret.length = [illustIDs_ count] - ret.location;
		}
		
		if (ret.length == 0) {
			ret.location = 0;
			return ret;
		}
		
		for (i = ret.location; i < ret.location + ret.length; i++) {
			[ary addObject:[illustIDs_ objectAtIndex:i]];
		}
		
		[storage_ setLoadIllusts:ary];
	}
	return ret;
}

- (void) setImageIndex:(NSInteger)index {
	DLog(@"setImageIndex: %@", @(index));
	if ((!loadingMatrix_ && index < [illustIDs_ count]) || (loadingMatrix_ && index + IMAGE_CACHE_SIZE / 2 < [illustIDs_ count])) {
		NSRange			range;
		
		DLog(@"setImageIndex u");
		
		range.location = (index - IMAGE_CACHE_SIZE / 2 < 0 ? 0 : index - IMAGE_CACHE_SIZE / 2);
		range.length = IMAGE_CACHE_SIZE;
		if (range.location <= [illustIDs_ count] && [illustIDs_ count] < range.location + range.length) {
			range.length = [illustIDs_ count] - range.location;
		}

		[self loadToCache:range];
		[storage_ getIllust:[illustIDs_ objectAtIndex:index]];
		
		needsLoadIllustIndexRange_.location = 0;
		needsLoadIllustIndexRange_.length = 0;
		needsLoadIllustIndex_ = -1;
	} else if (loadingMatrix_) {
		DLog(@"setImageIndex d");

		needsLoadIllustIndexRange_.location = (index - IMAGE_CACHE_SIZE / 2 < 0 ? 0 : index - IMAGE_CACHE_SIZE / 2);
		needsLoadIllustIndexRange_.length = IMAGE_CACHE_SIZE;
		needsLoadIllustIndex_ = index;
	}
}

- (void) slideTimer:(NSTimer *)timer {
	DLog(@"slideTimer");
	
	slideTimer_ = nil;
	if (displayIllistIndex_ >= [illustIDs_ count]) {
		if (matrixConnection_) {
			slideTimer_ = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(slideTimer:) userInfo:nil repeats:NO];
		} else {
			[self reload];
		}
		return;
	}

	DLog(@"slideTimer: %@ / %@ (%@)", @(displayIllistIndex_), @([self currentImageIndex]), [illustIDs_ objectAtIndex:displayIllistIndex_]);

	if (displayIllistIndex_ != [self currentImageIndex]) {
		[self setImageIndex:displayIllistIndex_];
	} else {
		if (![self paused]) {
			displayIllistIndex_++;
			slideTimer_ = [NSTimer scheduledTimerWithTimeInterval:[self slideInterval] target:self selector:@selector(slideTimer:) userInfo:nil repeats:NO];
		}
	}
}

#pragma mark-

- (NSDictionary *) contentAtIndex:(int)idx inArray:(NSArray *)ary {
	for (NSDictionary *info in ary) {
		if ([[info objectForKey:@"Index"] intValue] == idx) {
			return info;
		}
	}
	return NO;
}

#pragma mark-

- (void) matrixParser:(MatrixParser *)parser foundPicture:(NSDictionary *)pic {
	if (illustIDsTmp_ == nil) {
		illustIDsTmp_ = [[NSMutableArray alloc] init];
	}
	[illustIDsTmp_ addObject:[pic objectForKey:@"IllustID"]];
	//[illustIDs_ addObject:[pic objectForKey:@"IllustID"]];
	
	if ([pic objectForKey:@"MediumURLString"]) {
		[[self pixiv] addEntries:pic forIllustID:[pic objectForKey:@"IllustID"]];
	}
}

- (void) matrixParser:(MatrixParser *)parser finished:(long)err {
	[self setContents:illustIDsTmp_ random:random_ reverse:reverse];
	[illustIDsTmp_ removeAllObjects];
	
	DLog(@"matrixParser finished: %@", [illustIDs_ description]);

	if (needsLoadIllustIndex_ >= 0 && needsLoadIllustIndexRange_.location + needsLoadIllustIndexRange_.length < [illustIDs_ count]) {
		// load
		NSMutableArray	*ary = [NSMutableArray array];
		NSInteger				i;
		
		for (i = needsLoadIllustIndexRange_.location; i < needsLoadIllustIndexRange_.location + needsLoadIllustIndexRange_.length; i++) {
			[ary addObject:[illustIDs_ objectAtIndex:i]];
		}
		
		[storage_ setLoadIllusts:ary];
		[storage_ getIllust:[illustIDs_ objectAtIndex:needsLoadIllustIndex_]];
		needsLoadIllustIndex_ = -1;
		needsLoadIllustIndexRange_.location = 0;
		needsLoadIllustIndexRange_.length = 0;
	}

	pictureIsFound_ = YES;
}

- (void) connection:(CHHtmlParserConnection *)con finished:(long)err {
	DLog(@"connection finished");
	if (con == matrixConnection_) {
		maxPage_ = matrixParser_.maxPage;
			
		if ([self class] == [PixivSlideshowViewController class] && [self.method hasPrefix:@"ranking"]) {
			maxPage_ = 6;
		}

		[matrixParser_ release];
		matrixParser_ = nil;

		[matrixConnection_ release];
		matrixConnection_ = nil;

		loadingMatrix_ = NO;

		//[self setImageIndex:displayIllistIndex_];
		//DLog(@"displayIllistIndex_ = %d", displayIllistIndex_);
		DLog(@"needsLoadIllustIndex_ = %@", @(needsLoadIllustIndex_));
		if (needsLoadIllustIndex_ >= 0 && needsLoadIllustIndex_ < [illustIDs_ count]) {				
			DLog(@"reload finished to load");

			[self loadToCache:needsLoadIllustIndexRange_];
			[storage_ getIllust:[illustIDs_ objectAtIndex:needsLoadIllustIndex_]];

			needsLoadIllustIndex_ = -1;
			needsLoadIllustIndexRange_.location = 0;
			needsLoadIllustIndexRange_.length = 0;
		} else if (!slideTimer_ && !reloadTimer_) {
			DLog(@"reload finished to reload timer");

			//reloadTimer_ = [NSTimer scheduledTimerWithTimeInterval:[self slideInterval] target:self selector:@selector(reload) userInfo:nil repeats:NO];
			slideTimer_ = [NSTimer scheduledTimerWithTimeInterval:[self slideInterval] target:self selector:@selector(slideTimer:) userInfo:nil repeats:NO];
		}
	}
}

#pragma mark-

- (void) reload {
	long	err = [[self pixiv] allertReachability];
	if (err) {
		reloadTimer_ = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(reload) userInfo:nil repeats:NO];
		return;
	} else {
		reloadTimer_ = nil;
	}
	
	DLog(@"reload");

	[matrixConnection_ cancel];
	[matrixConnection_ release];
	matrixConnection_ = nil;
	
	MatrixParser		*parser = [self matrixParser];
	CHHtmlParserConnection	*con;
	
	pictureIsFound_ = NO;
	parser.delegate = self;
	con = [[CHHtmlParserConnection alloc] initWithURL:[NSURL URLWithString:[self matrixURL]]];
	
	con.referer = [self referer];
	DLog(@"slide reload before: %@", @([self retainCount]));
	con.delegate = self;
	DLog(@"slide reload after: %@", @([self retainCount]));
	matrixParser_ = [parser retain];
	matrixConnection_ = con;
	
	loadingMatrix_ = YES;
	[con startWithParser:parser];
	DLog(@"slide reload started: %@", @([self retainCount]));
}

- (void) reflesh {
	loadedPage_ = 0;
	//lastDisplayTime_ = 0;

	//pthread_mutex_lock(&imageCacheMutex_);
	displayIllistIndex_ = 0;
	//pthread_mutex_unlock(&imageCacheMutex_);
	
	//pthread_mutex_lock(&illustIDsMutex_);
	[illustIDs_ removeAllObjects];
	//pthread_mutex_unlock(&illustIDsMutex_);
	
	[self reload];
}

- (NSString *) nextIID:(NSString *)iid {
	NSInteger	idx = [illustIDs_ indexOfObject:iid];
	if (0 <= idx && idx < [illustIDs_ count]) {
		idx++;
		if (0 <= idx && idx < [illustIDs_ count]) {
			return [illustIDs_ objectAtIndex:idx];
		} else {
			return nil;
		}
	} else {
		return nil;
	}
}

- (NSString *) prevIID:(NSString *)iid {
	NSInteger	idx = [illustIDs_ indexOfObject:iid];
	if (0 <= idx && idx < [illustIDs_ count]) {
		idx--;
		if (0 <= idx && idx < [illustIDs_ count]) {
			return [illustIDs_ objectAtIndex:idx];
		} else {
			return nil;
		}
	} else {
		return nil;
	}
}

#pragma mark-

/*
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
*/

#pragma mark-

- (NSMutableDictionary *) storeInfo {
	NSMutableDictionary *info = [super storeInfo];
	
	[info setObject:[account info] forKey:@"Account"];
	[info setObject:method forKey:@"Method"];

	return info;
}

- (BOOL) needsStore {
	return NO;
}

- (BOOL) restore:(NSDictionary *)info {
	id obj;
	
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

	return YES;
}

- (void) frameChanged:(id)sender image:(UIImage *)image {
	imageView1_.image = image;
}

- (BOOL) prefersStatusBarHidden {
	return self.navigationController.navigationBarHidden;
}

@end


static void CGContextFillStrokeRoundedRect( CGContextRef context, CGRect rect, CGFloat radius ) {
	CGContextMoveToPoint( context, CGRectGetMinX( rect ), CGRectGetMidY( rect ));
	CGContextAddArcToPoint( context, CGRectGetMinX( rect ), CGRectGetMinY( rect ), CGRectGetMidX( rect ), CGRectGetMinY( rect ), radius );
	CGContextAddArcToPoint( context, CGRectGetMaxX( rect ), CGRectGetMinY( rect ), CGRectGetMaxX( rect ), CGRectGetMidY( rect ), radius );
	CGContextAddArcToPoint( context, CGRectGetMaxX( rect ), CGRectGetMaxY( rect ), CGRectGetMidX( rect ), CGRectGetMaxY( rect ), radius );
	CGContextAddArcToPoint( context, CGRectGetMinX( rect ), CGRectGetMaxY( rect ), CGRectGetMinX( rect ), CGRectGetMidY( rect ), radius );
	CGContextSetLineWidth( context, 2 );
	CGContextClosePath( context );
	CGContextDrawPath( context, kCGPathFillStroke );
	//CGContextFillPath(context);
}


@implementation ClockView

@synthesize dateLabel, timeLabel;

- (void) update {
	NSDate *now = [NSDate date];
	dateLabel.text = [dateFormatter_ stringFromDate:now];
	timeLabel.text = [timeFormatter_ stringFromDate:now];
}

- (void) startTimer {
	[self update];
	timer_ = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(update) userInfo:nil repeats:YES];
}

- (void) stopTimer {
	[timer_ invalidate];
	timer_ = nil;
}

- (void) dealloc {
	[self stopTimer];
	[dateLabel release];
	[timeLabel release];
	[super dealloc];
}

- (void)viewDidLoad {	
	if (!dateFormatter_) {
		dateFormatter_ = [[NSDateFormatter alloc] init];
		[dateFormatter_ setDateFormat:@"yyyy/MM/dd"];
	}
	if (!timeFormatter_) {
		timeFormatter_ = [[NSDateFormatter alloc] init];
		[timeFormatter_ setDateFormat:@"HH:mm"];
	}
	[self startTimer];
}

- (void)viewDidUnload {
	[self stopTimer];
	self.dateLabel = nil;
	self.timeLabel = nil;
}

- (void) drawRect:(CGRect)rect {
	//UIImage *img = [UIImage imageNamed:@"clock_bg.png"];
	//[img drawAtPoint:CGPointZero];
	CGRect r;
	r.origin.x = 1;
	r.origin.y = 1;
	r.size.width = rect.size.width - 2;
	r.size.height = rect.size.height - 2;
	
	[[[UIColor blackColor] colorWithAlphaComponent:0.5] setFill];
	[[[UIColor whiteColor] colorWithAlphaComponent:0.5] setStroke];
	CGContextFillStrokeRoundedRect(UIGraphicsGetCurrentContext(), r, 10);
}

@end
