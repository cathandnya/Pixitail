//
//  DisableAdViewController.m
//  pixiViewer
//
//  Created by nya on 10/09/13.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "DisableAdViewController.h"
#import "SFHFKeychainUtils.h"


@implementation DisableAdViewController

@synthesize purchaseButton;
@synthesize cannotPurchaseLabel;
@synthesize restoreButton;
@synthesize activityBaseView;

- (void) load {
	NSSet *idts;
#ifdef PIXITAIL
	idts = [NSSet setWithObject:@"org.cathand.pixitail.DisableAd"];
#else
	idts = [NSSet setWithObject:@"org.cathand.illustail.DisableAd"];
#endif	
	SKProductsRequest *req = [[SKProductsRequest alloc] initWithProductIdentifiers:idts];
	req.delegate = self;
	
	productRequest = req;
	[productRequest start];
	
	activityBaseView.hidden = NO;
	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorStartNotification" object:nil];
}

/*
 // The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
    }
    return self;
}
*/

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.title = NSLocalizedString(@"DisableAd Adon", nil);
	
#ifdef PIXITAIL
	cannotPurchaseLabel.hidden = YES;
#else
	cannotPurchaseLabel.hidden = YES;
#endif

	[[SKPaymentQueue defaultQueue] addTransactionObserver:self];
	
	if ([SKPaymentQueue canMakePayments]) {
		[self load];
	} else {
		UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"cannot make payments.", nil) message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil] autorelease];
		[alert show];
	}
}


/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [self setCannotPurchaseLabel:nil];
	[self setRestoreButton:nil];
	[self setActivityBaseView:nil];
    [super viewDidUnload];
	
	[productRequest cancel];
	[productRequest release];
	productRequest = nil;
	[products release];
	products = nil;

	[[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
	
	self.purchaseButton = nil;
}

- (void)dealloc {	
    [cannotPurchaseLabel release];
	[productRequest cancel];
	[productRequest release];
	productRequest = nil;
	[products release];
	products = nil;
	
	[[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
	
	self.purchaseButton = nil;

	[restoreButton release];
	[activityBaseView release];
    [super dealloc];
}

#pragma mark-

- (IBAction) buttonAction:(id)sender {
	if ([products count] == 0) {
		return;
	}

	SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:[products objectAtIndex:0]];
	payment.quantity = 1;
	
	activityBaseView.hidden = NO;
	[[SKPaymentQueue defaultQueue] addPayment:payment];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorStartNotification" object:nil];
	
	purchaseButton.enabled = NO;
	restoreButton.enabled = NO;
	self.navigationItem.hidesBackButton = YES;
}

- (IBAction) restoreAction:(id)sender {
	if ([products count] == 0) {
		return;
	}

	[[SKPaymentQueue defaultQueue] restoreCompletedTransactions];

	activityBaseView.hidden = NO;
	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorStartNotification" object:nil];
	
	purchaseButton.enabled = NO;
	restoreButton.enabled = NO;
	self.navigationItem.hidesBackButton = YES;
}

#pragma mark-

- (void)requestDidFinish:(SKRequest *)request {
	activityBaseView.hidden = YES;
	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:nil];

	if (request == productRequest) {
		[productRequest release];
		productRequest = nil;
	}
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
	activityBaseView.hidden = YES;
	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:nil];

	UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"SKRequest failed.", nil) message:[error localizedDescription] delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil] autorelease];
	[alert show];
	
	if (request == productRequest) {
		[productRequest release];
		productRequest = nil;
	}
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
	[products release];
	products = [response.products retain];
	
	if ([products count] == 1) {
		SKProduct *product = [products objectAtIndex:0];
		NSNumberFormatter *numberFormatter = [[[NSNumberFormatter alloc] init] autorelease];
		[numberFormatter setFormatterBehavior:NSNumberFormatterBehavior10_4];
		[numberFormatter setNumberStyle:NSNumberFormatterCurrencyStyle];
		[numberFormatter setLocale:product.priceLocale];
		NSString *formattedString = [numberFormatter stringFromNumber:product.price];
		
		[purchaseButton setTitle:[NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Purchase", nil), formattedString] forState:UIControlStateNormal];
		purchaseButton.enabled = YES;
		restoreButton.enabled = YES;
	}
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
	for (SKPaymentTransaction *t in transactions) {
		switch (t.transactionState) {
		case SKPaymentTransactionStatePurchasing:
			break;
				
		case SKPaymentTransactionStateFailed:
		case SKPaymentTransactionStateDeferred:
			activityBaseView.hidden = YES;
			[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:nil];
		{
			UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Purchase failed.", nil) message:[t.error localizedDescription] delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil] autorelease];
			[alert show];
		}
			self.navigationItem.hidesBackButton = NO;
			purchaseButton.enabled = YES;
			restoreButton.enabled = YES;
			break;
				
		case SKPaymentTransactionStatePurchased:
		case SKPaymentTransactionStateRestored:
			[queue finishTransaction:t];
		
			activityBaseView.hidden = YES;
			[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:nil];
			[[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"DisableAd"];
			[[NSUserDefaults standardUserDefaults] synchronize];
#ifdef PIXITAIL
			[SFHFKeychainUtils storeUsername:@"DisableAd" andPassword:@"1" forServiceName:@"org.cathand.Pixitail" updateExisting:YES error:nil];
#else
			[SFHFKeychainUtils storeUsername:@"DisableAd" andPassword:@"1" forServiceName:@"org.cathand.Illustail" updateExisting:YES error:nil];
#endif
			
			[self.navigationController popViewControllerAnimated:YES];
			break;
		}
	}
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue {

}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error {
	activityBaseView.hidden = YES;
	[[NSNotificationCenter defaultCenter] postNotificationName:@"NetworkActivityIndicatorEndNotification" object:nil];

	UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Purchase failed.", nil) message:[error localizedDescription] delegate:nil cancelButtonTitle:nil otherButtonTitles:NSLocalizedString(@"OK", nil), nil] autorelease];
	[alert show];

	self.navigationItem.hidesBackButton = NO;
	purchaseButton.enabled = YES;
	restoreButton.enabled = YES;
}

@end
