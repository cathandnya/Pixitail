//
//  PixivTagAddViewController.h
//  pixiViewer
//
//  Created by nya on 09/10/19.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "DefaultViewController.h"


@class PixivTagAddViewController;


@protocol PixivTagAddViewControllerDelegate
- (void) tagAddViewCancel:(PixivTagAddViewController *)sender;
- (void) tagAddView:(PixivTagAddViewController *)sender done:(NSDictionary *)info;
@end



@interface PixivTagAddViewController : DefaultViewController {
	UITextView			*textView_;
	UIBarButtonItem		*doneButton_;
	UINavigationItem	*navItem_;
	UILabel *countLabel;

	NSString *titleString;	
	NSString *defaultString;
	NSString *type;
	int maxCount;
	id<PixivTagAddViewControllerDelegate> delegate;
}

@property(readwrite, retain, nonatomic) IBOutlet UITextView *textView_;
@property(readwrite, retain, nonatomic) IBOutlet UIBarButtonItem *doneButton_;
@property(readwrite, retain, nonatomic) IBOutlet UINavigationItem *navItem_;
@property(readwrite, retain, nonatomic) IBOutlet UILabel *countLabel;
@property (retain, nonatomic) IBOutlet UIView *baseView;

@property(readwrite, assign, nonatomic) id<PixivTagAddViewControllerDelegate> delegate;
@property(readwrite, retain, nonatomic) NSString *titleString;
@property(readwrite, retain, nonatomic) NSString *defaultString;
@property(readwrite, retain, nonatomic) NSString *type;
@property(readwrite, assign, nonatomic) int maxCount;

- (IBAction) cancel;
- (IBAction) done;

@end
