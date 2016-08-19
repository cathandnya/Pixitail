//
//  PixivMangaPageViewController.m
//  pixiViewer
//
//  Created by nya on 10/05/16.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "PixivMangaPageViewController.h"
#import "ImageDiskCache.h"
#import "SharedAlertView.h"
#import "UIImage+animatedGIF.h"
#import "NSData+GIF.h"


#define ZOOM_VIEW_TAG 200
#define ZOOM_STEP 1.5
#define ZOOM_MAX 3.0


@implementation PixivMangaPageViewController

@synthesize delegate;
@synthesize urlString, illustID;
@dynamic image;

- (void)dealloc {
	[self loadImageCancel];
	[scrollView release];
	scrollView = nil;
	[imageView release];
	imageView = nil;
	
	[urlString release];
	[illustID release];

    [super dealloc];
}

#pragma mark-

- (void) viewDidLoad {
	[super viewDidLoad];
	self.view.backgroundColor = [UIColor blackColor];
	self.view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
	
	CGRect r = self.view.frame;
	r.origin = CGPointZero;
	scrollView = [[UIScrollView alloc] initWithFrame:r];
	scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
	scrollView.backgroundColor = [UIColor clearColor];
	scrollView.bounces = YES;
	scrollView.delegate = self;
	scrollView.multipleTouchEnabled = YES;
	scrollView.minimumZoomScale = 1;
	scrollView.maximumZoomScale = 2;
	[self.view addSubview:scrollView];
	
	imageView = [[UIImageView alloc] initWithFrame:r];
	imageView.contentMode = UIViewContentModeScaleAspectFit;
	imageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
	[scrollView addSubview:imageView];
	
	imageView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.1];
	
	UITapGestureRecognizer *tgr = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapAction:)] autorelease];
	tgr.numberOfTapsRequired = 2;
	[scrollView addGestureRecognizer:tgr];
	UITapGestureRecognizer *gr = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(buttonAction)] autorelease];
	[gr requireGestureRecognizerToFail:tgr];
	[scrollView addGestureRecognizer:gr];
}

- (void) viewDidUnload {
	[super viewDidUnload];
	
	[self loadImageCancel];
	[scrollView release];
	scrollView = nil;
	[imageView release];
	imageView = nil;
}

#pragma mark-

- (void) loadImage {
	if (imageConnection) {
		return;
	}
	
	if ([self.view viewWithTag:100] == nil) {
		UIProgressView *progress = [[[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault] autorelease];
		progress.tag = 100;
		CGRect r = progress.frame;
		r.size.width = 3 * self.view.frame.size.width / 4;
		r.origin.x = (self.view.frame.size.width - r.size.width) / 2;
		r.origin.y = (self.view.frame.size.height - r.size.height) / 2;
		progress.frame = r;
		[self.view addSubview:progress];
	}
	
	assert(urlString);
	NSMutableURLRequest			*req = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
	assert(imageConnection == nil);
	if ([self.delegate referer]) [req setValue:[self.delegate referer] forHTTPHeaderField:@"Referer"];
	imageConnection = [[NSURLConnection alloc] initWithRequest:req delegate:self];
	imageData = [[NSMutableData alloc] init];
	[req release];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorStartNotification" object:nil];
	[imageConnection start];
}

- (void) loadImageCancel {
	if (imageConnection) {
		[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:nil];
		[imageConnection cancel];
		[imageConnection release];
		imageConnection = nil;
	}
}

- (void) load {
	UIImage *img = imageView.image;
	if (img == nil) {
		img = [[self.delegate cache] imageForKey:self.illustID];
	}
	if (img == nil) {
		[self loadImage];
	} else {
		[self setImage:img];
	}
}

- (void) clear {
	imageView.image = nil;
	scrollView.zoomScale = 1;
}

#pragma mark-

- (UIScrollView *) scrollView {
	return scrollView;
}

- (void) updateDisplay {
}

- (void) setImage:(UIImage *)img {
	CGSize imgSize = img.size;
	//CGRect imageRect = maxCenter(imgSize, self.scrollView.frame);
	imageView.image = img;
	self.scrollView.zoomScale = 1.0;
	
	DLog(@"image size: %@", NSStringFromCGSize(imgSize));
	if (imgSize.width * 4 < imgSize.height) {
		// マッチ棒
		initialScale = 1;
		scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width, self.scrollView.frame.size.width * imgSize.height / imgSize.width);
		fitScale = imgSize.height / self.scrollView.contentSize.height;
	} else {
		scrollView.contentSize = scrollView.frame.size;
		if (imgSize.height / imgSize.width < self.scrollView.frame.size.height / self.scrollView.frame.size.width){
			// 幅木順
			initialScale = 1.0;
			fitScale = imgSize.width / self.scrollView.frame.size.width;
		} else {
			// 高崎淳
			initialScale = 1.0;
			fitScale = imgSize.height / self.scrollView.frame.size.height;
		}
	}
	DLog(@"fit size: %@", NSStringFromCGSize(CGSizeMake(self.scrollView.frame.size.width * fitScale, self.scrollView.frame.size.height * fitScale)));
	
	imageView.frame = CGRectMake(0, 0, scrollView.contentSize.width, scrollView.contentSize.height);
	self.scrollView.minimumZoomScale = MIN(fitScale, 1);
	self.scrollView.maximumZoomScale = MAX(fitScale, 2);
	self.scrollView.zoomScale = initialScale;

	imageView.image = img;
}

- (UIImage *) image {
	return imageView.image;
}

- (void) loaded:(NSData *)data {
	[imageConnection release];
	imageConnection = nil;

	if (![self scrollView]) {
		return;
	}

	UIImage	*img = [data isGIF] ? [UIImage animatedImageWithAnimatedGIFData:data] : [UIImage imageWithData:data];

	[[self.view viewWithTag:100] removeFromSuperview];
	[self scrollView].alpha = 1.0;
	if (img) {
		// cache
		[[self.delegate cache] setImageData:data forKey:self.illustID];
		[self setImage:img];
		
		[delegate loadImageFinished:self];
	} else {
		// 読めなかった
		[[SharedAlertView sharedInstance] showWithTitle:NSLocalizedString(@"Image load failed.", nil) message:@"" cancelButtonTitle:nil okButtonTitle:@"OK"];
	}
	
	[imageData release];
	imageData = nil;

	[self updateDisplay];
}

#pragma mark-

- (void) connection:(NSURLConnection *)con didReceiveResponse:(NSURLResponse *)response {
	imageSize = [response expectedContentLength];
}

- (void) connection:(NSURLConnection *)con didReceiveData:(NSData *)data {
	[imageData appendData:data];

	UIProgressView	*view = (UIProgressView *)[self.view viewWithTag:100];
	if (view) {
		view.progress = (double)[imageData length] / (double)imageSize;
	}
}

- (void) connection:(NSURLConnection *)con didFailWithError:(NSError *)error {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:nil];
	[self loaded:nil];
}

- (void) connectionDidFinishLoading:(NSURLConnection *)con {
	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:nil];
	[self loaded:imageData];
}

#pragma mark-

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

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)aView {
    return imageView;
}

/************************************** NOTE **************************************/
/* The following delegate method works around a known bug in zoomToRect:animated: */
/* In the next release after 3.0 this workaround will no longer be necessary      */
/**********************************************************************************/
- (void)scrollViewDidEndZooming:(UIScrollView *)aView withView:(UIView *)view atScale:(CGFloat)scale {
    [scrollView setZoomScale:scale+0.01 animated:NO];
    [scrollView setZoomScale:scale animated:NO];
}

#pragma mark TapDetectingImageViewDelegate methods

- (void) doubleTapAction:(UITapGestureRecognizer *)sender {
	CGPoint tapPoint = [sender locationInView:scrollView];
    float newScale = 2;
	if (scrollView.zoomScale == 1.0) {
		newScale = 2;
	} else {
		newScale = 1;
	}
    CGRect zoomRect = [self zoomRectForScale:newScale withCenter:tapPoint];
    [[self scrollView] zoomToRect:zoomRect animated:YES];
}

- (void) buttonAction {
	[delegate singleTapAtPoint:CGPointZero];
}

@end
