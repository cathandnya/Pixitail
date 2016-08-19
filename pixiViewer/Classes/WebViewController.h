//
//  WebViewController.h
//

#import <UIKit/UIKit.h>
#import "DefaultViewController.h"


// WebViewController

@interface WebViewController : DefaultViewController<UIWebViewDelegate, UIActionSheetDelegate>
{
    IBOutlet UIWebView *webView;
    IBOutlet UIBarButtonItem *backButton;
    IBOutlet UIBarButtonItem *forwardButton;
    IBOutlet UIBarButtonItem *reloadButton;
    IBOutlet UIBarButtonItem *stopButton;
    IBOutlet UIBarButtonItem *flexibleSpaceItem;
    IBOutlet UIBarButtonItem *fixedSpaceItem;
    UIBarButtonItem *activityIndicatorItem;
    
    BOOL isShown;
	BOOL loading;
	
	NSURL *url;
	NSString *html;
	
	UIActionSheet *actionSheet;
}

@property(retain, nonatomic, readwrite) NSURL *url;
@property(retain, nonatomic, readwrite) NSString *html;

- (IBAction)stopAction;
- (IBAction)reloadAction;
- (IBAction)backAction;
- (IBAction)forwardAction;

// webViewを作り直す
- (void) rebuild;

@end

