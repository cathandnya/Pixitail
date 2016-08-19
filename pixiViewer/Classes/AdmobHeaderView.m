//
//  AdmobHeaderView.m
//  pixiViewer
//
//  Created by nya on 10/03/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "AdmobHeaderView.h"
#import <GoogleMobileAds/GADBannerView.h>


@implementation AdmobHeaderView

+ (AdmobHeaderView *) sharedInstance {
	static AdmobHeaderView *view = nil;
	if (view == nil) {
		view = [[AdmobHeaderView alloc] init];
	}
	return view;
}

- (id) initWithViewController:(id)vc {
    if ((self = [super initWithFrame:CGRectMake(0, 0, 320, 50 + 1)])) {
		viewController = vc;
		
		//srand(time(NULL));		
		//if (YES || (rand() % 2) == 0) {
			adView = [[GADBannerView alloc] initWithAdSize:kGADAdSizeBanner origin:CGPointZero];
			adView.adUnitID = ADMOB_UNIT_ID;
			adView.delegate = self;
			adView.rootViewController = viewController;
			
			UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, ((UIView *)adView).frame.size.height, self.frame.size.width, 1)];
			line.autoresizingMask = UIViewAutoresizingFlexibleWidth;
			UIActivityIndicatorView *act = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
			act.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
			act.frame = CGRectMake((self.frame.size.width - act.frame.size.width) / 2, (self.frame.size.height - act.frame.size.height) / 2, act.frame.size.width, act.frame.size.height);
			act.hidesWhenStopped = YES;
			act.tag = 1000;
			[act startAnimating];
			line.backgroundColor = [UIColor lightGrayColor];
			[self addSubview:line];
			[self addSubview:act];
			[line release];
			[act release];
			self.backgroundColor = [UIColor clearColor];
			
			adView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
			
			[self addSubview:adView];
			
			GADRequest *req = [GADRequest request];
			//req.testing = NO;
			[adView loadRequest:req];
		
		self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    }
    return self;
}

- (void)dealloc {
	adView.delegate = nil;
	[adView release];
	
    [super dealloc];
}

- (void) layoutSubviews {
	[super layoutSubviews];
	
	CGPoint p = CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2);
	adView.center = p;
}

#pragma mark -
#pragma mark AdMobDelegate methods

- (void)adViewDidReceiveAd:(GADBannerView *)aView {
	if ([adView superview] == nil) {
		[self addSubview:adView];
	}
}

- (void)adView:(GADBannerView *)aView didFailToReceiveAdWithError:(GADRequestError *)error {
	DLog(@"ad failed: %@", [error localizedDescription]);

	[adView removeFromSuperview];
	adView.delegate = nil;
	[adView release];
	adView = nil;
}

@end


@implementation AdmobHeaderBGView

- (id) init {
    if ((self = [super initWithFrame:[AdmobHeaderView sharedInstance].frame])) {
		UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, self.frame.size.height - 1, 320, 1)];
		line.backgroundColor = [UIColor lightGrayColor];
		[self addSubview:line];
		[line release];
		self.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

@end
