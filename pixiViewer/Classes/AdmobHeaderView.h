//
//  AdmobHeaderView.h
//  pixiViewer
//
//  Created by nya on 10/03/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GoogleMobileAds/GADBannerViewDelegate.h>


@class GADBannerView;


@interface AdmobHeaderView : UIView<GADBannerViewDelegate> {
	GADBannerView *adView;
	id viewController;
}

- (id) initWithViewController:(id)vc;

@end


@interface AdmobHeaderBGView : UIView

@end
