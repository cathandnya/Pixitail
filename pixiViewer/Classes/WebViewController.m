//
//  WebViewController.m
//

#import "WebViewController.h"
#import "Reachability.h"


#define BACK_BUTTON_INDEX 2
#define FIXED_SPACE_ITEM_INDEX 3
#define FORWARD_BUTTON_INDEX 4
#define FLEXIBLE_SPACE_ITEM_INDEX 1
#define RELOAD_BUTTON_INDEX 0

// WebViewController (Private)

@interface WebViewController (Private)

- (void)updateBarButton;
- (void)showSimpleAlertWithTitle:(NSString *)aTitle message:(NSString *)aMessage;

@end


// WebViewController

@implementation WebViewController

@synthesize url, html;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.hidesBottomBarWhenPushed = YES;
    }
    return self;
}

- (void)dealloc 
{  
    webView.delegate = nil;
    [webView release], webView = nil;
    [backButton release];
    [forwardButton release];
    [reloadButton release];
    [flexibleSpaceItem release];
    [fixedSpaceItem release];
    [activityIndicatorItem release], activityIndicatorItem = nil;
	
	self.url = nil;
	self.html = nil;
	
	[super dealloc];  
}

- (UIBarButtonItem *)activityIndicatorItem
{
    if (activityIndicatorItem == nil) {
        const CGFloat w = 18;
		UIActivityIndicatorView *activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
		activityIndicatorView.hidesWhenStopped = YES;
        CGRect frame = activityIndicatorView.frame;
        frame.origin = CGPointZero;
        frame.size.width = w;
        frame.size.height = w;
        UIView *baseView = [[UIView alloc] initWithFrame:frame];
        frame.origin.x = (baseView.frame.size.width - activityIndicatorView.frame.size.width) / 2.0;
        frame.origin.y = (baseView.frame.size.height - activityIndicatorView.frame.size.height) / 2.0;
        activityIndicatorView.frame = frame;
        [baseView addSubview:activityIndicatorView];
		[activityIndicatorView release];
		activityIndicatorItem = [[UIBarButtonItem alloc] initWithCustomView:baseView];
		[baseView release];
        activityIndicatorItem.width = w;
    }
    
    return activityIndicatorItem;
}

- (void)viewDidLoad 
{
	//[self.navigationController setNavigationBarHidden:YES animated:NO];
	//[self.navigationController setNavigationBarHidden:NO animated:NO];
    //[self.navigationController setToolbarHidden:NO animated:NO];
    webView.scalesPageToFit = YES;
	    
	if (self.url) {
		[webView loadRequest:[NSURLRequest requestWithURL:self.url]];
	} else if (self.html) {
		[webView loadHTMLString:self.html baseURL:[NSURL URLWithString:[[NSBundle mainBundle] bundlePath]]];
	}
}

- (void)viewDidUnload
{
	if (webView.loading) {
		loading = NO;
		
		[webView stopLoading];
		//[[Service sharedService] networkActivityHide];
	}

    webView.delegate = nil;
    [webView release], webView = nil;
    [backButton release], backButton = nil;
    [forwardButton release], forwardButton = nil;
    [reloadButton release], reloadButton = nil;
    [stopButton release], stopButton = nil;
    [flexibleSpaceItem release], flexibleSpaceItem = nil;
    [fixedSpaceItem release], fixedSpaceItem = nil;
    [activityIndicatorItem release], activityIndicatorItem = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
	//self.navigationController.toolbar.barStyle = UIBarStyleDefault;
	//self.navigationController.toolbar.translucent = NO;
	//self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
	//self.navigationController.navigationBar.translucent = NO;
	
	UIBarButtonItem *actionBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(action:)];
	[actionBtn autorelease];
    [self activityIndicatorItem];
    
    NSArray *toolbarItems;
    if (webView.loading && isShown) {
        toolbarItems = [NSArray arrayWithObjects:activityIndicatorItem, flexibleSpaceItem, backButton, flexibleSpaceItem, forwardButton, flexibleSpaceItem, actionBtn, nil];
    } else {
        toolbarItems = [NSArray arrayWithObjects:reloadButton, flexibleSpaceItem, backButton, flexibleSpaceItem, forwardButton, flexibleSpaceItem, actionBtn, nil];
    }
    backButton.enabled = webView.canGoBack;
    forwardButton.enabled = webView.canGoForward;	
    [self setToolbarItems:toolbarItems animated:YES];

	if ([UIDevice currentDevice].systemVersion.floatValue >= 7.0 && UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		[self performSelector:@selector(viewWillAppearDelay) withObject:nil afterDelay:1.0];
	} else {
		[self viewWillAppearDelay];
	}
}

- (void) viewWillAppearDelay {
	[self.navigationController setNavigationBarHidden:NO animated:YES];
    [self.navigationController setToolbarHidden:NO animated:YES];
}

- (void)viewDidAppear:(BOOL)animated
{
    //[self.navigationController setToolbarHidden:NO animated:YES];
    isShown = YES;
	[self updateBarButton];
}

- (void)viewWillDisappear:(BOOL)animated
{
	//self.navigationController.toolbar.barStyle = UIBarStyleBlackTranslucent;
	//self.navigationController.toolbar.translucent = YES;
	//self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
	//self.navigationController.navigationBar.translucent = YES;
	
    isShown = NO;
	[self updateBarButton];
	
	if (actionSheet) {
		[actionSheet dismissWithClickedButtonIndex:[actionSheet cancelButtonIndex] animated:YES];
		actionSheet = nil;
	}
}

- (UIBarButtonItem *)barButtonWithIndex:(NSUInteger)index
{
    NSArray *toolbarItems = self.navigationController.toolbarItems;
    UIBarButtonItem *button = [toolbarItems objectAtIndex:index];
    return button;
}

- (void)replaceToolbarButtonWithButton:(UIBarButtonItem *)button
{
    NSArray *toolbarItems = self.navigationController.toolbar.items;
    NSMutableArray *mutableToolbarItems = [NSMutableArray arrayWithArray:toolbarItems];
    if ([mutableToolbarItems count] > RELOAD_BUTTON_INDEX) {
        [mutableToolbarItems replaceObjectAtIndex:RELOAD_BUTTON_INDEX withObject:button];
        [self setToolbarItems:mutableToolbarItems animated:NO];
    }
}

- (void)updateBarButton
{
    UIActivityIndicatorView *activityIndicatorView = (UIActivityIndicatorView *)[self.activityIndicatorItem.customView.subviews objectAtIndex:0];
    if (webView.loading && isShown) {
        [activityIndicatorView startAnimating];
        [self replaceToolbarButtonWithButton:activityIndicatorItem];
    } else {
        [activityIndicatorView stopAnimating];
        [self replaceToolbarButtonWithButton:reloadButton];
    }
    
    backButton.enabled = webView.canGoBack;
    forwardButton.enabled = webView.canGoForward;	
}

- (void)showSimpleAlertWithTitle:(NSString *)aTitle message:(NSString *)aMessage
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:aTitle
                                                    message:aMessage
                                                   delegate:self 
                                          cancelButtonTitle:NSLocalizedString(@"OK", nil) 
                                          otherButtonTitles:nil];
    
    [alert show];
    [alert release];
}

- (void) setHtml:(NSString *)str {
	NSArray* a_paths = NSSearchPathForDirectoriesInDomains( NSDocumentDirectory, NSUserDomainMask, YES );
	if ([a_paths count] == 0) {
		assert(0);
		html = str;
	} else {
		// 保存
		NSString *path = [[a_paths objectAtIndex:0] stringByAppendingPathComponent:@"webview_html.html"];
		NSError *err = nil;
		[str writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&err];
		self.url = [NSURL fileURLWithPath:path];
		[html release];
		html = nil;
	}
}

#pragma mark UIWebViewDelegate

- (void)webViewDidStartLoad:(UIWebView *)aWebView
{
    [self updateBarButton];
	//[[Service sharedService] networkActivityShow];
	loading = YES;
}

-(void)webViewDidFinishLoad:(UIWebView *)aWebView
{
    [webView stringByEvaluatingJavaScriptFromString:
                           @"try {var a = document.getElementsByTagName('a'); for (var i = 0; i < a.length; ++i) { a[i].setAttribute('target', '');}}catch (e){}; document.title"];
    [self updateBarButton];
	if (loading) {
		//[[Service sharedService] networkActivityHide];
		loading = NO;
	}
    
    /*
    if ([[[webView.request URL] absoluteString] hasPrefix:@"http://s.ameblo.jp/"]) {
        [self performSelector:@selector(scrollToHideNavBar) withObject:nil afterDelay:0.5];
    }
    */
}

- (void) scrollToHideNavBar {
    [webView stringByEvaluatingJavaScriptFromString:@"window.scrollBy(0, 55);"];
}

- (BOOL)webView:(UIWebView *)aWebView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    return YES;
}

- (void)webView:(UIWebView *)aWebView didFailLoadWithError:(NSError *)error
{
    [self updateBarButton];
	if (loading) {
		//[[Service sharedService] networkActivityHide];
		loading = NO;
	}
    
    NSLog(@"%@ %s %@ %@", self, __PRETTY_FUNCTION__, [error description], [error localizedDescription]);

    if ([[Reachability reachabilityForInternetConnection] currentReachabilityStatus] == NotReachable) {
        [self showSimpleAlertWithTitle:NSLocalizedString(@"No Network.", nil) message:nil];        
    }
    
}

#pragma mark action

- (IBAction)reloadAction
{
    NSString *urlStr = [[webView.request URL] absoluteString];
    if ([urlStr length] == 0 || urlStr == nil || [urlStr isEqualToString:@"about:blank"]) {
		if (self.url) {	
			[webView loadRequest:[NSURLRequest requestWithURL:self.url]];
		} else {
			[webView loadHTMLString:self.html baseURL:[NSURL URLWithString:[[NSBundle mainBundle] bundlePath]]];
		}
    } else {
		[webView reload];
	}
}

- (IBAction)backAction
{
	if (webView.canGoBack) {
		[webView goBack];
	} else if (self.html) {
		[webView loadHTMLString:self.html baseURL:[NSURL URLWithString:[[NSBundle mainBundle] bundlePath]]];
	}
}

- (IBAction)forwardAction
{
    [webView goForward];    
}
        
- (IBAction)stopAction
{
    [webView stopLoading];
}

- (void) action:(id)sender {
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:NSLocalizedString(@"Open With Safari", nil), nil];

	if (([[UIDevice currentDevice] respondsToSelector:@selector(userInterfaceIdiom)] ? [[UIDevice currentDevice] userInterfaceIdiom] : 0) != 0) {
		if (actionSheet) [actionSheet dismissWithClickedButtonIndex:[actionSheet cancelButtonIndex] animated:YES];
		actionSheet = sheet;
		[sheet showFromBarButtonItem:sender animated:YES];
	} else {
		[sheet showFromToolbar:self.navigationController.toolbar];
	}

    [sheet release];
}

- (void)actionSheet:(UIActionSheet *)sheet clickedButtonAtIndex:(NSInteger)buttonIndex {
	actionSheet = nil;
	
    if (buttonIndex == 0) {
        // safari
        [[UIApplication sharedApplication] openURL:[webView.request URL]];
    }
}

#pragma mark-

- (void) rebuild {
	CGRect rect = webView.frame;
	UIWebView *wv = [[UIWebView alloc] initWithFrame:rect];
	UIView *sv = [webView superview];
	
	if (webView.loading) {
		loading = NO;
		
		[webView stopLoading];
		//[[Service sharedService] networkActivityHide];
	}

	[webView removeFromSuperview];
	[sv addSubview:wv];
	[webView release];
	webView = wv;

	webView.delegate = self;
    webView.scalesPageToFit = YES;
	if (self.url) {
		[webView loadRequest:[NSURLRequest requestWithURL:self.url]];
	} else if (self.html) {
		[webView loadHTMLString:self.html baseURL:[NSURL URLWithString:[[NSBundle mainBundle] bundlePath]]];
	}
}

@end
