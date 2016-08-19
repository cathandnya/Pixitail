//
//  PixivRatingViewController.h
//  pixiViewer
//
//  Created by nya on 09/11/28.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "DefaultViewController.h"


@class PixivRatingViewController;


@protocol PixivRatingViewDelegate
- (void) ratingViewCancel:(PixivRatingViewController *)sender;
- (void) ratingView:(PixivRatingViewController *)sender done:(NSInteger)rate;
@end


@interface PixivRatingViewController : DefaultViewController<UIPickerViewDelegate, UIPickerViewDataSource> {
	UIPickerView *_picker;
	UINavigationItem *_navItem;
	
	NSString *titleString;	
	id<PixivRatingViewDelegate> ratingDelegate;
}

@property(readwrite, retain, nonatomic) IBOutlet UIPickerView *_picker;
@property(readwrite, retain, nonatomic) IBOutlet UINavigationItem *_navItem;

@property(readwrite, assign, nonatomic) id<PixivRatingViewDelegate> ratingDelegate;
@property(readwrite, retain, nonatomic) NSString *titleString;

- (IBAction) done;
- (IBAction) cancel;

@end
