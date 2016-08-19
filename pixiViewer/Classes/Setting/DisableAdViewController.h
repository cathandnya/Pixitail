//
//  DisableAdViewController.h
//  pixiViewer
//
//  Created by nya on 10/09/13.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h>


@interface DisableAdViewController : UIViewController<SKPaymentTransactionObserver, SKProductsRequestDelegate, SKRequestDelegate> {
	SKProductsRequest *productRequest;
	NSArray *products;
	
	UIButton *purchaseButton;
	UILabel *cannotPurchaseLabel;
}

@property(readwrite, nonatomic, retain) IBOutlet UIButton *purchaseButton;
@property (nonatomic, retain) IBOutlet UILabel *cannotPurchaseLabel;
@property (retain, nonatomic) IBOutlet UIButton *restoreButton;
@property (retain, nonatomic) IBOutlet UIView *activityBaseView;

- (IBAction) buttonAction:(id)sender;

@end
