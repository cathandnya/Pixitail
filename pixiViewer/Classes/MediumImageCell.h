//
//  MediumViewImageCell.h
//  pixiViewer
//
//  Created by nya on 11/08/05.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@class ImageLoaderManager;


@interface MediumImageCell : UITableViewCell {
	UIImageView *mediumImageView;
	UIProgressView *progressView;
	UIActivityIndicatorView *activityView;
}

+ (MediumImageCell *) cell:(UITableView *)tableView;

@property(readwrite, nonatomic, retain) IBOutlet UIImageView *mediumImageView;
@property(readwrite, nonatomic, retain) IBOutlet UIProgressView *progressView;
@property(readwrite, nonatomic, retain) IBOutlet UIActivityIndicatorView *activityView;

- (void) setImageWithID:(NSString *)ID loader:(ImageLoaderManager *)mgr;

@end
