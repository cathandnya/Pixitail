//
//  DefaultViewController.h
//  pixiViewer
//
//  Created by nya on 10/05/12.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol DefaultViewControllerProtocol
- (NSMutableDictionary *) storeInfo;
- (BOOL) needsStore;
- (BOOL) restore:(NSDictionary *)info;
- (void) showProgress:(BOOL)activity withTitle:(NSString *)str tag:(int)tag;
- (void) hideProgress;
- (void)setStatusBarHidden:(BOOL)hidden animated:(BOOL)animated;
@end


@interface NSObject(DefaultViewControllerAddition)
- (BOOL) isKindOfDefaultViewController;
@end



@class ProgressViewController;
@interface DefaultViewController : UIViewController<DefaultViewControllerProtocol> {
	ProgressViewController *progressViewController_;
	BOOL progressShowing_;
	NSString *storedTitle;
}
@end


@interface DefaultTableViewController : UITableViewController<DefaultViewControllerProtocol> {
	ProgressViewController *progressViewController_;
	BOOL progressShowing_;
	NSString *storedTitle;
}
@end


id DefaultViewControllerWithStoredInfo(NSDictionary *info);
void setStatusbarHidden(BOOL hidden, BOOL animated);
