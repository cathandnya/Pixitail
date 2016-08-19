//
//  PixivMangaViewController.m
//  pixiViewer
//
//  Created by nya on 09/09/18.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "PixivMangaViewController.h"
#import "PixivMangaParser.h"
#import "Pixiv.h"
#import "ImageDiskCache.h"

#import "UserDefaults.h"
#import "DropBoxTail.h"
#import "EvernoteTail.h"
#import "PixivMatrixViewController.h"
#import "PixivMediumViewController.h"
#import "PixivBigViewController.h"
#import "PixiViewerAppDelegate.h"
#import "AlwaysSplitViewController.h"
#import "SharedAlertView.h"
#import "CameraRoll.h"
#import "SkyDrive.h"
#import "SugarSync.h"
#import "GoogleDrive.h"
#import "TumblrAccountManager.h"
#import "PixitailConstants.h"


#define MARGIN		(10)


@implementation PixivMangaViewController

@synthesize illustID;

- (PixService *) pixiv {
	return [Pixiv sharedInstance];
}

- (ImageCache *) cache {
	return [ImageCache pixivBigCache];
}

- (NSString *) referer {
	return @"http://www.pixiv.net/";
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
	return nil;
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

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
}
*/

/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}
*/

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
	int i = 0;
	for (PixivMangaPageViewController *vc in viewControllers_) {
		if (curPage_ != i) {
			[vc clear];
		}
		i++;
	}
}

- (UIBarButtonItem *) saveButton {
	return (UIBarButtonItem *)[self.toolbarItems objectAtIndex:2];
}

- (NSString *) nextIID {
	return [[self parentMedium] nextIID];
}

- (NSString *) prevIID {
	return [[self parentMedium] prevIID];
}

- (void) updateSegment {
	/*
	UISegmentedControl *seg = (UISegmentedControl *)self.navigationItem.rightBarButtonItem.customView;
	if (progressShowing_) {
		[seg setEnabled:NO forSegmentAtIndex:0];
		[seg setEnabled:NO forSegmentAtIndex:1];
	} else {
		[seg setEnabled:[self prevIID] != nil forSegmentAtIndex:0];
		[seg setEnabled:[self nextIID] != nil forSegmentAtIndex:1];
	}
	 */
}

- (void) updateDisplay {
	BOOL	loading = NO;//[self.view viewWithTag:100] ? YES : NO;
	{
		NSMutableArray	*tmp = [NSMutableArray array];
		UIBarButtonItem	*item;
		
		item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRewind target:self action:@selector(prev)];
		[tmp addObject:item];
		[item setEnabled:!loading && 0 < curPage_];
		[item release];

		item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
		[tmp addObject:item];
		[item release];

		item = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"save.png"] style:UIBarButtonItemStylePlain target:self action:@selector(saveAction:)];
		item.enabled = (((PixivMangaPageViewController *)[viewControllers_ objectAtIndex:curPage_]).image != nil);
		[tmp addObject:item];
		[item release];	
		
		item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
		[tmp addObject:item];
		[item release];
		
		if (curPage_ + 1 < [urlStrings_ count]) {
			item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFastForward target:self action:@selector(next)];
		} else {
			item = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"replay.png"] style:UIBarButtonItemStylePlain target:self action:@selector(next)];
		}
		[tmp addObject:item];
		[item setEnabled:!loading && [urlStrings_ count] > 1];
		[item release];
		
		[self setToolbarItems:tmp animated:NO];
		//[self.navigationController.toolbar setItems:tmp animated:NO];
	}
	
	UILabel *label = (UILabel *)self.navigationItem.titleView;
	if ([urlStrings_ count] > 0) {
		label.text = [NSString stringWithFormat:@"%d / %@", curPage_ + 1, @([urlStrings_ count])];
	} else {
		label.text = @"";
	}

	//self.navigationItem.rightBarButtonItem.enabled = (((PixivMangaPageViewController *)[viewControllers_ objectAtIndex:curPage_]).image != nil);
	//[super updateDisplay];
	
	[self updateSegment];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	if ([self respondsToSelector:@selector(setEdgesForExtendedLayout:)]) {
		self.edgesForExtendedLayout = UIRectEdgeAll;
		self.automaticallyAdjustsScrollViewInsets = NO;
	}
	if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
		[self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
	}
	self.wantsFullScreenLayout = YES;
	self.view.backgroundColor = [UIColor blackColor];
	
	CGRect r = self.view.frame;
	r.origin = CGPointZero;
	r.origin.x -= MARGIN / 2;
	r.size.width += MARGIN;
	scrollView = [[UIScrollView alloc] initWithFrame:r];
	scrollView.pagingEnabled = YES;
	scrollView.delegate = self;
	scrollView.backgroundColor = [UIColor blackColor];
	scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
	scrollView.showsHorizontalScrollIndicator = NO;
	scrollView.showsVerticalScrollIndicator = NO;
	[self.view addSubview:scrollView];
	
	curPage_ = 0;	
	[self reload];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mediumUpdated:) name:@"MediumViewControllerLoadedNotification" object:[self parentMedium]];
}

- (void)viewDidUnload {
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
	[super viewDidUnload];
	
	[connection_ cancel];
	[connection_ release];
	connection_ = nil;
	[parser_ release];
	parser_ = nil;
	
	for (PixivMangaPageViewController *vc in viewControllers_) {
		[vc loadImageCancel];
	}
	[scrollView release];
	scrollView = nil;
}

- (void) setupToolbar {
}

- (void) viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];

	/*
	if ([urlStrings_ count] > 0) {
		[self setStatusBarHidden:YES animated:YES];
		[self.navigationController setNavigationBarHidden:YES animated:YES];
		[self.navigationController setToolbarHidden:YES animated:YES];
	}
	*/

	UILabel *label = [[[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 40)] autorelease];
	label.textAlignment = UITextAlignmentCenter;
	if ([urlStrings_ count] > 0) {
		label.text = [NSString stringWithFormat:@"%d / %@", curPage_ + 1, @([urlStrings_ count])];
	} else {
		label.text = @"";
	}
	label.backgroundColor = [UIColor clearColor];
	label.textColor = [UIColor whiteColor];
	self.navigationItem.titleView = label;
	
	/*
	UISegmentedControl *seg = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:[UIImage imageNamed:@"up.png"], [UIImage imageNamed:@"down.png"], nil]];
	seg.segmentedControlStyle = UISegmentedControlStyleBar;
	//seg.tintColor = [UIColor grayColor];
	seg.momentary = YES;
	[seg addTarget:self action:@selector(segmentAction:) forControlEvents:UIControlEventValueChanged];
	UIBarButtonItem	*item = [[UIBarButtonItem alloc] initWithCustomView:seg];
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:seg] autorelease];
	[seg release];
	[item release];
	 */
}

- (void)viewDidAppear:(BOOL)animated {	
	[super viewDidAppear:animated];
	
	//[self.navigationController setToolbarHidden:NO animated:YES];
	[self updateDisplay];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];

	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		[self.navigationController setNavigationBarHidden:YES animated:YES];
		[self.navigationController setToolbarHidden:YES animated:YES];
	}
}

- (UIStatusBarStyle) preferredStatusBarStyle {
	return UIStatusBarStyleLightContent;
}

- (BOOL) prefersStatusBarHidden {
	return self.navigationController.navigationBarHidden;
	
}

- (void)viewWillLayoutSubviews {
	CGRect r;
	r.origin = CGPointZero;
	r.size = scrollView.frame.size;
	r.origin.x += MARGIN / 2;
	r.size.width -= MARGIN;
	for (UIViewController *vc in viewControllers_) {
		vc.view.frame = r;
		r.origin.x += scrollView.frame.size.width;
	}
}

- (void) willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
	scrollView.delegate = nil;
    CGFloat pageWidth = self.scrollView.frame.size.width;
    curPage_ = floor((self.scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
	scrollView.hidden = YES;
}

- (void) didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	[self setURLs:urlStrings_];
	scrollView.hidden = NO;
	scrollView.delegate = self;
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[connection_ cancel];
	[connection_ release];
	connection_ = nil;
	[parser_ release];
	parser_ = nil;
	
	for (PixivMangaPageViewController *vc in viewControllers_) {
		[vc loadImageCancel];
	}
	[scrollView release];
	scrollView = nil;

	
	self.illustID = nil;
	[urlStrings_ release];
	urlStrings_ = nil;
	[viewControllers_ release];
	viewControllers_ = nil;

    [super dealloc];
}

- (PixivMangaParser *) mangaParser {
	return (PixivMangaParser *)parser_;
}

- (UIScrollView *) scrollView {
	return scrollView;
}

- (long) reload {
	if ([urlStrings_ count] > 0) {
		return 0;
	}

	long	err = [[self pixiv] allertReachability];
	if (err) {
		return err;
	}
	
	NSDictionary	*info = [[self pixiv] infoForIllustID:self.illustID];
	NSArray *urls = [info objectForKey:@"Images"];	
	id	num = [info objectForKey:@"MangaPageCount"];
	NSString *urlBase = [info objectForKey:@"MediumURLString"];
	if ([urls count] > 0) {	
		NSMutableArray *ary = [NSMutableArray array];
		for (NSDictionary *i in urls) {
			[ary addObject:[i objectForKey:@"URLString"]];
		}
		[self performSelector:@selector(setURLs:) withObject:ary afterDelay:0.2];
		return 0;
	} else if (num && urlBase) {
		/*
		NSArray *srcList = [[PixitailConstants sharedInstance] valueForKeyPath:@"constants.manga_replacement_src"];
		NSArray *dstList = [[PixitailConstants sharedInstance] valueForKeyPath:@"constants.manga_replacement_dst"];
		if (srcList.count == dstList.count) {
			for (NSInteger i = 0; i < srcList.count; i++) {
				NSString *src = srcList[i];
				NSString *dst = dstList[i];
				urlBase = [urlBase stringByReplacingOccurrencesOfString:src withString:dst];
			}
			
			int count = [num intValue];
			NSMutableArray *ary = [NSMutableArray array];
			for (NSInteger i = 0; i < count; i++) {
				NSString *url = [NSString stringWithFormat:urlBase, @(i)];
				DLog(@"%@", url);
				[ary addObject:url];
			}
			[self performSelector:@selector(setURLs:) withObject:ary afterDelay:0.2];
			return 0;
		}
		 */
		
		/*
		int count = [num intValue];
		NSString *ext = [urlBase pathExtension];
		NSString *base = [urlBase stringByDeletingPathExtension];
		base = [base substringToIndex:base.length - 2];
		
		NSMutableArray *ary = [NSMutableArray array];
		for (int i = 0; i < count; i++) {
			DLog(@"%@", [base stringByAppendingString:[[NSString stringWithFormat:@"_big_p%d", i] stringByAppendingPathExtension:ext]]);
			[ary addObject:[base stringByAppendingString:[[NSString stringWithFormat:@"_big_p%d", i] stringByAppendingPathExtension:ext]]];
		}
		
		//[self setURLs:ary];
		[self performSelector:@selector(setURLs:) withObject:ary afterDelay:0.2];
		 */
	}
/*
	if ([self.view viewWithTag:1234] == nil) {
		UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
		CGRect r = activity.frame;
		r.origin.x = (self.view.frame.size.width - r.size.width) / 2.0;
		r.origin.y = (390 - r.size.height) / 2.0;
		activity.frame = r;
		activity.tag = 1234;
		activity.hidesWhenStopped = YES;
		[self.view addSubview:activity];
		if (r.origin.x > 0) {
			[activity startAnimating];
		} else {
			[activity stopAnimating];
		}
		[activity release];
	}

	{
		PixivMangaParser		*parser = [[PixivMangaParser alloc] initWithEncoding:NSUTF8StringEncoding];
		CHHtmlParserConnection	*con = [[CHHtmlParserConnection alloc] initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://www.pixiv.net/member_illust.php?mode=manga&illust_id=%@", self.illustID]]];
		
		//con.referer = @"http://www.pixiv.net/";
		con.referer = [NSString stringWithFormat:@"http://www.pixiv.net/member_illust.php?mode=manga&illust_id=%@&p=0", self.illustID];
		con.delegate = self;
		parser_ = parser;
		connection_ = con;
	
		[con startWithParser:parser];
	}
*/
	[[SharedAlertView sharedInstance] showWithTitle:NSLocalizedString(@"Image load failed.", nil) message:@"" cancelButtonTitle:nil okButtonTitle:@"OK"];
	return 0;
}

- (PixivMangaPageViewController *) bigViewController:(NSString *)url illustID:(NSString *)iid {
	PixivMangaPageViewController *vc = [[PixivMangaPageViewController alloc] init];
	vc.urlString = url;
	vc.illustID = iid;
	vc.delegate = self;
	return [vc autorelease];
}

- (void) setURLs:(NSArray *)array {
	if (urlStrings_ != array) {
		[urlStrings_ release];
		urlStrings_ = [array retain];
	}
	
	CGSize s;
	s.width = [urlStrings_ count] * scrollView.frame.size.width;
	s.height = scrollView.frame.size.height;
	
	NSMutableArray *vcs = [NSMutableArray array];
	for (NSString *url in urlStrings_) {
		PixivMangaPageViewController *vc = [[PixivMangaPageViewController alloc] init];
		vc.urlString = url;
		vc.illustID = [NSString stringWithFormat:@"%@_%@", illustID, @([urlStrings_ indexOfObject:url])];
		vc.delegate = self;
		[vcs addObject:vc];
		[vc release];
	}
	[viewControllers_ release];
	viewControllers_ = [vcs retain];
	
	NSArray *tmp = [[scrollView.subviews retain] autorelease];
	for (UIView *v in tmp) {
		[v removeFromSuperview];
	}
	
	CGRect r;
	r.origin = CGPointZero;
	r.size = scrollView.frame.size;
	r.origin.x += MARGIN / 2;
	r.size.width -= MARGIN;
	scrollView.contentSize = s;
	int i = 0;
	for (PixivMangaPageViewController *vc in viewControllers_) {
		vc.view.frame = r;
		[scrollView addSubview:vc.view];
		r.origin.x += scrollView.frame.size.width;
		
		//vc.view.hidden = i > 0;
		//((UIView *)vc.scrollView.subviews.lastObject).backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.1 * (i + 1)];
		
		if (abs(i - curPage_) < 3) {
			[vc load];
		}
		i++;
	}
	
	r.origin.x = curPage_ * scrollView.frame.size.width;
	[scrollView setContentOffset:CGPointMake(r.origin.x, 0) animated:NO];
	
	[self.view setNeedsLayout];
}

- (void) connection:(CHHtmlParserConnection *)con finished:(long)err {
	if (con == connection_) {
		[[self.view viewWithTag:1234] removeFromSuperview];
	
		[connection_ release];
		connection_ = nil;
		
		if (err) {
			[[SharedAlertView sharedInstance] showWithTitle:NSLocalizedString(@"Image load failed.", nil) message:@"" cancelButtonTitle:nil okButtonTitle:@"OK"];
		} else {
			//[self setStatusBarHidden:YES animated:YES];
			//[self.navigationController setNavigationBarHidden:YES animated:YES];
			//[self.navigationController setToolbarHidden:YES animated:YES];
			
			[self setURLs:[self mangaParser].urlStrings];
		}
		[parser_ release];
		parser_ = nil;
				
		curPage_ = 0;
		[self updateDisplay];
	}
}

- (void) next {
	if (curPage_ + 1 < [urlStrings_ count]) {
		curPage_++;
		//[self reload];
	} else {
		curPage_ = 0;
		//[self reload];
	}
	
	CGRect r = scrollView.frame;
	r.origin.x = r.size.width * curPage_;
	[scrollView setContentOffset:CGPointMake(r.size.width * curPage_, 0) animated:YES];
}

- (void) prev {
	if (0 < curPage_) {
		curPage_--;
		//[self reload];
	}

	CGRect r = scrollView.frame;
	r.origin.x = r.size.width * curPage_;
	[scrollView setContentOffset:CGPointMake(r.size.width * curPage_, 0) animated:YES];
}

- (void)scrollViewDidScroll:(UIScrollView *)sender {
	if (((PixivMangaPageViewController *)[viewControllers_ objectAtIndex:curPage_]).scrollView.zoomScale != 1.0) {
		return;
	}
	
    CGFloat pageWidth = self.scrollView.frame.size.width;  
    curPage_ = floor((self.scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;  
	[(PixivMangaPageViewController *)[viewControllers_ objectAtIndex:curPage_] load];
	if (curPage_ + 1 < [viewControllers_ count]) {
		[(PixivMangaPageViewController *)[viewControllers_ objectAtIndex:curPage_ + 1] load];
	}
	[self updateDisplay];
}  

- (void) singleTapAtPoint:(CGPoint)tapPoint {
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
	if ([self respondsToSelector:@selector(setNeedsStatusBarAppearanceUpdate)]) {
		[self performSelector:@selector(setNeedsStatusBarAppearanceUpdate)];
	}
	
	[self updateDisplay];
}

- (void) loadImageFinished:(id)sender {
	if (sender == [viewControllers_ objectAtIndex:curPage_]) {
		[self updateDisplay];
	}
}

/*
- (void) loadImage {
	UIImage *img = [[self cache] imageForKey:[NSString stringWithFormat:@"%@_%d", self.illustID, curPage_]];
	if (img) {
		[self setImage:img];

		[[self.view viewWithTag:100] removeFromSuperview];
		[self scrollView].alpha = 1.0;
		[self updateDisplay];
	} else {
		[super loadImage];
	}
}

- (NSString *) currentImageKey {
	return [NSString stringWithFormat:@"%@_%d", self.illustID, curPage_];
}
*/

- (NSString *) serviceName {
	return @"pixiv";
}

- (NSString *) url {
	return [NSString stringWithFormat:@"http://www.pixiv.net/member_illust.php?mode=medium&illust_id=%@", self.illustID];
}

- (void) save:(NSString *)local data:(NSData *)data withInfo:(NSDictionary *)info type:(int)type {	
	if (local && type == 1) {
		NSMutableDictionary *dic = [[info mutableCopy] autorelease];
		NSString *p = [local stringByAppendingString:@"_db"];
		[data writeToFile:p atomically:YES];
		
		[dic setObject:p forKey:@"Path"]; 
		
		[[DropBoxTail sharedInstance] upload:dic];
	} else if (local && type == 2) {
		NSMutableDictionary *dic = [[info mutableCopy] autorelease];
		NSString *p = [local stringByAppendingString:@"_en"];
		[data writeToFile:p atomically:YES];
		
		[dic setObject:p forKey:@"Path"]; 
		
		[[EvernoteTail sharedInstance] upload:dic];
	} else if (local && (type == 3 || type == 4)) {
		NSMutableDictionary *dic = [[info mutableCopy] autorelease];
		NSString *p = [local stringByAppendingString:@"_tu"];
		[data writeToFile:p atomically:YES];
		
		[dic setObject:p forKey:@"Path"]; 
		
		[[Tumblr sharedInstance] upload:dic];
	} else if (local && type == 5) {
		NSMutableDictionary *dic = [[info mutableCopy] autorelease];
		NSString *p = [local stringByAppendingString:@"_ss"];
		[data writeToFile:p atomically:YES];
		
		[dic setObject:p forKey:@"Path"]; 
		
		[[SugarSync sharedInstance] upload:dic];
	} else if (local && type == 6) {
		NSMutableDictionary *dic = [[info mutableCopy] autorelease];
		NSString *p = [local stringByAppendingString:@"_gd"];
		[data writeToFile:p atomically:YES];
		
		[dic setObject:p forKey:@"Path"]; 
		
		[[GoogleDrive sharedInstance] upload:dic];
	} else if (local && type == 7) {
		NSMutableDictionary *dic = [[info mutableCopy] autorelease];
		NSString *p = [local stringByAppendingString:@"_sd"];
		[data writeToFile:p atomically:YES];
		
		[dic setObject:p forKey:@"Path"]; 
		
		[[SkyDrive sharedInstance] upload:dic];
	} else {
		NSMutableDictionary *dic = [[info mutableCopy] autorelease];
		NSString *p = [local stringByAppendingString:@"_cr"];
		[data writeToFile:p atomically:YES];
		
		[dic setObject:p forKey:@"Path"]; 
		
		[[CameraRoll sharedInstance] save:dic];
	}
}

- (NSDictionary *) infoForIllustID:(NSString *)iid {
	return [[self parentMedium] infoForIllustID:iid];
}

- (NSString *) parserClassName {
	return [[self parentMedium] parserClassName];
}

- (NSString *) sourceURL {
	return [[self parentMedium] sourceURL];
}

- (NSString *) tumblrServiceName {
	return [[self parentMedium] tumblrServiceName];
}

- (void) save:(int)type {
	PixivMangaPageViewController *cur = ((PixivMangaPageViewController *)[viewControllers_ objectAtIndex:curPage_]);
	NSData *data = [[self cache] imageDataForKey:cur.illustID];
	
	NSDictionary	*info = [self infoForIllustID:self.illustID];
	NSString		*title = [info objectForKey:@"Title"];
	NSString		*user = [info objectForKey:@"UserName"];
	NSMutableArray	*tags = [NSMutableArray array];
	for (NSDictionary *tag in [info objectForKey:@"Tags"]) {
		if ([tag isKindOfClass:[NSString class]]) {
			[tags addObject:tag];
		} else if ([tag isKindOfClass:[NSDictionary class]]) {
			[tags addObject:[tag objectForKey:@"Name"]];
		}
	}
	[tags addObject:[self serviceName]];
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
	
	NSMutableDictionary *dic = [NSMutableDictionary dictionary];
	id obj;
	
	obj = [self parserClassName];
	if (obj) [dic setObject:obj forKey:@"ParserClass"]; 
	obj = [self sourceURL];
	if (obj) [dic setObject:obj forKey:@"SourceURL"]; 
	obj = user;
	if (obj) [dic setObject:obj forKey:@"Username"]; 
	obj = [self serviceName];
	if (obj) [dic setObject:obj forKey:@"ServiceName"]; 
	obj = [self referer];
	if (obj) [dic setObject:obj forKey:@"Referer"]; 
	obj = title;
	if (obj) [dic setObject:obj forKey:@"Name"]; 
	obj = title;
	if (obj) [dic setObject:obj forKey:@"Title"]; 
	obj = tags;
	if (obj) [dic setObject:obj forKey:@"Tags"]; 
	obj = [self url];
	if (obj) {
		[dic setObject:obj forKey:@"URL"]; 
		[dic setObject:obj forKey:@"Referer"]; 
	}
	
	if (type == 3 || type == 4) {
		NSString *url = [self url];
		NSString *caption;
		if ([info objectForKey:@"Title"] && [info objectForKey:@"UserName"]) {
#ifdef PIXITAIL
			caption = [NSString stringWithFormat:NSLocalizedString(@"Tumblr caption pixitail", nil), url, [info objectForKey:@"Title"], [info objectForKey:@"UserName"], [self tumblrServiceName]];
#else
			caption = [NSString stringWithFormat:NSLocalizedString(@"Tumblr caption", nil), url, [info objectForKey:@"Title"], [info objectForKey:@"UserName"],	[self tumblrServiceName]];
#endif
		} else {
#ifdef PIXITAIL
			caption = [NSString stringWithFormat:NSLocalizedString(@"Tumblr caption pixitail no author", nil), url, [self tumblrServiceName]];
#else
			caption = [NSString stringWithFormat:NSLocalizedString(@"Tumblr caption no author", nil), url, url, [self tumblrServiceName]];
#endif
		}
		[dic setObject:caption forKey:@"Caption"];
		
		NSMutableDictionary *tdic = [NSMutableDictionary dictionaryWithObjectsAndKeys:
									 @"image/jpeg",		@"ContentType",
									 @"image.jpg",		@"Filename",
									 [NSNumber numberWithBool:type == 4],		@"Private",
									 url,				@"URL",
									 nil];
		[dic addEntriesFromDictionary:tdic];
	}
	
	NSArray *imageURLs = [NSArray arrayWithObject:cur.urlString];
	if (imageURLs.count == 0) {
		[dic setObject:local forKey:@"Path"];
		
		[self save:local data:data withInfo:dic type:type];
	} else if (imageURLs.count == 1) {
		[dic setObject:local forKey:@"Path"];
		[dic setObject:[imageURLs lastObject] forKey:@"ImageURL"]; 
		
		[self save:local data:data withInfo:dic type:type];
	} else {
		int i = 0;
		for (NSString *imgurl in imageURLs) {
			local = [local stringByAppendingFormat:@"_%d", i++];
			
			[dic setObject:imgurl forKey:@"ImageURL"]; 
			[dic setObject:local forKey:@"Path"];
			[dic setObject:[title stringByAppendingFormat:@"_%03d", i] forKey:@"Name"];
			[dic setObject:[title stringByAppendingFormat:@"_%03d", i] forKey:@"Title"];
			[dic setObject:title forKey:@"Directory"];
			
			[self save:local data:data withInfo:dic type:type];
		}
	}
	
	//[self saveButton].enabled = NO;
}

- (void) save:(UIActionSheet *)sheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    NSString *title = [sheet buttonTitleAtIndex:buttonIndex];
    if ([title isEqualToString:NSLocalizedString(@"Post to tumblr", nil)]) {
        [self save:3];
    } else if ([title isEqualToString:NSLocalizedString(@"Post to tumblr(Private)", nil)]) {
        [self save:4];
    } else if ([title isEqualToString:NSLocalizedString(@"Dropbox", nil)]) {
        [self save:1];
    } else if ([title isEqualToString:NSLocalizedString(@"Evernote", nil)]) {
		if (![EvernoteTail sharedInstance].session.isAuthenticated) {
			[[EvernoteTail sharedInstance].session authenticateWithViewController:self completionHandler:^(NSError *error) {
				if (error) {
					[[[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Login failed", nil) message:[error localizedDescription] delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil] autorelease] show];
				}
			}];
		} else {
			[self save:2];
		}
    } else if ([title isEqualToString:NSLocalizedString(@"SugarSync", nil)]) {
        [self save:5];
    } else if ([title isEqualToString:NSLocalizedString(@"Googleドライブ", nil)]) {
        [self save:6];
    } else if ([title isEqualToString:NSLocalizedString(@"SkyDrive", nil)]) {
		if (![SkyDrive sharedInstance].available) {
			[[SkyDrive sharedInstance] login:self withDelegate:nil];
		} else {
			[self save:7];
		}
    } else if ([title isEqualToString:@"カメラロール"]) {
        [self save:0];
    }
}

- (void)actionSheet:(UIActionSheet *)sheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	actionSheet_ = nil;
	
	if (sheet.tag == 300) {
        // save
		[self save:sheet clickedButtonAtIndex:buttonIndex];
	}
}

- (void) saveAction:(id)sender {
	if (actionSheet_) [actionSheet_ dismissWithClickedButtonIndex:[actionSheet_ cancelButtonIndex] animated:NO];
	
	UIActionSheet	*alert;
    alert = [[UIActionSheet alloc] init];
    alert.delegate = self;
    alert.tag = 300;
    if ([TumblrAccountManager sharedInstance].currentAccount != nil) {
        // Tumblr
        [alert addButtonWithTitle:NSLocalizedString(@"Post to tumblr", nil)];
    }
    if ([[DropBoxTail sharedInstance] linked]) {
        [alert addButtonWithTitle:NSLocalizedString(@"Dropbox", nil)];
    }
    if (UDBoolWithDefault(@"SaveToEvernote", NO)) {
        [alert addButtonWithTitle:NSLocalizedString(@"Evernote", nil)];
    }
    if (UDBoolWithDefault(@"SaveToSugarSync", NO)) {
        [alert addButtonWithTitle:NSLocalizedString(@"SugarSync", nil)];
    }
    if ([GoogleDrive sharedInstance].available) {
        [alert addButtonWithTitle:NSLocalizedString(@"Googleドライブ", nil)];
    }
    if (UDBoolWithDefault(@"SaveToSkyDrive", NO)) {
        [alert addButtonWithTitle:NSLocalizedString(@"SkyDrive", nil)];
    }
	
    [alert addButtonWithTitle:@"カメラロール"];
    [alert addButtonWithTitle:@"キャンセル"];
    [alert setCancelButtonIndex:alert.numberOfButtons - 1];
    
	if (([[UIDevice currentDevice] respondsToSelector:@selector(userInterfaceIdiom)] ? [[UIDevice currentDevice] userInterfaceIdiom] : 0) != 0) {
		[alert showFromBarButtonItem:sender animated:YES];
	} else {
		[alert showFromToolbar:self.navigationController.toolbar];
	}
	actionSheet_ = alert;
	[alert release];
}

- (void) save {
	PixivMangaPageViewController *cur = ((PixivMangaPageViewController *)[viewControllers_ objectAtIndex:curPage_]);

	NSData *data = [[self cache] imageDataForKey:cur.illustID];
	if (data) {
		NSDictionary	*info = [[self pixiv] infoForIllustID:self.illustID];
		NSString		*title = [info objectForKey:@"Title"];
		NSString		*user = [info objectForKey:@"UserName"];
		NSMutableArray	*tags = [NSMutableArray array];
		for (NSDictionary *tag in [info objectForKey:@"Tags"]) {
			if ([tag isKindOfClass:[NSString class]]) {
				[tags addObject:tag];
			} else if ([tag isKindOfClass:[NSDictionary class]]) {
				[tags addObject:[tag objectForKey:@"Name"]];
			}
		}
		[tags addObject:[self serviceName]];
		if (!title) {
			title = cur.illustID;
		}
		title = [title stringByAppendingFormat:@"_%03d", curPage_ + 1];

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
		
		if (local && [[DropBoxTail sharedInstance] linked]) {
			NSString *p = [local stringByAppendingString:@"_db"];
			[data writeToFile:p atomically:YES];

			[[DropBoxTail sharedInstance] upload:[NSDictionary dictionaryWithObjectsAndKeys:
				p,			@"Path",
				title,		@"Name",
				user,		@"Username",
				[self serviceName],	@"ServiceName",
				nil]];
		}

		if (local && UDBoolWithDefault(@"SaveToEvernote", NO)) {
			NSString *p = [local stringByAppendingString:@"_en"];
			[data writeToFile:p atomically:YES];

			[[EvernoteTail sharedInstance] upload:[NSDictionary dictionaryWithObjectsAndKeys:
				title,								@"Title",
				p,									@"Path",
				NSStringFromCGSize(cur.image.size),	@"Size",
				user,								@"Username",
				[self serviceName],					@"ServiceName",
				tags,								@"Tags",
				[self url],							@"URL",
				nil]];
		}
	}

	if (UDBoolWithDefault(@"SaveToCameraRoll", YES)) {
		if (cur.image) {
			UIImageWriteToSavedPhotosAlbum(cur.image, nil, nil, nil);
		}
	}
	
	[self saveButton].enabled = NO;
}

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
	
	[info setObject:illustID forKey:@"IllustID"];

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

- (Class) bigClass {
	return [PixivBigViewController class];
}

- (UIViewController *) viewControllerWithID:(NSString *)idt {
	NSDictionary	*info = [[self pixiv] infoForIllustID:idt];
	
	PixivBigViewController *controller = nil;
	if ([[info objectForKey:@"IllustMode"] isEqualToString:@"manga"]) {
		// manga
		controller = [[[self class] alloc] init];
	} else if ([info objectForKey:@"Images"] != nil) {
		// manga
		controller = [[[self class] alloc] init];
		controller.illustID = idt;

		NSMutableArray *ary = [NSMutableArray array];
		for (NSDictionary *i in [info objectForKey:@"Images"]) {
			[ary addObject:[i objectForKey:@"URLString"]];
		}
		[controller performSelector:@selector(setURLs:) withObject:ary];
	} else {
		// big
		controller = [[[self bigClass] alloc] initWithNibName:@"PixivBigViewController" bundle:nil];
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
	NSDictionary	*info = [[self pixiv] infoForIllustID:idt];
	if ([self infoIsValid:info]) {
		[self replaceViewController:[self viewControllerWithID:idt]];
	} else {
		UIActivityIndicatorView	*act = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
		CGRect	frame = [act frame];
		//frame.size.width = [UIScreen mainScreen].bounds.size.width * 2.0 / 3.0;
		frame.origin.x = ([UIScreen mainScreen].bounds.size.width - frame.size.width) / 2.0;
		frame.origin.y = ([UIScreen mainScreen].bounds.size.height - frame.size.height) / 2.0;
		[act setFrame:frame];
		[act setTag:1000];
		act.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
		[self.view addSubview:act];
		[act startAnimating];
		[act release];
		[self scrollView].alpha = 0.25;
		
		//UISegmentedControl *seg = (UISegmentedControl *)self.navigationItem.rightBarButtonItem.customView;
		//[seg setEnabled:NO forSegmentAtIndex:0];
		//[seg setEnabled:NO forSegmentAtIndex:1];
		
		[self saveButton].enabled = NO;
	}
}

- (void) down {
	[self go:[self nextIID]];

	[[self parentMedium] next];
}

- (void) up {
	[self go:[self prevIID]];

	[[self parentMedium] prev];
}

- (IBAction ) segmentAction:(id)sender {
	UISegmentedControl	*seg = sender;
	if (seg.selectedSegmentIndex == 0 && [self prevIID]) {
		// up
		[self up];
	} else if ([self nextIID]) {
		//
		[self down];
	}
}

- (void) mediumUpdated:(NSNotification *)notif {
	PixivMediumViewController *medium = [self parentMedium];
	if (medium == nil) {
		return;
	}
	
	if ([medium.illustID isEqual:self.illustID] == NO) {
		NSDictionary	*info = [[self pixiv] infoForIllustID:medium.illustID];
		if ([info objectForKey:@"MediumURLString"]) {
			[self replaceViewController:[self viewControllerWithID:medium.illustID]];
		} else {
			[medium reload];
		}
	}
}

@end
