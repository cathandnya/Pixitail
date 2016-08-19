//
//  OAuthViewController.h
//  EchoPro
//
//  Created by nya on 09/08/05.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DefaultViewController.h"


@class OAuthViewController;
@protocol OAuthViewControllerDelegate
- (void) oauthViewController:(OAuthViewController *)obj didEnd:(NSString *)pin;
@end


@interface OAuthViewController : DefaultViewController<UINavigationBarDelegate, UIActionSheetDelegate, UIWebViewDelegate, UITextFieldDelegate> {
	UILabel		*label;
	UIWebView		*webView;
	UITextField	*pinField;
	NSURL					*url;
	
	id<OAuthViewControllerDelegate>	delegate;
}

@property(readwrite, nonatomic, retain) IBOutlet UILabel		*label;
@property(readwrite, nonatomic, retain) IBOutlet UIWebView		*webView;
@property(readwrite, nonatomic, retain) IBOutlet UITextField	*pinField;

@property(nonatomic, retain) NSURL *url;

- (void) setDelegate:(id<OAuthViewControllerDelegate>)del;

- (IBAction) doneWeb;
- (IBAction) cancelWeb;

@end
